#! /usr/bin/env bash

# Adopted from https://combine-lab.github.io/salmon/getting_started/
# Below, 'salmon index ...' takes ~45-50 seconds on Wynton, regardess of file location

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

file=athal.fa.gz
echo "Input file: ${file} [$(du --bytes ref/${file} | cut -f 1) bytes]"
echo

echo "Benchmark target (./ref):"
ls -l "ref/${file}"
tf="$(mktemp -d)"
bench cp "ref/${file}" "${tf}"
for kk in {1..2}; do
    printf "%d. " "${kk}"
    bench salmon index -t "ref/${file}" -i "${tf}/athal_index"
    ls -la "${tf}/athal_index"
    rm -rf "${tf}/athal_index"
done
echo

## Make sure to unmount everything (also on errors)
trap "easycatfs unmount --all" EXIT

## Mount targets locally
ref=$(easycatfs mount "${PWD}/ref")
echo "Benchmark local mount (${ref}):"
ls -l "${ref}/${file}"
for kk in {1..2}; do
    printf "%d. " "${kk}"
    bench salmon index -t "${ref}/${file}" -i "${tf}/athal_index"
    ls -la "${tf}/athal_index"
    rm -rf "${tf}/athal_index"
done

rm -rf "${tf}"

