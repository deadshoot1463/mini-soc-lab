# Réseau Docker

## 1. Segmentation réseau

Afin d'isoler les différents composants de l'infrastructure, trois réseaux Docker dédiés sont créés :

- **`exploit_lan`** : réseau dédié à la partie exploitation / attaque.
    
- **`worker_lan`** : réseau dédié aux composants de travail.
    
- **`elk_lan`** : réseau dédié à la stack de supervision et de centralisation des logs ELK.
    

### 1.1 Création des réseaux

Dans un premier temps, les trois réseaux Docker sont créés avec le driver `bridge` :

```bash
docker network create exploit_lan
docker network create elk_lan
docker network create worker_lan
```

La commande suivante permet de vérifier leur création :

```bash
docker network ls
```

Exemple de sortie :

```text
NETWORK ID     NAME          DRIVER    SCOPE
345b68c710ee   bridge        bridge    local
332dbe2a656b   elk_lan       bridge    local
e36d8faa7066   exploit_lan   bridge    local
e1159a400d4a   host          host      local
40051a102462   none          null      local
c2395fec08b4   worker_lan    bridge    local
```

---

## 2. Configuration des sous-réseaux

Afin de maîtriser l'adressage IP et de garantir une séparation claire entre les différents environnements, les réseaux sont configurés avec des sous-réseaux personnalisés.

### 2.1 Suppression des réseaux précédents

Si les réseaux ont déjà été créés précédemment, ils peuvent être supprimés avec :

```bash
docker network rm exploit_lan worker_lan elk_lan
```

### 2.2 Création des réseaux avec des sous-réseaux personnalisés

Les trois réseaux sont ensuite recréés avec leur propre plage d'adresses IP :

```bash
docker network create \
  --driver bridge \
  --subnet 192.30.10.0/24 \
  exploit_lan

docker network create \
  --driver bridge \
  --subnet 10.30.10.0/24 \
  worker_lan

docker network create \
  --driver bridge \
  --subnet 172.30.10.0/24 \
  elk_lan
```

L'utilisation de sous-réseaux distincts permet d'isoler les flux réseau entre les différentes zones de l'infrastructure.

### 2.3 Plan d'adressage

|Réseau|Sous-réseau|Passerelle|
|---|---|---|
|`exploit_lan`|`192.30.10.0/24`|`192.30.10.1`|
|`worker_lan`|`10.30.10.0/24`|`10.30.10.1`|
|`elk_lan`|`172.30.10.0/24`|`172.30.10.1`|

> **Remarque :** les adresses de passerelle sont attribuées automatiquement par Docker lors de la création du réseau avec le paramètre `--subnet`, sauf configuration spécifique.

---

## 3. Vérification des réseaux

Pour vérifier la configuration et identifier les conteneurs connectés à chaque réseau, la commande `docker network inspect` peut être utilisée :

```bash
docker network inspect exploit_lan
docker network inspect worker_lan
docker network inspect elk_lan
```

Ces commandes permettent notamment de vérifier :

- le sous-réseau utilisé ;
    
- l'adresse de la passerelle ;
    
- les conteneurs connectés ;
    
- les adresses IP attribuées aux conteneurs ;
    
- la configuration du réseau Docker.
    

---

# Architecture Docker Compose

L'infrastructure est organisée autour de plusieurs fichiers **Docker Compose**, chacun permettant de déployer un composant spécifique de la plateforme.

L'organisation permet de séparer les différentes briques de l'infrastructure tout en conservant une gestion centralisée depuis le projet racine.

---
# Docker Compose racine

Le fichier `docker-compose.yml` constitue le **point d’entrée principal de la stack mini-SOC**.

Il permet d'assembler les différents fichiers Docker Compose du projet grâce à la directive `include`. Chaque composant de l'infrastructure possède ainsi son propre fichier de configuration, tandis que le fichier racine permet de piloter l'ensemble de la stack depuis un point centralisé.
## Organisation

Le fichier racine regroupe les différents composants dans un ordre logique de déploiement :

```
docker-compose.yml
│
├── docker-compose.setup-certs.yml
├── docker-compose.setup-passwords.yml
├── docker-compose.elasticsearch.yml
├── docker-compose.kibana.yml
├── docker-compose.filebeat.yml
└── docker-compose.suricata.yml
```

Cette organisation permet de séparer les responsabilités de chaque service tout en conservant une configuration globale de la stack.

### Rôle du fichier `docker-compose.yml`

Le fichier `docker-compose.yml` permet notamment de :

- centraliser le déploiement de la stack ;
- inclure les différents fichiers Compose du projet ;
- organiser les composants selon leur ordre logique de démarrage ;
- simplifier l'administration de l'ensemble de l'infrastructure.

c'est le  **point d'entrée unique** pour gérer la stack mini-SOC.
# Elasticsearch

**Elasticsearch** constitue le moteur de stockage, d'indexation et de recherche des événements et des logs collectés.

Il permet notamment de :

- centraliser les événements ;
    
- indexer les logs ;
    
- effectuer des recherches ;
    
- mettre les données à disposition de Kibana pour leur visualisation.
    

## Déploiement Elasticsearch

Les fichiers Compose associés sont :

```text
docker-compose.elasticsearch.yml
docker-compose.setup-certs.yml
```

Le fichier `docker-compose.elasticsearch.yml` permet de déployer le service Elasticsearch.

Le fichier `docker-compose.setup-certs.yml` est utilisé pour la configuration des certificats nécessaires à la sécurisation des communications.

---

# Kibana
![[Pasted image 20261001143212.png]]
**Kibana** fournit l'interface web permettant d'explorer, rechercher et visualiser les données stockées dans Elasticsearch.

Il permet notamment de construire des tableaux de bord et de faciliter l'analyse des événements de sécurité.

## Déploiement Kibana

Les fichiers Compose associés sont :

```text
docker-compose.kibana.yml
docker-compose.setup-passwords.yml
```

Le fichier `docker-compose.kibana.yml` permet de déployer Kibana.

Le fichier `docker-compose.setup-passwords.yml` est utilisé pour la configuration initiale des mots de passe et des accès aux différents services.

---

# Filebeat

**Filebeat** est un agent léger de collecte de logs. Il récupère les événements générés par les différents composants de l'infrastructure et les transmet vers Elasticsearch.

Il constitue donc une brique intermédiaire entre les sources de logs et la plateforme ELK.

## Déploiement Filebeat

Le fichier Compose associé est :

```text
docker-compose.filebeat.yml
```

Le déploiement de Filebeat permet de collecter et d'acheminer les logs vers Elasticsearch afin qu'ils puissent ensuite être analysés et visualisés dans Kibana.

---

# Suricata

**Suricata** est utilisé comme moteur de détection et de surveillance réseau.

Il analyse le trafic réseau afin de détecter des événements correspondant aux règles de sécurité configurées et génère des logs exploitables par la plateforme de supervision.

## Déploiement Suricata

Le fichier Compose associé est :

```text
docker-compose.suricata.yml
```

Les événements générés par Suricata peuvent ensuite être collectés par Filebeat et transmis à Elasticsearch pour leur analyse et leur visualisation dans Kibana.

---

# Vue d'ensemble de l'architecture

L'architecture repose donc sur plusieurs briques complémentaires :

```text
                         ┌──────────────────┐
                         │    Trafic réseau │
                         └────────┬─────────┘
                                  │
                                  ▼
                         ┌──────────────────┐
                         │     Suricata     │
                         │ Détection réseau │
                         └────────┬─────────┘
                                  │
                                  │ Logs
                                  ▼
                         ┌──────────────────┐
                         │     Filebeat     │
                         │ Collecte des logs│
                         └────────┬─────────┘
                                  │
                                  ▼
                         ┌──────────────────┐
                         │   Elasticsearch  │
                         │ Stockage / Index │
                         └────────┬─────────┘
                                  │
                                  ▼
                         ┌──────────────────┐
                         │      Kibana      │
                         │ Visualisation    │
                         └──────────────────┘
```

Les différents composants sont répartis sur des réseaux Docker dédiés afin de limiter les communications aux flux nécessaires au fonctionnement de l'infrastructure.

## Synthèse

|Composant|Fonction|Fichier Compose|
|---|---|---|
|**Suricata**|Détection et analyse du trafic réseau|`docker-compose.suricata.yml`|
|**Filebeat**|Collecte et transmission des logs|`docker-compose.filebeat.yml`|
|**Elasticsearch**|Stockage, indexation et recherche|`docker-compose.elasticsearch.yml`|
|**Kibana**|Visualisation et analyse des événements|`docker-compose.kibana.yml`|
|**Certificats**|Sécurisation des communications|`docker-compose.setup-certs.yml`|
|**Mots de passe**|Initialisation des accès|`docker-compose.setup-passwords.yml`|