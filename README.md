# easycatfs - Easy Read-Only Mounting of Slow Folders onto a Local Drive

This is Linux command-line tool for mounting one or more folders on a
network file system on a local disk such that the local-disk folders
mirrors everything (read-only) on the network folder.  This will
result in:

 * faster repeated access to files
 * decreased load on the network file system

This is particularly beneficial when working on high-performance
compute (HPC) clusters used by hundreds and thousands of processes and
users simultaneously.

For example, say the software you use access the same data files under
`/shared/data/` repeatedly.  If these files are large, you could
manually copy them to a local temporary folder (`cp -pR /shared/data
/tmp/$USER`), run your software, and then remove the temporary folder
(`rm /tmp/$USER/data`) when done.  This can be a tedious and
unnecessarily expensive process, especially if the software only use a
subset of the files in that folder.  The **easycatfs** tool solved this
problem by working similarly, but it will only copy files to a local
cache folder as they are needed. This caching mechanism is fully
automatic thanks to the **[catfs]** tool that is used internally.

```sh
#! /usr/bin/env bash

## Temporarily mount folder on local drive
shared_data=$(easycatfs mount /shared/data)

some_software --input="${shared_data}"

## Unmount temporarily mounted folders
easycatfs unmount /shared/data
```

Above, `${shared_data}` would be something like `/tmp/alice/shared/data`

_Importantly_, the software must not write to the locally mounted
version.  It is mounted as read-only and any attempts to write to it
will produce an error.


## Quality

The **easycatfs** tool is very fresh and needs lots of real-world
testing and benchmarking before considered stable.


## Write-only?

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

* Linux file system (local and remote)
* Bash
* [catfs] - Cache AnyThing filesystem


## Install

To use this software, download the [latest tarball
version](https://github.com/HenrikBengtsson/easycatfs/tags), extract
it to location of choice, and put its `bin/` folder on the search
`PATH`.  For example,

```sh
curl -L -O https://github.com/HenrikBengtsson/easycatfs/archive/refs/tags/0.1.0.tar.gz
tar xf easycatfs-0.1.0.tar.gz
mv easycatfs-0.1.0 /path/to/software/
export PATH=/path/to/software/easycatfs-0.1.0/bin:$PATH
```


[catfs]: https://github.com/kahing/catfs

