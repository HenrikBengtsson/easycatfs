[![shellcheck](https://github.com/HenrikBengtsson/easycatfs/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/HenrikBengtsson/easycatfs/actions/workflows/shellcheck.yml)

# easycatfs - Easy Mounting of Slow Folders onto Local Disk

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
under `/shared/data/` over and over.  If these files are large and
live on a network file system, a significant amount of the processing
time might be spend on the extra overhead that comes from reading
files over the network.  Also, if the network file system is busy
serving many other processes and users at the same time, there is also
slow down due to this.

One approach to address this is to manually copy the files we need to
a local temporary folder (`cp -pR /shared/data /tmp/$USER`) and point
our software to these locally hosted files.  If the software accesses
the same files multiple times, we will see a performance improvement
because we suffer less from the overhead that comes from working
directly towards the network file system. When done, we must not
forget to remove the temporary folder (`rm -rf /tmp/$USER/data`).

This stage and unstage approach can be a tedious and an unnecessarily
expensive process, especially if the software only use a subset of the
files in that folder.


## The solution

The **easycatfs** tool provides an easier solution to this problem.
All that is needed is to _specify_ the folders to be staged locally,
but there is no need for an explicit copy.  Files will only be copied,
to a local file cache, if and when read.  This caching mechanism is
fully automatic thanks to the **[catfs]** tool that is used
internally.

```sh
#! /usr/bin/env bash

## Make sure to unmount everything (also on interrupts and errors)
trap "easycatfs unmount --all" EXIT

## Temporarily mount two folders on local drive
ref=$(easycatfs mount "/resources/ref")
data=$(easycatfs mount "/shared/data")

cntseq -r "${ref}/hg.fa" -i "${data}/sample1.fq" sample1.bam
cntseq -r "${ref}/hg.fa" -i "${data}/sample2.fq" sample2.bam
```

Above, `${ref}` would be something like
`/tmp/alice/ppid=15187/resources/ref`. and `${data}` something like
`/tmp/alice/ppid=15187/shared/data`.

_Importantly_, the software must not write to these locally mounted
folders.  They are mounted as read-only and any attempts to write to
them will produce an error.


## Alternative style

An alternative style to the one used in the above example is:

```sh
#! /usr/bin/env bash

## Make sure to unmount everything (also on interrupts and errors)
trap "easycatfs unmount --all" EXIT

## Temporarily mount two folders on local drive
L_ROOT=$(easycatfs config root)
easycatfs mount "/resources/ref" "/shared/data"

cntseq -r "${L_ROOT}/resources/ref/hg.fa" -i "${L_ROOT}/shared/data/sample1.fq" sample1.bam
cntseq -r "${L_ROOT}/resources/ref/hg.fa" -i "${L_ROOT}/shared/data/sample2.fq" sample2.bam
```

which better resembles the version that would work directly toward the targets;

```sh
cntseq -r "/resources/ref/hg.fa" -i "/shared/data/sample1.fq" sample1.bam
cntseq -r "/resources/ref/hg.fa" -i "/shared/data/sample2.fq" sample2.bam
```


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
* libfuse (e.g. `yum install fuse-lib` on CentOS and `apt install libfuse2` on Ubuntu)
* [catfs] - Cache AnyThing filesystem


## Install

To use this software, download the [latest tarball
version](https://github.com/HenrikBengtsson/easycatfs/tags), extract
it to location of choice, and put its `bin/` folder on the search
`PATH`.  For example,

```sh
curl -L -O https://github.com/HenrikBengtsson/easycatfs/archive/refs/tags/0.1.4.tar.gz
tar xf 0.1.4.tar.gz
mv easycatfs-0.1.4 /path/to/software/
export PATH=/path/to/software/easycatfs-0.1.4/bin:$PATH
```

The **[catfs]** project provides [prebuilt executables](https://github.com/kahing/catfs/releases) and easy ways to install from source (`cargo install catfs`).  However, those version are too old.  Instead, we want to install the developer version available on GitHub from source:

```sh
git clone https://github.com/kahing/catfs.git
cargo install --root=/path/to/software/easycatfs-0.1.4 --path=catfs
```

In order to build from source, you also need the development files for **libfuse**, e.g. `yum install fuse-lib` on CentOS and `apt install libfuse-dev` on Ubuntu.


## Change log

See [NEWS](NEWS.md) for version history.


[catfs]: https://github.com/kahing/catfs
