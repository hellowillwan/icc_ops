
mysql -e 'show full processlist;' \
| awk -F '\t' '$5 !~ /Sleep|Binlog Dump|Daemon/ {printf "%-18s %-6s %-20s %-6s %-10s %-6s %-20s %-64s\n",strftime("%y-%m-%d %T"),$1,$2,$4,$5,$6,$7,$8}'
