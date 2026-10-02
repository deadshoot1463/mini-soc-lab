# SOC-RUN — Cheatsheet Lab

> **Répertoire de travail :** `Docker/`
> **Projet Docker Compose :** `mini-soc-run`

---

## 0. Vue d’ensemble

### Architecture

| Rôle          | Hostname                | Accès                                 |
| ------------- | ----------------------- | ------------------------------------- |
| Elasticsearch | `ELASTICS`              | https://localhost:9200                |
| Kibana        | `KIBANA`                | https://localhost:5601                |
| n8n           | `n8n`                   | http://localhost:5678                 |
| Suricata      | `SURICATA` / `suricata` | Pas d'UI                              |
| Filebeat      | `filebeat`              | Pas d'UI                              |
| Kali          | `kali`                  | `192.30.10.14`                        |
| Victime       | `victime`               | `10.30.10.20` / http://localhost:8080 |

### Réseaux Docker

| Réseau        | Subnet           | Usage                      |
| ------------- | ---------------- | -------------------------- |
| `exploit_lan` | `192.30.10.0/24` | Kali / trafic offensif     |
| `worker_lan`  | `10.30.10.0/24`  | Kali ↔ Victime             |
| `elk_lan`     | `172.30.10.0/24` | ELK / collecte / détection |

### Identifiants

Les identifiants sont stockés dans :

```text
.env
```

---

# 1. Démarrage de la stack

## 1.1 Se placer dans le projet

```powershell
cd ".\Docker"
```

## 1.2 Créer les réseaux — première installation uniquement

```powershell
docker network create --subnet=192.30.10.0/24 exploit_lan
docker network create --subnet=10.30.10.0/24 worker_lan
docker network create --subnet=172.30.10.0/24 elk_lan
```

Si les réseaux existent déjà, Docker retournera une erreur : ce n'est pas bloquant.

## 1.3 Démarrer toute la stack

```powershell
docker compose up -d --build
```

## 1.4 Démarrer uniquement ELK / détection

```powershell
docker compose up -d elasticsearch kibana filebeat suricata n8n
```

## 1.5 Démarrer uniquement le lab offensif

```powershell
docker compose up -d --build kali victime
```

---

# 2. Vérifier l'état de la stack

```powershell
docker compose ps
```

Vue globale :

```powershell
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

Logs de toute la stack :

```powershell
docker compose logs -f
```

Logs ciblés :

```powershell
docker compose logs -f suricata
docker compose logs -f filebeat
docker compose logs -f elasticsearch
docker compose logs -f kibana
docker compose logs -f n8n

docker logs -f victime
docker logs -f kali
```

---

# 3. Arrêter / redémarrer

Arrêter les conteneurs :

```powershell
docker compose stop
```

Redémarrer :

```powershell
docker compose start
```

Redémarrer un service :

```powershell
docker compose restart suricata
```

Arrêter et supprimer les conteneurs :

```powershell
docker compose down
```

> `docker compose down` supprime les conteneurs et les réseaux créés par Compose, mais conserve les volumes sauf option spécifique.

---

# 4. Interfaces accessibles depuis l'hôte

## Elasticsearch

Tester l'API :

```powershell
curl.exe -sk -u "elastic:<ELASTICSEARCH_PASSWORD>" https://localhost:9200
```

Lister les index :

```powershell
curl.exe -sk -u "elastic:<ELASTICSEARCH_PASSWORD>" "https://localhost:9200/_cat/indices?v"
```

## Kibana

Navigateur :

```text
https://localhost:5601
```

> Accepter le certificat auto-signé si nécessaire.

Connexion :

```text
Utilisateur : elastic
Mot de passe : <ELASTICSEARCH_PASSWORD>
```

## n8n

```text
http://localhost:5678
```

## Victime

Site principal :

```text
http://localhost:8080
```

DVWA :

```text
http://localhost:8080/dvwa
```

Identifiants DVWA :

```text
admin / password
```

---

# 5. Accéder aux conteneurs

```powershell
docker exec -it kali bash
docker exec -it victime bash
docker exec -it ELASTICS bash
docker exec -it KIBANA bash
docker exec -it suricata bash
docker exec -it filebeat bash
docker exec -it n8n sh
```

Depuis Kali, les scripts de test sont disponibles directement :

```bash
siem-tests.sh
```

---

# 6. Réseau et topologie

Lister les réseaux :

```powershell
docker network ls
```

Inspecter un réseau :

```powershell
docker network inspect exploit_lan
docker network inspect worker_lan
docker network inspect elk_lan
```

Afficher les conteneurs et leurs IP :

```powershell
docker network inspect worker_lan -f "{{range .Containers}}{{.Name}} {{.IPv4Address}}{{\"\n\"}}{{end}}"
```

## Depuis Kali

```bash
ip a
ip route
```

Tester la victime :

```bash
ping -c 3 10.30.10.20
```

Variables pratiques :

```bash
export VICTIME=10.30.10.20
```

---

# 7. Suricata — IDS

## 7.1 Vérifier les logs

Depuis l'hôte :

```powershell
Get-Content .\ELK-CONFIG\suricata\logs\eve.json -Tail 20
Get-Content .\ELK-CONFIG\suricata\logs\fast.log -Tail 20
```

Ou directement depuis Docker :

```powershell
docker logs suricata --tail 50
```

Suivre les événements en temps réel :

```powershell
Get-Content .\ELK-CONFIG\suricata\logs\eve.json -Wait
```

## 7.2 Tester les règles

```powershell
docker exec suricata suricata -T `
  -c /etc/suricata/suricata.yaml `
  -S /var/lib/suricata/rules/local.rules `
  --set default-log-dir=/tmp
```

## 7.3 Recharger Suricata

Après modification de `local.rules` :

```powershell
docker compose restart suricata
```

## 7.4 Fichiers importants

```text
ELK-CONFIG/
├── suricata/
│   ├── config/
│   │   └── suricata.yaml
│   ├── rules/
│   │   └── local.rules
│   └── logs/
│       ├── eve.json
│       └── fast.log
```

---

# 8. Filebeat → Elasticsearch

## Vérifier Filebeat

```powershell
docker logs filebeat --tail 30
```

Suivre les logs :

```powershell
docker logs -f filebeat
```

## Vérifier Elasticsearch

```powershell
curl.exe -sk -u "elastic:<ELASTICSEARCH_PASSWORD>" `
  "https://localhost:9200/_cat/indices?v"
```

## Rechercher les alertes Suricata

```powershell
curl.exe -sk `
  -u "elastic:<ELASTICSEARCH_PASSWORD>" `
  "https://localhost:9200/filebeat-*/_search?q=alert.signature:SOC-RUN&size=5"
```

---

# 9. Kibana — vérification des alertes

Dans Kibana :

```text
Discover
   ↓
Data View : filebeat-*
   ↓
Filtrer les événements Suricata
```

Filtres utiles :

```text
alert.signature : SOC-RUN*
```

ou :

```text
event_type : alert
```

Pour une analyse rapide :

```text
@timestamp
event_type
alert.signature
alert.category
source.ip
source.port
destination.ip
destination.port
```

---
##  Purge Kibana / repartir à zéro

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
# 10. Kali — reconnaissance

Entrer dans Kali :

```powershell
docker exec -it kali bash
```

Définir la cible :

```bash
VICTIME=10.30.10.20
```

Tester la connectivité :

```bash
ping -c 3 $VICTIME
```

Scan général :

```bash
nmap -sS -sV -T4 $VICTIME
```

Scan de ports ciblés :

```bash
nmap -p 21,22,53,80 $VICTIME
```

---

# 11. Kali — HTTP / Web

## Enumération de répertoires

```bash
gobuster dir \
  -u http://$VICTIME \
  -w /usr/share/wordlists/dirb/common.txt
```

DVWA :

```bash
gobuster dir \
  -u http://$VICTIME/dvwa \
  -w /usr/share/wordlists/dirb/common.txt
```

## Scan web

```bash
nikto -h http://$VICTIME
```

## Tester quelques chemins

```bash
curl -s http://$VICTIME/admin/
curl -s http://$VICTIME/backup/
curl -s http://$VICTIME/secret/config.txt
curl -s http://$VICTIME/.git/HEAD
curl -s http://$VICTIME/dvwa/
```

## DVWA depuis l'hôte

```text
http://localhost:8080/dvwa
```

```text
admin / password
```

---

# 12. Kali — SSH

> À utiliser uniquement dans le lab.

Définir la cible :

```bash
VICTIME=10.30.10.20
```

Test avec identifiants de lab :

```bash
hydra -l root -p root ssh://$VICTIME
```

Avec une wordlist :

```bash
hydra \
  -l root \
  -P /usr/share/wordlists/rockyou.txt \
  ssh://$VICTIME \
  -t 4 \
  -V
```

Connexion directe :

```bash
ssh root@$VICTIME
```

Identifiant de lab :

```text
root / root
```

Depuis l'hôte :

```powershell
ssh root@localhost -p 2222
```

---

# 13. Kali — DNS

```bash
VICTIME=10.30.10.20
```

Résolution :

```bash
dig @$VICTIME www.victime.local +short
```

```bash
dig @$VICTIME ns.victime.local +short
```

Énumération :

```bash
dnsrecon -d victime.local -n $VICTIME
```

Générer du trafic DNS dans le lab :

```bash
dns-flood.sh $VICTIME 500
```

Depuis l'hôte :

```powershell
dig @127.0.0.1 -p 53535 www.victime.local
```

---

# 14. Kali — FTP

Connexion :

```bash
VICTIME=10.30.10.20

ftp $VICTIME
```

Identifiants :

```text
Utilisateur : anonymous
Mot de passe : vide
```

Avec `lftp` :

```bash
lftp -u anonymous, $VICTIME \
  -e 'ls; ls pub; get pub/flag.txt; bye'
```

Depuis l'hôte :

```powershell
ftp localhost 2121
```

---

# 15. Certificats ELK

> ⚠️ À utiliser principalement lors d'une réinitialisation du lab.

Supprimer les certificats :

```powershell
Remove-Item -Recurse -Force .\ELK-CONFIG\certs\*
```

Régénérer :

```powershell
docker compose up setup-certs
```

Vérifier :

```powershell
docker logs setup-certs
docker logs setup-passwords
```

---

# 16. Debug rapide

## Conteneur qui redémarre en boucle

```powershell
docker ps -a
```

Puis :

```powershell
docker logs <nom> --tail 100
```

Ou :

```powershell
docker compose logs <service> --tail 100
```

## Vérifier le Compose

```powershell
docker compose config
```

## Ports occupés sous Windows

```powershell
netstat -ano | findstr ":8080"
netstat -ano | findstr ":5353"
netstat -ano | findstr ":53535"
netstat -ano | findstr ":9200"
```

## Rebuild ciblé

Kali :

```powershell
docker compose build kali --no-cache
```

Victime :

```powershell
docker compose build victime --no-cache
```

Recréer la victime :

```powershell
docker compose up -d --force-recreate victime
```

---

# 17. Scénario de démo — déroulement conseillé

## Étape 1 — Démarrer la stack

```powershell
cd ".\Docker"

docker compose up -d --build
```

## Étape 2 — Vérifier les services

```powershell
docker compose ps
```

Tester :

```text
Kibana         → https://localhost:5601
Elasticsearch  → https://localhost:9200
n8n            → http://localhost:5678
Victime        → http://localhost:8080
DVWA           → http://localhost:8080/dvwa
```

## Étape 3 — Vérifier Suricata

```powershell
docker logs suricata --tail 50
```

Puis :

```powershell
Get-Content .\ELK-CONFIG\suricata\logs\eve.json -Tail 20
```

## Étape 4 — Lancer les tests depuis Kali

```powershell
docker exec -it kali bash
```

Puis :

```bash
siem-tests.sh
```

Tests complémentaires :

```bash
nmap -sS -sV -T4 $VICTIME
gobuster dir -u http://$VICTIME -w /usr/share/wordlists/dirb/common.txt
nikto -h http://$VICTIME
```

Puis, selon le scénario du lab :

```bash
hydra ...
dns-flood.sh ...
ftp ...
```

## Étape 5 — Observer la détection

### Suricata

```powershell
Get-Content .\ELK-CONFIG\suricata\logs\fast.log -Tail 30
```

### Elasticsearch

```powershell
curl.exe -sk `
  -u "elastic:<ELASTICSEARCH_PASSWORD>" `
  "https://localhost:9200/_cat/indices?v"
```

### Kibana

```text
Discover
  → filebeat-*
  → event_type : alert
  → alert.signature : SOC-RUN*
```

---

# 18. Référence rapide — ports hôte

| Service       | Port / URL               |
| ------------- | ------------------------ |
| Elasticsearch | `https://localhost:9200` |
| Kibana        | `https://localhost:5601` |
| n8n           | `http://localhost:5678`  |
| Victime HTTP  | `http://localhost:8080`  |
| Victime SSH   | `localhost:2222`         |
| Victime FTP   | `localhost:2121`         |
| Victime DNS   | `localhost:53535`        |

---

# 19. Commandes essentielles — mémo express

### Stack

```powershell
docker compose up -d --build
docker compose ps
docker compose logs -f
docker compose down
```

### Kali

```powershell
docker exec -it kali bash
```

```bash
VICTIME=10.30.10.20
```

### Réseau

```bash
ping -c 3 $VICTIME
ip a
ip route
```

### Recon

```bash
nmap -sS -sV -T4 $VICTIME
```

### Web

```bash
gobuster dir -u http://$VICTIME -w /usr/share/wordlists/dirb/common.txt
nikto -h http://$VICTIME
```

### Suricata

```powershell
docker logs suricata --tail 50
Get-Content .\ELK-CONFIG\suricata\logs\fast.log -Tail 30
```

### Filebeat

```powershell
docker logs filebeat --tail 30
```

### Elasticsearch

```powershell
curl.exe -sk -u "elastic:<ELASTICSEARCH_PASSWORD>" https://localhost:9200
```

### Kibana

```text
https://localhost:5601
```

### Victime

```text
http://localhost:8080
```

### DVWA

```text
http://localhost:8080/dvwa
```
