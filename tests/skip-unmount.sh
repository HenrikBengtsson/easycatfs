#! /usr/bin/env bash

## If 'easycatfs' is not on the PATH, ...
if ! which easycatfs &> /dev/null; then
    ## try to load it as an environment module
    module load CBI 2> /dev/null  ## specific to C4 & Wynton
    module load easycatfs 2> /dev/null
fi

which easycatfs &> /dev/null || { 2>&1 echo "ERROR: No such executable: easycatfs"; exit 1; }

echo "easycatfs and catfs versions:"
easycatfs --version --full
echo

echo "Hostname: $(hostname)"

echo "Other existing job-specific /scratch folders:"
# shellcheck disable=SC2207
dirs=($(find /scratch -maxdepth 1 -user "${USER}" -type d))
count=${#dirs[@]}
count=$((count-1))
echo " - count: ${count}"
for dir in "${dirs[@]}"; do
    ## Skip current TMPDIR folder
    [[ "${dir}" == "${TMPDIR}" ]] && continue
    echo "Folder: ${dir}"
    du -s --bytes "${dir}"
    echo "Scanning for open files (lsof):"
    lsof +D "${dir}"
    echo "Scanning for open files (fuser):"
    fuser -vm "${dir}"
    echo "Removing ..."
    rm -rf "${dir}"
    if [[ -d "${dir}" ]]; then
	echo "FAILED"
    else
	echo "REMOVED"
    fi
done

echo "Pre-existing mounts:"
easycatfs mounts --full

echo "Pre-existing catfs processes:"
# shellcheck disable=SC2207
pids=($(pgrep catfs))
echo " - count: ${#pids[@]}"
for pid in "${pids[@]}"; do
    echo "catfs (pid $pid):"
    pstree -a -p -l "$pid"
done

echo "All user's processes:"
# shellcheck disable=SC2009
ps aux | grep -E "\b${USER}\b"


echo "Mounting current folder:"
L_PWD=$(easycatfs mount "$PWD")
easycatfs mounts --full


mkdir -p data

## Generate large file with random bytes
file="1024MiB.bin"
if [[ ! -f "data/${file}" ]]; then
    mib=${file/MiB.bin/}
    echo "Creating random file: ${file} [${mib} MiB]"
    dd bs="$((mib / 16))M" count=16 iflag=fullblock if=/dev/urandom of="data/${file}" 2> /dev/null
fi	 

echo "Test file: ${file} [$(du --bytes data/${file} | cut -f 1) bytes]"
echo

md5sum "${L_PWD}/data/${file}"

easycatfs cache-size --all --full

echo "Scanning for open files (lsof):"
lsof +D "${L_PWD}"
echo "Scanning for open files (fuser):"
fuser -vm "${L_PWD}"

## Force kill current process
echo "Terminating current process ..."
kill -TERM "$$"
echo "This line should never be reached"

