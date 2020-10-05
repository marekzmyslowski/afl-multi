#
# afl-multi
# The script runs mulit AFL instances of the fuzzer using screen application.
# 
# Author: Marek Zmysłowski
# Version: 0.1
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
#      http://www.apache.org/licenses/LICENSE-2.0
# This is the real deal: the program takes an instrumented binary and
# attempts a variety of basic fuzzing tricks, paying close attention to
# how they affect the execution path.
# 

#!/bin/bash

function help {
    echo ""
    echo "              afl-multi version: 0.1"
    echo ""
    echo "The script runs mulitple AFL instances of the fuzzer using screen application."
    echo "Author: Marek Zmysłowski <marekzmyslowski@poczta.onet.pl>"
    echo ""
    echo "./afl-multi x:y <rest of AFL parameters>"
    echo "x - number of master instances"
    echo "y - number of slave instanves"
    
}

# Check if any parameters are provided and display help
if [ $# -eq 0 ]
then
    help
    exit 0
else
    echo "afl-multi version: 0.1"
    echo "Author: Marek Zmysłowski <marekzmyslowski@poczta.onet.pl>"
fi

# Check if the screen application is installed
if ! [ -x "$(command -v screen)" ]; then
  echo 'Error: screen is not installed.' >&2
  exit 1
fi

echo ""
# Split the parameter for instances
instances=($(echo "$1" | tr ':' '\n'))

# Check if x and y are set
if [ -z "${instances[0]}" ] || [ -z "${instances[1]}" ]; then
    echo "Error: Number of instances set incorrectly!"
    exit 1
fi

# Checking total number of instances
total=$(("${instances[0]}" + "${instances[1]}"))
if [ $total -gt $(nproc --all) ]; then 
    echo "The number of afl-fuzz instances exceedes the number of CPU cores!"
    echo "Number of CPU cores: " $(nproc --all)
    echo "Number of afl-fuzz instances to run: " $total
    read -p "Do you want to continue (Y/n)?" choice
    case "$choice" in 
        y|Y ) echo "";;
        * ) exit 1;;
    esac

fi

echo "Master instances: ${instances[0]}" 
echo "Slave instances: ${instances[1]}"

# Shift first parameter
shift

# Wait 5 second. If something is wrong there is a time to stop.
echo "Running afl-fuzz in 5 seconds ..."
sleep 5

# Run master instances
master=0
while [ $master -lt ${instances[0]} ]
do
    echo "Running master instance: $master"
    minstance=$((master+1))
    screen -S M$master -d -m bash -c "afl-fuzz -M master$master:$minstance/${instances[0]} $*"
    ((master++))
done 

# Run slave instances
slave=0
while [ $slave -lt ${instances[1]} ]
do
    echo "Running slave instance: $slave"
    screen -S S$slave -d -m bash -c "afl-fuzz -S slave$slave $*"
    ((slave++))
done 

exit 0

