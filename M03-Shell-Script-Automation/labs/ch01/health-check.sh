#!/usr/bin/env bash
# health-check.sh รุ่นที่สอง: มีหัวรายงาน เวลา และสี
GREEN='\033[0;32m'
NC='\033[0m'

echo "=== Health Check: $(hostname) $(date '+%Y-%m-%d %H:%M') ==="
echo -e "${GREEN}[Load]${NC}  $(uptime | awk -F'average:' '{print $2}')"
echo -e "${GREEN}[RAM]${NC}   $(free -h | awk '/^Mem:/ {print $7 " available of " $2}')"
echo -e "${GREEN}[Disk]${NC}"
df -h -x tmpfs -x devtmpfs -x efivarfs
echo -e "${GREEN}[Failed services]${NC}"
systemctl --failed --no-legend
echo -e "${GREEN}[Listening TCP]${NC}"
ss -tln | awk 'NR > 1 {print "  " $4}'
