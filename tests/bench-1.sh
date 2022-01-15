#! /usr/bin/env bash

function bench {
    local res

#    ## For some reason, this doesn't work on Wynton    
#    local n
#    mapfile -t res < <(command time --format="%E (user=%U kernel=%S) CPU=%P IO=(in=%I out=%O)" "$@" 2>&1)
#    n=${#res[@]}
#    res=${res[$((n-1))]}

    res=$(command time --format="%E (user=%U kernel=%S) CPU=%P IO=(in=%I out=%O)" "$@" 2>&1)
    res=$(echo "${res}" | tail -1)

    echo "$1: ${res}"
}


echo "easycatfs and catfs versions:"
easycatfs --version --full
echo

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

echo "Benchmark target (./data):"
tf="$(mktemp)"
bench cp data/${file} "${tf}"
for kk in {1..5}; do
    printf "%d. " "${kk}"
    bench md5sum data/${file}
done
echo

data=$(easycatfs mount "${PWD}/data")
echo "Benchmark local mount (${data}):"

for kk in {1..5}; do
    printf "%d. " "${kk}"
    bench md5sum "${data}/${file}"
done

rm "${tf}"

easycatfs unmount --all
