

# Réseau Docker 
## Segmentation 
Création de la segmentation réseau Docker
Afin de segmenter le réseau, nous créons trois sous-réseaux distincts :

```
docker network create exploit_lan
docker network create elk_lan
docker network create worker_lan
```

Puis :

```
docker network ls
```

sortie : 
```
NETWORK ID     NAME          DRIVER    SCOPE
345b68c710ee   bridge        bridge    local
332dbe2a656b   elk_lan       bridge    local
e36d8faa7066   exploit_lan   bridge    local
e1159a400d4a   host          host      local
40051a102462   none          null      local
c2395fec08b4   worker_lan    bridge    local
```


  Pour créer les réseaux avec des adresses personnalisées.
  Vérifier conteneurs y sont attachés
```
docker network inspect exploit_lan
docker network inspect worker_lan
docker network inspect elk_lan
```
  ### Supprimer les trois réseaux

```
docker network rm exploit_lan worker_lan elk_lan
```


Créer les réseaux :
```
docker network create --driver bridge --subnet 192.30.10.0/24 exploit_lan
docker network create --driver bridge --subnet 10.30.10.0/24 worker_lan
docker network create --driver bridge --subnet 172.30.10.0/24 elk_lan
```

Nous aurons à présent : 
- Exploit_lan
```
"Subnet": "192.30.10.0/24"
"Gateway": "192.30.10.1"
```
- worker_lan
```
"Subnet": "10.30.10.0/24"
"Gateway": "10.30.10.1""
```
- elk_lan
```
"Subnet": "172.30.10.0/24
"Gateway": "172.30.10.1"
```


  # Docker compose racine

  
  # Elasticsearch

## Déploiement Elasticsearch

- [ ]  Kibana
- [ ]  Validation de la stack ELK