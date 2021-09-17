# Cygwin Mirror and Installation

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
