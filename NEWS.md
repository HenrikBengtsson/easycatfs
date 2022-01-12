# easycatfs

## Version 0.1.1-9000

* ...


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
