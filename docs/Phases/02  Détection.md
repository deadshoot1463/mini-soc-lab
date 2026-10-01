# Détection des comportements suspects

Une partie importante du projet consiste à **identifier et analyser les comportements suspects

Plusieurs types de signaux peuvent être exploités afin de détecter des activités potentiellement malveillantes :

- les scans de ports ;
    
- les connexions multiples provenant d'une même adresse IP ;
    
- les signatures et alertes générées par **Suricata** ;
    
- les tentatives d'exploitation ;
    
- les comportements réseau inhabituels ou anormaux.
    

L'objectif est de centraliser ces événements afin de pouvoir les **visualiser, les analyser et mettre en place des règles de détection**.

### Comment fonctionne la détection ?

Le processus repose principalement sur **Suricata**, **Filebeat**, **Elasticsearch** et **Kibana**.

Le flux de données peut être résumé ainsi :

```text
Trafic réseau
     │
     ▼
  Suricata
     │
     │  Événements / alertes
     ▼
  Filebeat
     │
     │  Ingestion
     ▼
 Elasticsearch
     │
     ▼
  Kibana
     │
     ├── Dashboards
     └── Règles de détection
```

### Suricata

**Suricata** est chargé d'analyser le trafic réseau et de détecter les activités correspondant aux règles de détection configurées.

Des règles spécifiques sont mises en place afin d'identifier différentes catégories de comportements suspects, telles que :

- les scans de ports ;
    
- les tentatives d'exploitation ;
    
- certaines signatures d'attaques connues ;
    
- les connexions ou communications inhabituelles.
    

Les règles ainsi que la configuration de Suricata sont disponibles dans :

```text
../Docker/suricata/rules
```

Les événements et alertes générés par Suricata constituent ensuite la source de données utilisée par la chaîne de collecte et d'analyse.

### Filebeat

**Filebeat** est utilisé pour récupérer les événements générés par Suricata et les transmettre à **Elasticsearch**.

Son rôle est notamment de :

1. récupérer les événements produits par Suricata ;
    
2. collecter et structurer les données nécessaires ;
    
3. transmettre les événements à Elasticsearch ;
    
4. permettre leur exploitation dans Kibana.
    

Les données stockées dans Elasticsearch peuvent ensuite être consultées et analysées dans **Kibana**, notamment à travers des **dashboards** permettant de visualiser les activités détectées.

Des **règles de détection** peuvent également être configurées afin d'identifier automatiquement certains comportements et de générer des alertes.

La configuration de Filebeat se trouve dans :

```text
../Docker/filebeat/filebeat.yml
```

### Chaîne de détection

Ainsi, lorsqu'un comportement suspect est généré dans le laboratoire, le processus est le suivant :

```text
Comportement suspect
        │
        ▼
Analyse du trafic par Suricata
        │
        ▼
Génération d'un événement / d'une alerte
        │
        ▼
Collecte par Filebeat
        │
        ▼
Envoi vers Elasticsearch
        │
        ▼
Visualisation et analyse dans Kibana
        │
        ▼
Détection et génération d'alertes
```

Cette architecture permet donc de **centraliser les événements de sécurité**, de suivre les activités observées dans le laboratoire et de construire progressivement un système de détection basé sur les données réseau.