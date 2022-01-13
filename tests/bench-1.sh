#! /usr/bin/env bash

function bench {
    command time --format="%E (user=%U kernel=%S) CPU=%P IO=(in=%I out=%O)" "$@"
}

mkdir -p data

## Generate large file with random bytes
file="512MiB.bin"
if [[ ! -f "data/${file}" ]]; then
    mib=${file/MiB.bin/}
    dd bs="$((${mib} / 16))M" count=16 iflag=fullblock if=/dev/urandom of="data/${file}"
fi	 

echo "Test file: ${file} [$(du --bytes data/${file} | cut -f 1) bytes]"
echo

echo "Benchmark target (./data):"
tf="$(mktemp)"
bench cp data/${file} "${tf}"
bench md5sum data/${file} > /dev/null
bench md5sum data/${file} > /dev/null
echo

data=$(easycatfs mount "${PWD}/data")
echo "Benchmark local mount (${data}):"

for kk in {1..5}; do
    echo "Iteration ${kk}:"
    bench md5sum "${data}/${file}" > /dev/null
done

rm "${tf}"

easycatfs unmount --all
