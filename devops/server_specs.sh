#!/bin/bash

echo "🔹 Hostname & OS Info:"
hostnamectl
echo ""

echo "🔹 CPU Information:"
lscpu | grep -E 'Model name|Socket|Thread|Core|CPU\(s\)|Vendor ID'
echo ""

echo "🔹 Total Memory (RAM):"
grep MemTotal /proc/meminfo | awk '{printf "%.2f GB\n", $2 / 1024 / 1024}'
echo ""

echo "🔹 Filesystem Disk Usage:"
df -h --type=ext4 --type=xfs --type=btrfs
echo ""

echo "🔹 Max Network Bandwidth:"
# Find the network interface name (e.g., eth0, enp0s3, etc.)
interface=$(ip -o link show | awk -F': ' '{print $2}' | grep -E 'eth|enp')
# Get the max speed of the interface
ethtool $interface 2>/dev/null | grep Speed || echo "No interface or ethtool not available"
echo ""

echo "🔹 GPU Information (if available):"
lspci | grep -i vga || echo "No GPU detected"
echo ""
