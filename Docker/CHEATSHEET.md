# SOC-RUN — Cheatsheet lab

> Répertoire de travail : `Docker/`  
> Projet Compose : `mini-soc-run`

| Rôle | Hostname | IP / accès |
|------|----------|------------|
| Elasticsearch | `ELASTICS` | https://localhost:9200 |
| Kibana | `KIBANA` | https://localhost:5601 |
| n8n | `n8n` | http://localhost:5678 |
| Suricata | `SURICATA` | (pas d’UI) |
| Kali | `kali` | `192.30.10.14` |
| Victime | `victime` | `10.30.10.20` · http://localhost:8080 |

Réseaux : `exploit_lan` `192.30.10.0/24` · `worker_lan` `10.30.10.0/24` · `elk_lan` `172.30.10.0/24`

Identifiants : voir `.env` (ne pas committer).

---

## 1. Stack Docker (démarrage / arrêt)

```powershell
# Se placer dans le dossier Docker
cd ".\Docker"

# Créer les réseaux (une fois)
docker network create --subnet=192.30.10.0/24 exploit_lan
docker network create --subnet=10.30.10.0/24 worker_lan
docker network create --subnet=172.30.10.0/24 elk_lan

# Lancer toute la stack
docker compose up -d --build

# Lancer uniquement ELK / détection
docker compose up -d elasticsearch kibana filebeat suricata n8n

# Lancer uniquement le lab offensif
docker compose up -d --build kali victime

# Statut
docker compose ps
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Logs
docker compose logs -f
docker compose logs -f suricata
docker compose logs -f filebeat
docker compose logs -f ELASTICS
docker logs -f victime
docker logs -f kali

# Stop / restart
docker compose stop
docker compose start
docker compose restart suricata
docker compose down          # stop + remove containers (garde volumes/bind)
```

---

## 2. Accès aux interfaces (hôte)

```powershell
# Elasticsearch (HTTPS + auth)
curl.exe -sk -u "elastic:<ELASTICSEARCH_PASSWORD>" https://localhost:9200
curl.exe -sk -u "elastic:<ELASTICSEARCH_PASSWORD>" "https://localhost:9200/_cat/indices?v"

# Kibana
# Navigateur : https://localhost:5601  (accepter le cert auto-signé)
# Login UI : elastic / <ELASTICSEARCH_PASSWORD>

# n8n
# Navigateur : http://localhost:5678

# Victime (site + DVWA)
# Navigateur : http://localhost:8080
# DVWA       : http://localhost:8080/dvwa   (admin / password)
```

---

## 3. Shells conteneurs

```powershell
docker exec -it kali bash
docker exec -it victime bash
docker exec -it ELASTICS bash
docker exec -it KIBANA bash
docker exec -it suricata bash
docker exec -it filebeat bash
docker exec -it n8n sh
```

Depuis Kali, aide aux tests :

```bash
siem-tests.sh
```

---

## 4. Réseau / topologie

```powershell
docker network ls
docker network inspect exploit_lan
docker network inspect worker_lan
docker network inspect elk_lan

# Qui est sur quel réseau
docker network inspect worker_lan -f "{{range .Containers}}{{.Name}} {{.IPv4Address}}{{\"\\n\"}}{{end}}"
```

```bash
# Depuis Kali
ping -c 3 10.30.10.20
ip a
ip route
```

---

## 5. Suricata (IDS)

```powershell
# Logs Suricata
Get-Content .\ELK-CONFIG\suricata\logs\eve.json -Tail 20
Get-Content .\ELK-CONFIG\suricata\logs\fast.log -Tail 20
docker logs suricata --tail 50

# Tester le chargement des règles custom
docker exec suricata suricata -T -c /etc/suricata/suricata.yaml -S /var/lib/suricata/rules/local.rules --set default-log-dir=/tmp

# Recharger après édition de local.rules
docker compose restart suricata
```

Fichiers utiles :
- Règles custom : `ELK-CONFIG/suricata/rules/local.rules`
- Config : `ELK-CONFIG/suricata/config/suricata.yaml`
- EVE JSON : `ELK-CONFIG/suricata/logs/eve.json`

---

## 6. Filebeat / Elasticsearch

```powershell
# Filebeat vivant ?
docker logs filebeat --tail 30

# Indices / data streams
curl.exe -sk -u "elastic:<PASS>" "https://localhost:9200/_cat/indices/filebeat*?v"
curl.exe -sk -u "elastic:<PASS>" "https://localhost:9200/_data_stream/filebeat*?pretty"

# Chercher des alertes Suricata (ECS module)
curl.exe -sk -u "elastic:<PASS>" "https://localhost:9200/filebeat-*/_search?q=event.kind:alert&size=5"
```

Dans Kibana :
1. **Discover** → data view `filebeat-*`
2. KQL : `event.kind: alert and tags: suricata`
3. Colonnes utiles : `rule.name`, `source.ip`, `destination.ip`, `url.original`, `user_agent.original`, `dns.question.name`, `suricata.eve.payload_printable`, `observer.name`


---

## 7. Purge Kibana / repartir à zéro

Supprime les docs indexés + les logs Suricata locaux, puis recrée Filebeat (registry vide).

```powershell
# Depuis Docker/
$pass = (Select-String -Path .env -Pattern '^ELASTICSEARCH_PASSWORD=(.*)$').Matches.Groups[1].Value

# 1) Stopper Filebeat
docker compose stop filebeat

# 2) Supprimer le data stream (= tous les events dans Kibana)
docker exec -e PASS=$pass ELASTICS sh -c 'curl -sk -u "elastic:$PASS" -X DELETE "https://localhost:9200/_data_stream/filebeat-8.17.0?pretty"'

# 3) Vider les logs Suricata sur l'hôte
Remove-Item -Force .\ELK-CONFIG\suricata\logs\eve.json,.\ELK-CONFIG\suricata\logs\fast.log,.\ELK-CONFIG\suricata\logs\stats.log -ErrorAction SilentlyContinue
New-Item -ItemType File -Path .\ELK-CONFIG\suricata\logs\eve.json -Force | Out-Null
New-Item -ItemType File -Path .\ELK-CONFIG\suricata\logs\fast.log -Force | Out-Null

# 4) Recréer Filebeat + redémarrer Suricata
docker compose up -d --force-recreate filebeat
docker compose restart suricata
```

Vérifier : Discover → 0 doc (rafraîchir / élargir la plage de temps). Les prochains events Suricata recréent l’index automatiquement.

---

## 8. Attacker (Kali) — recon

```bash
# Shell
docker exec -it kali bash

VICTIME=10.30.10.20

ping -c 3 $VICTIME
nmap -sS -sV -T4 $VICTIME
nmap -p 21,22,53,80 $VICTIME
```

---

## 9. Attacker — HTTP / web

```bash
VICTIME=10.30.10.20

# Enum répertoires
gobuster dir -u http://$VICTIME -w /usr/share/wordlists/dirb/common.txt
gobuster dir -u http://$VICTIME/dvwa -w /usr/share/wordlists/dirb/common.txt

# Scan web
nikto -h http://$VICTIME

# Chemins sensibles
curl -s http://$VICTIME/admin/
curl -s http://$VICTIME/backup/
curl -s http://$VICTIME/secret/config.txt
curl -s http://$VICTIME/.git/HEAD
curl -s http://$VICTIME/dvwa/
```

DVWA (navigateur hôte) : http://localhost:8080/dvwa — `admin` / `password`

---

## 10. Attacker — SSH

```bash
VICTIME=10.30.10.20

# Brute force rapide (credentials lab)
hydra -l root -p root ssh://$VICTIME

# Avec wordlist
hydra -l root -P /usr/share/wordlists/rockyou.txt ssh://$VICTIME -t 4 -V

# Connexion directe
ssh root@$VICTIME   # password: root
```

Depuis l’hôte :

```powershell
ssh root@localhost -p 2222
```

---

## 11. Attacker — DNS

```bash
VICTIME=10.30.10.20

dig @$VICTIME www.victime.local +short
dig @$VICTIME ns.victime.local +short
dnsrecon -d victime.local -n $VICTIME

# Flood (génère du volume / alertes)
dns-flood.sh $VICTIME 500
```

Depuis l’hôte (port publié `53535`) :

```powershell
dig @127.0.0.1 -p 53535 www.victime.local
```

---

## 12. Attacker — FTP

```bash
VICTIME=10.30.10.20

ftp $VICTIME
# login: anonymous
# password: (vide)

lftp -u anonymous, $VICTIME -e 'ls; ls pub; get pub/flag.txt; bye'
```

Depuis l’hôte :

```powershell
ftp localhost 2121
```

---

## 13. Certificats / setup ELK

```powershell
# Régénérer les certs (supprimer le dossier d'abord)
Remove-Item -Recurse -Force .\ELK-CONFIG\certs\*
docker compose up setup-certs

# Logs setup
docker logs setup-certs
docker logs setup-passwords
```

---

## 14. Debug utile

```powershell
# Conteneur qui restart en boucle
docker ps -a
docker logs <nom> --tail 100

# Ports en conflit (Windows)
netstat -ano | findstr ":8080"
netstat -ano | findstr ":5353"
netstat -ano | findstr ":9200"

# Valider le compose
docker compose config

# Rebuild ciblé
docker compose build kali --no-cache
docker compose build victime --no-cache
docker compose up -d --force-recreate victime
```

---

## 15. Scénario de démo (ordre conseillé)

```powershell
# 1) Stack up
docker compose up -d --build

# 2) Vérifier Kibana + ES
# https://localhost:5601  /  https://localhost:9200

# 3) Attaques depuis Kali
docker exec -it kali bash
siem-tests.sh
# puis lancer nmap / gobuster / hydra / dns-flood / ftp

# 4) Vérifier les alertes
# Kibana Discover → event.kind: alert and tags: suricata
# ou : Get-Content .\ELK-CONFIG\suricata\logs\fast.log -Tail 30
```

---

## Rappel ports hôte

| Service | URL / port |
|---------|------------|
| Elasticsearch | `https://localhost:9200` |
| Kibana | `https://localhost:5601` |
| n8n | `http://localhost:5678` |
| Victime HTTP | `http://localhost:8080` |
| Victime SSH | `localhost:2222` |
| Victime FTP | `localhost:2121` |
| Victime DNS | `localhost:53535` |
