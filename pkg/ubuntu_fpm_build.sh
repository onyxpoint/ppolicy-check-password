#!/bin/bash
set -o errexit
set -o errtrace
set -o nounset

name=ppolicy-check-password
version=1.2
description='A password policy overlay that provides the ability to:
 - Check passwords against cracklib
 - Ensure that specific quantities of characters from particular character sets
   are used in the password
 - Ensure that a certain number of character sets are used in the password.
 - Ensure that the number of consecutive characters used from a character set
   is limited.'
license=OpenLDAP
config=/etc/ldap/check_password.conf
include_cracklib=1
url="$(git remote -v | head -n1 \
    | sed -e's@^.*:@https://github.com/@' -e's@[.]git.*$@@')"
includes="-I$(ls -1d $(pwd)/openldap/openldap-*/debian/build/include)\
 -I$(ls -1d $(pwd)/openldap/openldap-*/include)\
 -I$(ls -1d $(pwd)/openldap/openldap-*/servers/slapd)\
"

update_makefile() {
    cp -av Makefile Makefile.ubuntu
    # Update config path to match slapd
    sed -r -i -e"s@^(CONFIG=).*\$@\1${config}@" Makefile.ubuntu
    # Update includes path for Ubuntu openldap
    sed -r -i    -e"s@^(INCS=).*\$@\1${includes}@" Makefile.ubuntu
    if (( include_cracklib != 1 ))
    then
        # Disable cracklib. Resolves error:
        #   lt_dlopen failed: (check_password.so) file not found.
        sed -r -i \
            -e"/-DHAVE_CRACKLIB/d" \
            -e"s@^(CRACKLIB_LIB=.*)\$@#\1@" \
            -e"s@^(LIBS=[^ ]+).*\$@\1@" \
            Makefile.ubuntu
    fi
    cp -av Makefile.ubuntu Makefile.ubuntu.test
    sed -r -i \
        -e"s@^(CONFIG=).*\$@\1check_password.conf.test@" \
        Makefile.ubuntu.test
}

prep_layout() {
    # doc
    local _doc=layout/usr/share/doc/${name}
    mkdir -pv ${_doc}
    cp -av *.md LICENSE ${_doc}/
    # shared object
    local _ldap=layout/usr/lib/ldap
    local _so=check_password.so
    mkdir -pv ${_ldap}
    # http://people.canonical.com/~cjwatson/ubuntu-policy/policy.html/ch-files.html#s-libraries
    strip --strip-unneeded -p -v ${_so} -o ${_ldap}/${_so}.${version}
    # shared object symlink
    # workaround https://github.com/jordansissel/fpm/issues/1018
    {
        echo '#!/bin/sh'
        echo 'cd /usr/lib/ldap'
        echo "ln -fnsv ${_so}.${version} ${_so}"
    } > create_symlink.sh
    {
        echo '#!/bin/sh'
        echo "rm -fv /usr/lib/ldap/${_so}"
    } > remove_symlink.sh
    # fix permissions
    find layout -type f -exec chmod 0644 {} +
}

cleanup() {
    rm -fv Makefile.ubuntu*
    rm -fv check_password.conf.test
    rm -fv *_symlink.sh
    rm -rfv layout
    make clean || true
}

cleanup_and_abort() {
    local _es=${$?}
    cleanup
    echo "(${_es}) Error encountered. Aborting"
    exit ${_es}
}

update_makefile
make -f Makefile.ubuntu.test check_password_test || cleanup_and_abort
LD_LIBRARY_PATH=. ./cpass || cleanup_and_abort
make -f Makefile.ubuntu check_password || cleanup_and_abort
prep_layout
fpm --verbose \
    -t deb \
    -s dir \
    --force \
    --architecture all \
    --name "${name}" \
    --license "${license}" \
    --version "${version}" \
    --description "${description}" \
    --url "${url}" \
    --after-install create_symlink.sh \
    --after-upgrade create_symlink.sh \
    --after-remove remove_symlink.sh \
    -C layout \
    . \
    || cleanup_and_abort
cleanup
