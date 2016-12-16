# check_password.c

OpenLDAP pwdChecker library


## Maintainers

- 2011 Trevor Vaughan <tvaughan@onyxpoint.com> - Onyx Point, Inc.
- 2009 Jerome HUET - LTB-project
- 2009 Clement Oudot <clem.oudot@gmail.com> - LTB-project
- 2008-01-30 Pierre-Yves Bonnetain <py.bonnetain@ba-cst.com>
- 2007-06-06 Michael Steinmann <msl@calivia.com>


## Overview

``check_password.c`` is an OpenLDAP ``pwdPolicyChecker`` module used to check
the strength and quality of user-provided passwords.

This module is used as an extension of the OpenLDAP password policy controls,
see ``slapo-ppolicy(5)`` section ``pwdCheckModule``.

``check_password.c`` will run a number of checks on the passwords to ensure
minimum strength and quality requirements are met. Passwords that do not meet
these requirements are rejected.

This was originally packaged as
``ltb-project-openldap-ppolicy-check-password-1.1``. However, Onyx Point made a
great number of changes and improvements and has re-labeled it
``ppolicy-check-password``. All original license restrictions and user
privileges apply.

The original code can be downloaded from [LDAP Tool Box - Files -
LSC](http://tools.ltb-project.org/projects/ltb/files).


## Password checks

- passwords shorter than 6 characters are rejected (also note that cracklib
  rejects passwords shorter than 6 characters)
- syntactic checks controls how many different character classes are used
  (lower, upper, digit and punctuation characters). The minimum number of
  classes is defined in a configuration file. You can set the minimum for each
  class.
- passwords are checked against cracklib if cracklib is enabled at compile
  time. It can be disabled in configuration file.
- password checking can optionally be set to ensure that no more than a given
  number of characters from a character set can be used in a row.


## INSTALLATION

Use the provided Makefile to build the module.

Compilation constants :

``CONFIG_FILE``: Path to the configuration file.
              Defaults to ``/etc/openldap/check_password.conf``

``DEBUG``: If defined, check_password will syslog() its actions.

``LDEBUG``: If defined, check_password will print its actions to the console.

Build dependencies
cracklib header files (link with ``-lcrack``). The Makefile does not look for
cracklib; you may need to provide the paths manually.

Install into the slapd server module path.  Change the installation
path to match with the OpenLDAP module path in the Makefile.

The module may be defined with slapd.conf parameter "modulepath".


### Red Hat

On Red Hat systems, you will need to download the openldap source RPM that you
want to build against and perform the following steps:

1. ``rpm -i <openldap source RPM>``
2. ``rpmbuild -bc <rpm_build_dir>/SPECS/openldap.spec``
3. ``cd <openldap-password-module_dir>``

    4. ``mkdir openldap-<version>``
    5. ``cd openldap-<version>``
    6. ``src_dir="<rpm_build_dir>/BUILD/openldap-<version>/openldap-<version>/"``
    7. ``cp -r $src_dir/build-servers $src_dir/include \
         $src_dir/libraries $src_dir/servers .``

Then, the Makefile should work properly.


### Ubuntu

Unfortunately, due to [Bug #1210144 “package should include slapd
headers”](https://bugs.launchpad.net/ubuntu/+source/openldap/+bug/1210144),
OpenLdap must be built prior to building ``ppolicy-check-password``:

1. Install required packages:

    ```
    sudo apt-get install build-essential devscripts libcrack2-dev \
        libldap2-dev ruby-dev
    sudo apt-get build-dep openldap
    sudo gem install fpm
    ```

2. Build OpenLDAP:

    ```
    mkdir -f openldap
    cd openldap
    apt-get source openldap
    cd openldap-*
    debuild -us -uc -b
    cd ../..
    ```

3. Build Ubuntu package

    ```
    ./pkg/ubuntu_fpm_build.sh
    ```

4. View package to verify contents:

    ```
    less *.deb
    ```

**Note:** You will also need to install `libcrack2-dev` on the host where you
install  `slapd`. Otherwise, you will recedive the following (misleading)
error:

```
check_password_quality: lt_dlopen failed: (check_password.so) file not found.
```



## TESTING

An application is provided to build tests for check_password.c. The Makefile
will produce 'cpass' which will run the tests defined in check_password_test.c.
It is highly suggested that you use this if you are going to modify
check_password.c.

You'll need to run cpass with: ``LD_LIBRARY_PATH=. ./cpass``


## USAGE

To use this module you need to add objectClass pwdPolicyChecker with an
attribute 'pwdCheckModule: check_password.so' to a password policy entry.

The module depends on a working cracklib installation including wordlist files.
If the wordlist files are not readable, the cracklib check will be skipped
silently.

**Note:** pwdPolicyChecker modules are loaded on *every* password change
operation.

## Configuration

The configuration file (``/etc/openldap/check_password.conf`` by default)
contains parameters for the module. If the file is not found, parameters are
given their default value.

The syntax of the file is:

```
parameter value
```

with spaces being delimiters. Parameter names ARE case sensitive (this may
change in the future).

Current parameters:

- ``max_consecutive_per_class``: integer. Default value: 5. Maximum number of
  characters that can appear consecutively from a given character class. 0
  disables.
- ``min_digit``: integer. Defaut value: 0. Minimum digit characters expected.
- ``min_lower``: integer. Defaut value: 0. Minimum lower characters expected.
- ``min_points``: integer. Default value: 3. Minimum number of quality points a
  new password must have to be accepted. One quality point is awarded for
  each character class used in the password.
- ``min_punct``: integer. Defaut value: 0. Minimum punctuation characters
  expected.
- ``min_upper``: integer. Defaut value: 0. Minimum upper characters expected.
- ``use_cracklib``: integer. Default value: 1. Set it to 0 to disable cracklib
  verification. It has no effect if cracklib is not included at compile time.

Example with defaults:

```
max_consecutive_per_class 5
min_digit 0
min_lower 0
min_points 3
min_punct 0
min_upper 0
use_cracklib 1
```


## Logs

If a user password is rejected by an OpenLDAP pwdChecker module, the user will
**not** get a detailed error message, this is by design.

Typical user message from
[ldappasswd(1)](http://www.openldap.org/software/man.cgi?query=ldappasswd&apropos=0&sektion=0&manpath=OpenLDAP+2.4-Release&format=html):

```
Result: Constraint violation (19)
Additional info: Password fails quality checking policy
```

A more detailed message is written to the server log. Server log:

```
check_password_quality: module error: (check_password.so)
Password for dn=".." does not pass required number of strength checks (2 of 3)
```


## Caveats

Runtime errors with this module (such as cracklib configuration problems) may
bring down the slapd process.

Use at your own risk.


## TODO

- use proper malloc function, see [ITS#4998](http://www.openldap.org/its/index.cgi/Archive.Incoming?selectid=4998;usearchives=1;statetype=-1)
- get rid of GOTO's


## HISTORY

- 2011-01-28: Version 1.2: Trevor Vaughan <tvaughan@onyxpoint.com> - Onyx
  Point, Inc.

  - Ensure the the configuration file is only read once per run.
  - Add max_consecutive_per_class.
  - Add LDEBUG flag for local debugging.
  - Add test code and update Makefile

- 2009-10-30: Version 1.1: Clement OUDOT - LTB-project

  - Apply patch from Jerome HUET for minUpper/minLower/minDigit/minPunct

- 2009-02-05: Version 1.0.3: Clement Oudot <clem.oudot@gmail.com> - LINAGORA
  Group

  - Add useCracklib parameter in config file (with help of Pascal Pejac)
  - Prefix log messages with "check_password: "
  - Log what character type is found for quality checking

- 2008-01-31: Version 1.0.2: Pierre-Yves Bonnetain <py.bonnetain@ba-cst.com>

  - Several bug fixes.
  - Add external config file

- 2007-06-06: Version 1.0.1: Michael Steinmann <msl@calivia.com>

  - add dn to error messages

- 2007-06-02: Version 1.0: Michael Steinmann <msl@calivia.com>
