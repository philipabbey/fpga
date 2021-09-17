@echo off
rem
rem Reference: https://superuser.com/questions/40545/upgrading-and-installing-packages-through-the-cygwin-command-line/301026#301026
rem Setup command-line arguments: https://cygwin.com/faq/faq.html#faq.setup.cli
rem
rem Full mirror created by this script is 96GB and took ~2 hours to rsync.
rem Subsequent updates took seconds and after 2 days < 100 MB changes packages.
rem
rem Check the script setup:
rem

rem ***************************************************************************
rem Choose the dated mirror to install from
set DATEDMIRROR=2021-07-08-14-03-58
rem Choose the location on your local disk to install to
set INSTALLDIR=D:\cygwin64

rem Need one of the following two, either install over HTTP(s) or via local path names
rem Could not get a mapped drive letter to work here, it's better to use the SMB/CIFS share name.
rem This is probably because once you elevate to Administrator, the drive mappings can be different.
rem i.e. NOT T:\cygwin-mirror but...
set MIRRORPATH=\\cygwin.local\website\cygwin-mirror
set MIRRORURL=https://www.cygwin.local/cygwin-mirror/%DATEDMIRROR%/

rem Choose installation method: local or mirror?
rem 0 for install from mirror over HTTP(s)
rem 1 for install using local path names and mapped drives
rem If the Cygwin mirror has no webserver, you must use local.
rem If you use the "install from mirror" option, the package files get downloaded locally and take additional space.
set LOCAL=1
rem ***************************************************************************

rem derived variables
set SETUPPATH=%MIRRORPATH%\%DATEDMIRROR%

rem common variable between the two installation types
set CATEGORIES=Base,Devel
rem rhash includes crc32
set PACKAGES=bc,cygutils-extra,nc,procps,psmisc,rhash,zip

rem Cygwin setup 2.905
rem `
rem Command Line Options:
rem 
rem     --allow-unsupported-windows    Allow old, unsupported Windows versions
rem  -a --arch                         Architecture to install (x86_64 or x86)
rem  -C --categories                   Specify entire categories to install
rem  -o --delete-orphans               Remove orphaned packages
rem  -A --disable-buggy-antivirus      Disable known or suspected buggy anti virus
rem                                    software packages during execution.
rem  -D --download                     Download packages from internet only
rem  -f --force-current                Select the current version for all packages
rem  -h --help                         Print help
rem  -I --include-source               Automatically install source for every
rem                                    package installed
rem  -i --ini-basename                 Use a different basename, e.g. "foo",
rem                                    instead of "setup"
rem  -U --keep-untrusted-keys          Use untrusted keys and retain all
rem  -L --local-install                Install packages from local directory only
rem  -l --local-package-dir            Local package directory
rem  -m --mirror-mode                  Skip package availability check when
rem                                    installing from local directory (requires
rem                                    local directory to be clean mirror!)
rem  -B --no-admin                     Do not check for and enforce running as
rem                                    Administrator
rem  -d --no-desktop                   Disable creation of desktop shortcut
rem  -r --no-replaceonreboot           Disable replacing in-use files on next
rem                                    reboot.
rem  -n --no-shortcuts                 Disable creation of desktop and start menu
rem                                    shortcuts
rem  -N --no-startmenu                 Disable creation of start menu shortcut
rem  -X --no-verify                    Don't verify setup.ini signatures
rem     --no-version-check             Suppress checking if a newer version of
rem                                    setup is available
rem     --enable-old-keys              Enable old cygwin.com keys
rem  -O --only-site                    Do not download mirror list.  Only use sites
rem                                    specified with -s.
rem  -M --package-manager              Semi-attended chooser-only mode
rem  -P --packages                     Specify packages to install
rem  -p --proxy                        HTTP/FTP proxy (host:port)
rem  -Y --prune-install                Prune the installation to only the requested
rem                                    packages
rem  -K --pubkey                       URL or absolute path of extra public key
rem                                    file (RFC4880 format)
rem  -q --quiet-mode                   Unattended setup mode
rem                                    Comment: You still get the setup progress dialogue box
rem  -c --remove-categories            Specify categories to uninstall
rem  -x --remove-packages              Specify packages to uninstall
rem  -R --root                         Root installation directory
rem  -S --sexpr-pubkey                 Extra DSA public key in s-expr format
rem  -s --site                         Download site URL
rem  -u --untrusted-keys               Use untrusted saved extra keys
rem  -g --upgrade-also                 Also upgrade installed packages
rem     --user-agent                   User agent string for HTTP requests
rem  -v --verbose                      Verbose output
rem  -V --version                      Show version
rem  -W --wait                         When elevating, wait for elevated child
rem                                    process

rem
rem Do the work
rem

if exist %SETUPPATH%\setup-x86_64.exe (
  echo Executing: %SETUPPATH%\setup-x86_64.exe

  if %LOCAL% EQU 1 (
    echo List of available dated mirrors
    dir %MIRRORPATH%
    echo.
    echo You have chosen: %DATEDMIRROR%
    echo.
    echo Ignore "Cygwin Setup (Not Responding)" dialogue box, it's just busy!
    echo.
    %SETUPPATH%\setup-x86_64.exe ^
      --no-desktop ^
      --quiet-mode ^
      --wait ^
      --arch x86_64 ^
      --root %INSTALLDIR% ^
      --local-package-dir %MIRRORPATH%\%DATEDMIRROR% ^
      --local-install ^
      --categories %CATEGORIES% ^
      --packages %PACKAGES% ^
      --quiet-mode

  ) else (

    %SETUPPATH%\setup-x86_64.exe ^
      --no-desktop ^
      --quiet-mode ^
      --wait ^
      --arch x86_64 ^
      --root %INSTALLDIR% ^
      --only-site ^
      --local-package-dir %USERPROFILE%\Downloads ^
      --site %MIRRORURL% ^
      --categories %CATEGORIES% ^
      --packages %PACKAGES% ^
      --quiet-mode

  )

) else (
  echo Cannot find '%SETUPPATH%\setup-x86_64.exe', check the DATEDMIRROR variable
)

pause
