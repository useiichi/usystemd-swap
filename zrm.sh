#!/bin/bash
### BEGIN INIT INFO
# Provides: zram
# Required-Start:
# Required-Stop:
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: Increased Performance In Linux With zRam (Virtual Swap Compressed in RAM)
# Description: Adapted from systemd scripts at https://github.com/mystilleef/FedoraZram
### END INIT INFO
 
start() {
    # get the number of CPUs
    num_cpus=$(grep -c processor /proc/cpuinfo)
    # if something goes wrong, assume we have 1
    [ "$num_cpus" != 0 ] || num_cpus=1
 
    # set decremented number of CPUs
    decr_num_cpus=$((num_cpus - 1))
 
    # get the amount of memory in the machine
    mem_total_kb=$(grep MemTotal /proc/meminfo | grep -E --only-matching '[[:digit:]]+')
	
    #we will only assign 50% of system memory to zram
    mem_total_kb=$((mem_total_kb / 5))
 
    mem_total=$((mem_total_kb * 1024))
 
    # load dependency modules
    modprobe zram num_devices=$num_cpus
 
    # initialize the devices
    for i in $(seq 0 $decr_num_cpus); do
    echo $((mem_total / num_cpus)) > /sys/block/zram$i/disksize
    done
 
    # Creating swap filesystems
    for i in $(seq 0 $decr_num_cpus); do
    mkswap /dev/zram$i
    done
 
    # Switch the swaps on
    for i in $(seq 0 $decr_num_cpus); do
    swapon -p 100 /dev/zram$i
    done
}
 
stop() {
	for i in $(grep '^/dev/zram' /proc/swaps | awk '{ print $1 }'); do
		swapoff "$i"
	done
 
	if grep -q "^zram " /proc/modules; then
		sleep 1
		rmmod zram
	fi
}
 
 
case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        stop
        sleep 3
        start
        ;;
esac
wait
