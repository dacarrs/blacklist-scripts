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

link_set () {
    if [ "$3" = "log" ]; then
        iptables -A "$1" -m set --match-set "$2" src,dst -m limit --limit "$LIMIT" -j LOG --log-prefix "BLOCK $2 "
    fi
    iptables -A "$1" -m set --match-set "$2" src -j DROP
    iptables -A "$1" -m set --match-set "$2" dst -j DROP
}

logread > /tmp/logger.txt
cat logger.txt | grep SRC= | awk '{print $14}' | sort | uniq | sed 's/^SRC=//' >> /tmp/log_blacklist_full.txt

sort /tmp/log_blacklist_full.txt | uniq -u > /tmp/log_full_ipset.txt

# Create iptables
set_name="logread-blacklist"
if ! ipset list | grep -q "Name: ${set_name}"; then
    ipset create "${set_name}" hash:ip
fi
link_set "${blocklist_chain_name}" "${set_name}" "$1"

# Create list if not exists
ipset create -exist ${ipset_name} ${ipset_params}

for i in $( cat ${target} ) ; do ipset add ${ipset_name} $i ; done