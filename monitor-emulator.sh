#!/bin/bash

# Android Emulator Memory Monitor Script
# Usage: ./monitor-emulator.sh

echo "🔍 Android Emulator Memory Monitor"
echo "=================================="

while true; do
    clear
    echo "📱 Emulator Status: $(date)"
    echo "=================================="
    
    # Check ADB devices
    echo "🔗 Connected Devices:"
    adb devices | grep -v "List of devices attached"
    echo ""
    
    # Check emulator processes and memory usage
    echo "💾 Emulator Memory Usage:"
    ps aux | grep emulator | grep -v grep | while read line; do
        pid=$(echo $line | awk '{print $2}')
        mem_mb=$(echo $line | awk '{print $6}')
        mem_gb=$(awk "BEGIN {printf \"%.1f\", $mem_mb/1024/1024}")
        cmd=$(echo $line | awk '{for(i=11;i<=NF;i++) printf "%s ", $i; print ""}')
        echo "PID: $pid | Memory: ${mem_gb}GB | Command: $(basename $(echo $cmd | awk '{print $1}'))"
    done
    echo ""
    
    # System memory overview
    echo "🖥️  System Memory:"
    free -h | grep -E "(内存|Mem|交换|Swap)"
    echo ""
    
    # Check if emulator is responsive
    echo "🏃 Emulator Health Check:"
    if adb shell echo "alive" >/dev/null 2>&1; then
        echo "✅ Emulator is responsive"
        uptime_seconds=$(adb shell cat /proc/uptime | awk '{print int($1)}')
        uptime_minutes=$((uptime_seconds / 60))
        echo "⏱️  Android uptime: ${uptime_minutes} minutes"
    else
        echo "❌ Emulator not responsive"
    fi
    
    echo ""
    echo "Press Ctrl+C to exit, waiting 5 seconds..."
    sleep 5
done
