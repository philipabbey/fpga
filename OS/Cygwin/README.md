# Cygwin Mirror and Installation

![Repeatable dated mirror and installation from that local mirror](./media/Dated_Mirror_Installation.png?raw=true "Repeatable dated mirror and installation from that local mirror")

I'm in a team of FPGA developers creating designs on Windows machines but we have a Linux build server. In order to provide a common build scripts between the Linux Build Server and our local Windows PCs we use Cygwin to execute the build scripts locally so that the same build scripts can be used in both environments. We now need a means to ensure that each person using the build scripts has the same installation of Cygwin, even if they need to reinstall their Windows PC. The problems I aim to solve here are the evolving nature of the Cygwin mirrors which means any two installations a few days apart can be different, and scripting the selection of packages to install.

Please read the blog post [Cygwin Mirror and Installation](http://blog.abbey1.org.uk/index.php/technology/cygwin-mirror-and-installation) to explain how the code works in detail.

## Customisation

```shell
MIRRORSITE="rsync://cygwin.mirror.constant.com/cygwin-ftp"
MIRRORLOC="/data/website/cygwin-mirror"
KEEP=3
```

* `MIRRORSITE`: See the [list of possible mirror sites](https://cygwin.com/mirrors.html) that can be used as the source.
* `MIRRORLOC`: The destination directory on your local server.
* `KEEP`: the maximum number of previous mirrors to retain.
