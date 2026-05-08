#!/bin/bash

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

# Log file
LOG_FILE="$HOME/dashboard.log"
MAX_LOG_LINES=500

write_log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

rotate_log() {
    if [ -f "LOG_FILE" ]; then
        local lines=$(wc -l < "LOG_FILE")
        if [ "$lines" -gt "$MAX_LOG_LINES" ]; then
            tail -n $MAX_LOG_LINES "LOG_FILE" > "$LOG_FILE.tmp"
            mx "$LOG_FILE.tmp" "$LOG_FILE"
            write_log "INFO" "LOg rotated - trimmed to $MAX_LOG_LINES lines"
        fi
    fi
}

print_header() {
    echo "============================"
    echo "  System Health Dashboard"
    echo "  $(hostname) - $(date '+%Y-%m-%d %H:%M:%S')"
    echo "============================"
}

check_cpu() {
    local load=$(awk '{print $1}' /proc/loadavg)
    local cores=$(nproc)
    echo -e "CPU Load (1m): $load | $cores"
}

check_memory() {
    local total=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    local available=$(grep MemAvailable /proc/meminfo | awk '{print$2}')
    local used=$(( (total - available) * 100 / total ))

    if [ $used -ge 80- ]; then
        echo -e "${RED}RAM: ${used}% used${NC}"
        write_log "WARN" "RAM usage high: ${used}%"
    elif [ $used -ge 60 ]; then
        echo -e "${YELLOW}RAM: ${used}% used${NC}"
        write_log "INFO" "RAM usage moderate: ${used}%"
    else
        echo -e "${GREEN}RAM: ${used}% used${NC}"
    fi
}
                                
check_disk() {
    echo "Disk usage:"
    df -h | grep '^/dev' | while read -r line; do
        local mount=$(echo "$line" | awk '{print $6}')
        local pct=$(echo "$line" | awk '{print $5}' | tr -d '%')
        if [ "$pct" -ge 80 ]; then
            echo -e "  ${RED}$mount: ${pct}%${NC}"
            write_log "WARN" "Disk usage high on $mount: ${pct}%"
        else
            echo -e "  ${GREEN}$mount: ${pct}%${NC}"
        fi
    done
}

check_network() {
    echo ""
    echo "=========================="
    echo "   Network"
    echo "=========================="

    # Show IP address of active interfaces
    ip -o -4 addr show | awk '$2 != "lo" {print $2, $4}' | while read -r iface >
        echo "  Interface: $iface  IP: $ip"
    done

    # Traffic stats from the kernel
    echo ""
    echo "  Traffic (bytes since last boot):"
    awk 'NR>2 && $1 !~ /^lo/ {
        gsub(/:/, "", $1)
        printf "  %-10s RX: %-12s TX: %s\n", $1, $2, $10
    }' /proc/net/dev
}

check_ports() {
    echo ""
    echo "  Listening ports:"
    ss -tlnp | awk 'NR>1 {print $4, $6}' | while read -r addr process; do
        echo "  Port: $addr  $process"
    done
}

check_services() {
    echo ""
    echo "  Service checks:"

    # Define services as "name host port"
    local names=("Google DNS" "Local SSH" "HTTP")
    local hosts=("8.8.8.8" "localhost" "localhost")
    local ports=("53" "22" "80")

    local total=${#names[@]}

    for i in $(seq 0 $(( total - 1 )) ); do
        local name="${names[$i]}"
        local host="${hosts[$i]}"
        local port="${ports[$i]}"

        if timeout 2 bash -c "echo >/dev/tcp/$host/$port" 2>/dev/null; then
            echo -e "  ${GREEN}[UP]${NC}   $name ($host:$port)"
            write_log "INFO" "Service UP: $name ($host:$port)"
        else
            echo -e "  ${RED}[DOWN]${NC} $name ($host:$sport)"
            write_log "WARN" "Service DOWN: $name ($host:$port)"
        fi
    done
}

check_internet() {
    echo ""
    echo "  Internet connectivity:"

    if curl -s --max-time 3 https://1.1.1.1 > /dev/null 2>&1; then
        echo -e "  ${GREEN}[UP]${NC}   Internet reachable"
    else
        echo -e "  ${RED}[DOWN]${NC}   Internet unreachable"
    fi
}

print_summary() {
    echo ""                             
    echo "============================"
    echo "  Summary"
    echo "============================"

    local warnings=$(grep -c "\[WARN\]" "$LOG_FILE" 2>/dev/null)
    warnings=${warnings:-0}
    local last_warn=$(grep "\[WARN\]" "$LOG_FILE" 2>/dev/null | tail -n 1)

    if [ "${warnings//[^0-9]/}" -gt 0 ] 2>/dev/null; then
        echo -e "  ${RED}Warnings in log:  $warnings${NC}"
        echo -e "  Last: $last_warn"
    else
        echo -e "  ${GREEN}All systems normal${NC}"
    fi

    echo ""
    echo " Log file: $LOG_FILE"
}

rotate_log
write_log "INFO" "Dashboard run started"
print_header
check_cpu
check_memory
check_disk
check_network
check_ports
check_services
check_internet
print_summary
write_log "INFO" "Dashboard run completed"
