[![shellcheck](https://github.com/HenrikBengtsson/easycatfs/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/HenrikBengtsson/easycatfs/actions/workflows/shellcheck.yml)

# easycatfs - Easy Read-Only Mounting of Slow Folders onto a Local Drive

This is Linux command-line tool for mounting one or more folders on a
network file system on a local disk such that the local-disk folders
mirrors everything (read-only) on the network folder.  This will
result in:

 * faster repeated access to files
 * decreased load on the network file system

This is particularly beneficial when working on high-performance
compute (HPC) clusters used by thousands of processes from hundred of
users simultaneously.

_WARNING: The **easycatfs** tool is work in progress. It is very
fresh and needs lots of real-world testing and benchmarking before
considered stable._


## The problem

For example, say, the software you run access the same data files
under `/shared/data/` repeatedly.  If these files are large, you could
manually copy them to a local temporary folder (`cp -pR /shared/data
/tmp/$USER`), run your software, and then remove the temporary folder
(`rm /tmp/$USER/data`) when done.  This stage and unstage approach can
be a tedious and unnecessarily expensive process, especially if the
software only use a subset of the files in that folder.


## The solution

The **easycatfs** tool provides an easier solution to this problem.
All that is needed is to _specify_ the folders to be staged locally,
but there is no need for an explicit copy.  Files will only be copied,
to a local file cache, if and when read.  This caching mechanism is
fully automatic thanks to the **[catfs]** tool that is used
internally.

```sh
#! /usr/bin/env bash

## Temporarily mount folder on local drive
shared_data=$(easycatfs mount /shared/data)

some_software --input="${shared_data}"

## Unmount temporarily mounted folders
easycatfs unmount /shared/data
```

Above, `${shared_data}` would be something like
`/tmp/alice/ppid=15187/shared/data`.

_Importantly_, the software must not write to the locally mounted
version.  It is mounted as read-only and any attempts to write to it
will produce an error.


## Why read-only?

The underlying **[catfs]** file-system tool supports writing as well,
which means **easycatfs** could also do that.  For conservative
reasons, I choose to only support reading, that is, all mounts are
read-only for now.  The reason is that, the main objective for it is
to use it in HPC environment and with HPC job schedulers.  There, if a
job runs longer than its allocated time slot, the job process will be
terminated by the scheduler.  Because the underlying **catfs** mount
will also be terminated at this point, there is a risk that the write
cache will not get flushed and the written or updated files might get
lost and not propagate to the target on the network file system.  When
a job is terminated this way, many job scheduler signals something
like `SIGUSR1` to give the job process a 60-second heads up and a
chance to terminate nicely, before being killed with something like
`SIGQUIT`.  So, technically, one could add a bash trap to capture the
first signal to unmount.  However, if there are lots of file updates
and the network file system is clogged up, then 60 seconds might not
be sufficient for flushing the locally cached updates.  Until this is
better understood, I decided to support only read-only mounts.  When
we have a success story for that, I might consider revisiting write
support.


## Requirements

* Linux file system (local and network)
* Bash
* [catfs] - Cache AnyThing filesystem


## Install

To use this software, download the [latest tarball
version](https://github.com/HenrikBengtsson/easycatfs/tags), extract
it to location of choice, and put its `bin/` folder on the search
`PATH`.  For example,

```sh
curl -L -O https://github.com/HenrikBengtsson/easycatfs/archive/refs/tags/0.1.2.tar.gz
tar xf 0.1.2.tar.gz
mv easycatfs-0.1.2 /path/to/software/
export PATH=/path/to/software/easycatfs-0.1.2/bin:$PATH
```

_Tips_: If you don't already have `catfs` on the search `PATH`, you can [download the `catfs` executable binary](https://github.com/kahing/catfs/releases) and copy it to the same `bin/` folder. Alternatively, if you have Rust installed, you can install `catfs` from source as:

```sh
cargo install --root=/path/to/software/easycatfs-0.1.2/bin catfs
```


## Change log

See [NEWS](NEWS.md) for version history.


[catfs]: https://github.com/kahing/catfs
