# easycatfs

## Version 0.1.2-9000

### New features

* `easycatfs --version --full` reports on the catfs version too.


## Version 0.1.2

### New features

* Add `easycatfs cache-size` to get the total file cache size (in bytes)
  for one or more targets.

* Now `mount` and `unmount` can take more than one target as input.


## Version 0.1.1

### Bug Fixes

* The temporary root folder was not guaranteed to be unique for each user,
  resulting in clashing folder paths on multi-tenant systems.

* The temporary root folder was not guaranteed to be unique for each process,
  resulting in clashing folder paths when a user mounts the same folder in
  concurrent processes.
  
* The temporary root folder did not work if none of the environment variables
  controlling it were set.


## Version 0.1.0

### New Features

* Created `easycatfs`.

* Implemented `easycatfs mount`, `easycatfs unmount`, `easycatfs mounts`,
  and `easycatfs config.`
