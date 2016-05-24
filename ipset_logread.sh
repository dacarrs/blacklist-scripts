#!/bin/sh

# /usr/local/sbin/block

# Notes: Call this from crontab. Feed updated every 15 minutes.
# Dump logread every 15m and add IPs to the IPSet.

ipset_name="logread-blacklist"
target="/tmp/log_full_ipset.txt"
ipset_params="hash:ip"
blocklist_chain_name=blocklists

# iptables logging limit
LIMIT="10/minute"

logread > /tmp/logger.txt
cat /tmp/logger.txt | grep SRC= | awk '{print $14}' | sort | uniq | sed 's/^SRC=//' >> /tmp/log_blacklist_full.txt

sort /tmp/log_blacklist_full.txt | uniq -u > /tmp/log_full_ipset.txt

# Create list if not exists
ipset create -exist ${ipset_name} ${ipset_params}

for i in $( cat ${target} ) ; do ipset add ${ipset_name} $i ; done