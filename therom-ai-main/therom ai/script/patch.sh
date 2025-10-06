#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
theorem_ai=`realpath "$DIR"/../bin/theorem_ai`
LEANC=`realpath "$DIR"/../bin/leanc`
StdLib=`realpath "$DIR"/../library`
echo "Using theorem_ai at: $theorem_ai"
echo "Using leanc at: $LEANC"
echo "Using stdlib at: $StdLib"

if [ "$#" -ne 1 ]; then
    echo "illegal number of parameters, usage `patch.sh <patcher.theorem_ai>`"
    exit 1
fi

PatcherSource=$1
PatcherExe="$PatcherSource".out
PatcherDir=`dirname $PatcherSource`

export LEAN_PATH=$PatcherDir:$StdLib

if [ ! -f $PatcherSource ]; then
    echo "theorem_ai patcher source file does not exist"
    exit 1
fi

if [ $PatcherSource -nt $PatcherExe ]; then
    echo "Compiling patcher program"
    $theorem_ai --cpp="$PatcherSource".cpp "$PatcherSource"
    if [ $? -ne 0 ]; then
        echo "Failed to compile $PatcherSource into C++ file"
        exit 1
    fi
    $LEANC -O3 -o "$PatcherExe" "$PatcherSource".cpp
    if [ $? -ne 0 ]; then
        echo "Failed to compile C++ file $PatcherSource.cpp"
        exit 1
    fi
    echo "Generated patcher executable: $PatcherExe"
fi

for leanFile in `find . -name '*.theorem_ai'`; do
    echo "Converting $leanFile"
    cp $leanFile $leanFile.old
    $PatcherExe $leanFile > $leanFile.new
    if [ $? -ne 0 ]; then
        echo "Failed to generate $leanFile.new"
        exit 1
    fi
done

for leanFile in `find . -name '*.theorem_ai'`; do
    # TODO: finish script
    diff $leanFile $leanFile.new > /dev/null
    if [ $? -ne 0 ]; then
        echo "modified $leanFile"
        mv $leanFile.new $leanFile
        rm -f $leanFile.old
    fi
done
