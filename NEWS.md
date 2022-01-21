# easycatfs

## Version 0.1.4-9002

### New features

* Add `easycatfs clear-cache`.

* Now `easycatfs unmount` reports on the current cache size before unmounting,
  unless `--quiet` is used.

* Now `easycatfs mount` support `--quiet`.

* Now `easycatfs cache-size --full` gives a per target and total cache size.

* Add option `--quiet`.

### Bug fixes

* `easycatfs cache-size <target>` would calculate the size of the target
  folder and not the cache for the target folder.


## Version 0.1.4

### New features

* Add support for `easycatfs config root`, `easycatfs config --full root`,
  and  `easycatfs config --all`.

* Environment variable `CATFS` can be used to override the default 'catfs'
  binary otherwise found on the `PATH`.
  

## Version 0.1.3

### New features

* `easycatfs --version --full` reports on the catfs version too.

### Bug fixes

* `easycatfs mount` would not guarantee that the mount point is ready
  before returning. Now it polls the mount point until available.


## Version 0.1.2

### New features

* Add `easycatfs cache-size` to get the total file cache size (in bytes)
  for one or more targets.

* Now `mount` and `unmount` can take more than one target as input.


## Version 0.1.1

### Bug fixes

* The temporary root folder was not guaranteed to be unique for each user,
  resulting in clashing folder paths on multi-tenant systems.

* The temporary root folder was not guaranteed to be unique for each process,
  resulting in clashing folder paths when a user mounts the same folder in
  concurrent processes.
  
* The temporary root folder did not work if none of the environment variables
  controlling it were set.


## Version 0.1.0

### New features

* Created `easycatfs`.

* Implemented `easycatfs mount`, `easycatfs unmount`, `easycatfs mounts`,
  and `easycatfs config.`
