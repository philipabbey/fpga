# Cygwin Mirror and Installation

![Repeatable dated mirror and installation from that local mirror](./media/Dated_Mirror_Installation.png?raw=true "Repeatable dated mirror and installation from that local mirror")

I'm in a team of FPGA developers creating designs on Windows machines but we have a Linux build server. In order to provide a common build scripts between the Linux Build Server and our local Windows PCs we use Cygwin to execute the build scripts locally so that the same build scripts can be used in both environments. We now need a means to ensure that each person using the build scripts has the same installation of Cygwin, even if they need to reinstall their Windows PC. The problems I aim to solve here are the evolving nature of the Cygwin mirrors which means any two installations a few days apart can be different, and scripting the selection of packages to install.

Please read the blog post [Cygwin Mirror and Installation](http://blog.abbey1.org.uk/index.php/technology/cygwin-mirror-and-installation) to explain how the code works in detail.

## Customisation

### Date Mirror Server

```shell
MIRRORSITE="rsync://cygwin.mirror.constant.com/cygwin-ftp"
MIRRORLOC="/data/website/cygwin-mirror"
KEEP=3
```

* `MIRRORSITE`: See the [list of possible mirror sites](https://cygwin.com/mirrors.html) that can be used as the source.
* `MIRRORLOC`: The destination directory on your local server.
* `KEEP`: the maximum number of previous mirrors to retain.

### Development Client PC

```batch
set DATEDMIRROR=2021-07-08-14-03-58
set INSTALLDIR=D:\cygwin64
set MIRRORPATH=\\cygwin.local\website\cygwin-mirror
set MIRRORURL=https://www.cygwin.local/cygwin-mirror/%DATEDMIRROR%/
set LOCAL=1
set CATEGORIES=Base,Devel
set PACKAGES=bc,cygutils-extra,nc,procps,psmisc,rhash,zip
```

* `DATEDMIRROR`: Choose the dated mirror to install. This is a sub-directory name in either `MIRRORPATH` or `MIRRORURL`.
* `INSTALLDIR`: Choose the location on your local disk to install to.
* `MIRRORPATH`: CIFS/SMB share path beginning `\\`, not a path starting with a drive letter like `W:`.
* `MIRRORURL`: URL to use for HTTP(s).
* `LOCAL`: Switch between the two methods of installation:
   * `LOCAL=0`: to install from mirror over HTTP(s). This means downloading the packages to install to the local PC. If the Cygwin mirror has not CIFS/SMB services you must set `LOCAL=0`.
   * `LOCAL=1`: to install using local path names and mapped drives. This avoids downloading the packages to the local PC, but requires CIFS/SMB for a networked drive under Windows. If the Cygwin mirror has no webserver, you must set `LOCAL=1`.
* `CATEGORIES`: Broad categories that Cygwin uses to install groups of packages.
* `PACKAGES`: Individual packages required to top-up or fine tune the categories.

## Execution

On the dated mirror host run the following every month or so. It will created an approximately 100GB mirror the first time. Thereafter it will just be the differences.

```shell
./sync-mirror.bash
```

On the development client PC install using [cygwin-install.cmd](cygwin-install.cmd).
