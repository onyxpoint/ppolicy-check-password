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
url="$(git remote -v \
    | head -n1 \
    | sed -e's#^.*:#https://github.com/#' -e's#[.]git.*$##')"
includes="-I$(ls -1d $(pwd)/openldap/openldap-*/debian/build/include)\
 -I$(ls -1d $(pwd)/openldap/openldap-*/include)\
 -I$(ls -1d $(pwd)/openldap/openldap-*/servers/slapd)\
"

update_makefile() {
    cp -av Makefile Makefile.ubuntu
    sed -r -i \
        -e's#^(INCS=)\$\(LDAP_INC\) \$\(CRACK_INC\)$#\1'"${includes}"'#' \
        -e's#^(CONFIG=)/etc/openldap/check_password.conf$#\1'"${config}"'#' \
        Makefile.ubuntu
}

prep_layout() {
    # doc
    local _doc=layout/usr/share/doc/${name}
    mkdir -pv ${_doc}
    cp -v *.md LICENSE ${_doc}/
    # shared object
    local _ldap=layout/usr/lib/ldap
    mkdir -pv ${_ldap}
    cp -v check_password.so ${_ldap}/
}

cleanup() {
    rm -fv Makefile.ubuntu
    rm -rfv layout
}

cleanup_and_abort() {
    local _es=${$?}
    cleanup
    echo "(${_es}) Error encountered. Aborting"
    exit ${_es}
}

update_makefile
make -f Makefile.ubuntu check_password || cleanup_and_abort
prep_layout
fpm \
    -t deb \
    -s dir \
    --force \
    --architecture all \
    --name "${name}" \
    --license "${license}" \
    --version "${version}" \
    --description "${description}" \
    --url "${url}" \
    -C layout \
    . \
    || cleanup_and_abort
cleanup
