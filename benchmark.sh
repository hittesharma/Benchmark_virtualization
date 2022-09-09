#!/bin/bash

# Record the Unix timestamp before starting the benchmarks.
time=$(date +%s)
runtime=5

# Run the sysbench CPU test and extract the "events per second" line.
1>&2 echo "Running CPU test..."
cpu=$(sysbench --time=$runtime cpu run | grep "events per second" | awk '/ [0-9.]*$/{print $NF}')

# Run the sysbench memory test and extract the "transferred" line. Set large total memory size so the benchmark does not end prematurely.
1>&2 echo "Running memory test..."
mem=$(sysbench --time=$runtime --memory-block-size=4K --memory-total-size=100T memory run | grep transferred | awk '/([0-9.]* MiB.sec)/{print $1}')

# Prepare one file (1GB) for the disk benchmarks
1>&2 sysbench --file-total-size=1G --file-num=1 fileio prepare

# Run the sysbench sequential disk benchmark on the prepared file. Use the direct disk access flag. Extract the number of read MiB.
1>&2 echo "Running fileio sequential read test..."
diskSeq=$(sysbench --time=$runtime --file-test-mode=seqrd --file-total-size=1G --file-num=1 --file-extra-flags=direct fileio run | grep "read, MiB" | awk '/ [0-9.]*$/{print $NF}')

# Run the sysbench random access disk benchmark on the prepared file. Use the direct disk access flag. Extract the number of read MiB.
1>&2 echo "Running fileio random read test..."
diskRand=$(sysbench --time=$runtime --file-test-mode=rndrd --file-total-size=1G --file-num=1 --file-extra-flags=direct fileio run | grep "read, MiB" | awk '/ [0-9.]*$/{print $NF}')

1>&2 echo "Running fork test..."
# Run the forkbenchmark
# Compile & make the forksum executable
make forksum 1>&2
chmod +x forksum
# Init vars
currentSessionTime60=$((SECONDS+60))
forksumSum=0
counter=0
# Loop until 60 seconds are over
while [ $SECONDS -lt $currentSessionTime60 ]; do
    lastRun="$(./forksum 1024 2048)"
    forksumSum="$(echo $lastRun + $forksumSum | bc -l )"
    ((counter=counter+1))
done
# Calc the average
forksAvg="$(echo $forksumSum / $counter | bc -l )"

1>&2 echo "Running network benchmark..."
# Run the network benchmark
# Set uplink per default to 0 to cope with server down
uplink="0"
# Run the iperf3 benchmark
uplink=$(iperf3 --format M --parallel 5 --interval 0 --time 60 --client 35.223.83.97 \
            | tee -a /dev/stderr \
            | grep 'SUM' | grep 'sender' | awk 'END{print $6}')

# Output the benchmark results as one CSV line
echo "$time,$cpu,$mem,$diskSeq,$diskRand,$forksAvg,$uplink"
