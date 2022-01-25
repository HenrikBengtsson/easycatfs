#! /usr/bin/env bash

# Adopted from https://combine-lab.github.io/salmon/getting_started/
# Below, 'salmon quant ...' takes ??? minutes

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

## If 'easycatfs' is not on the PATH, ...
if ! which easycatfs &> /dev/null; then
    ## try to load it as an environment module
    module load CBI 2> /dev/null  ## specific to C4 & Wynton
    module load easycatfs 2> /dev/null
fi
which easycatfs &> /dev/null || { 2>&1 echo "ERROR: No such executable: easycatfs"; exit 1; }

MODULEPATH=$HOME/modulefiles:$MODULEPATH
module load easycatfs/devel

echo "easycatfs and catfs versions:"
easycatfs --version --full
echo


## If 'salmon' is not on the PATH, ...
if ! which salmon &> /dev/null; then
    ## try to load it as an environment module
    module load CBI 2> /dev/null  ## specific to C4 & Wynton
    module load salmon 2> /dev/null
fi
which salmon &> /dev/null || { 2>&1 echo "ERROR: No such executable: salmon"; exit 1; }

echo "salmon version:"
salmon --version
echo

## Assert reference transcriptome index exists
[[ -d athal_index ]] || { 2>&1 echo "ERROR: No such folder: athal_index"; exit 1; }

## Assert sample sequence files exist
sample=DRR016125
for kk in {1..2}; do
    file="data/${sample}_${kk}.fastq.gz"
    [[ -f "${file}" ]] || { 2>&1 echo "ERROR: No such folder: ${file}"; exit 1; }
done

tf="$(mktemp -d)"

echo "Benchmark targets:"
echo " - Targets"
echo "   1. ./athal_index"
echo "   2. ./data"
bench cp data/"${sample}"_?.fastq.gz "${tf}"
for kk in {1..3}; do
    printf "%d. " "${kk}"
    bench salmon quant -i athal_index -l A -1 "data/${sample}_1.fastq.gz" -2 "data/${sample}_2.fastq.gz" -p 8 --validateMappings -o "${tf}/quants/${sample}_quant"
    rm -rf "${tf}/quants"
done
echo

## Make sure to unmount everything (also on errors)
trap "easycatfs unmount --all" EXIT

## Mount targets locally
athal_index=$(easycatfs mount "${PWD}/athal_index")
echo "Benchmark local mounts:"
echo " - Mountpoints"
echo "   1. ${athal_index}"
for kk in {1..3}; do
    printf "%d. " "${kk}"
    bench salmon quant -i "${athal_index}" -l A -1 "data/${sample}_1.fastq.gz" -2 "data/${sample}_2.fastq.gz" -p 8 --validateMappings -o "${tf}/quants/${sample}_quant"
    rm -rf "${tf}/quants"
done
echo
easycatfs unmount --all


## Mount targets locally
athal_index=$(easycatfs mount "${PWD}/athal_index")
data=$(easycatfs mount "${PWD}/data")
echo "Benchmark local mounts:"
echo " - Mountpoints"
echo "   1. ${athal_index}"
echo "   2. ${data}"
for kk in {1..3}; do
    printf "%d. " "${kk}"
    bench salmon quant -i "${athal_index}" -l A -1 "${data}/${sample}_1.fastq.gz" -2 "${data}/${sample}_2.fastq.gz" -p 8 --validateMappings -o "${tf}/quants/${sample}_quant"
    rm -rf "${tf}/quants"
done
echo

rm -rf "${tf}"
