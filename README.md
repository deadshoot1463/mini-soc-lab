# Mini-SOC Lab

## Objectif

L'objectif de ce projet est de construire un environnement SOC miniature permettant de suivre un incident de bout en bout :

**Attaque → Détection → Alerte → Enrichissement → Orchestration → Remédiation → Rapport d'incident**

Le laboratoire repose sur une séparation entre :

- une zone offensive permettant de générer du trafic malveillant ;
- une zone défensive chargée de détecter et analyser ce trafic ;
- une couche d'orchestration permettant d'automatiser certaines actions de réponse.

##  Flux de détection

	Trafic d'attaque ==> suricata ==> eve.json==> Filebeat==>Elasticsearch==>kibana       │
       │
      alerte
       │
       ▼
      n8n
      │
      ├──► Enrichissement CTI
      │
      ├──► Action de réponse
      │
      └──► Rapport d'incident

## Technologies

- Docker / Docker Compose	Conteneurisation et orchestration
- Kali	Génération du trafic d'attaque
- Metasploitable 2	Cible volontairement vulnérable
- Suricata	NIDS/NIPS et génération des événements
- Filebeat	Collecte et transmission des logs
- Elasticsearch	Stockage et indexation
- Kibana	SIEM, visualisation et alertes
- n8n	Orchestration SOAR
- MISP / OpenCTI	Threat Intelligence
##  Structure du dépôt

##  Installation

### Prérequis
- Linux recommandé
- Docker
- Docker Compose
- Git
au moins 8 Go de RAM disponibles

Une configuration disposant de davantage de mémoire est recommandée pour faire fonctionner confortablement l'ensemble de la stack.

## Détection

Une partie importante du projet consiste à identifier les comportements suspects générés dans le laboratoire.

Exemples de signaux pouvant être exploités :

- scans de ports ;
- multiples connexions provenant d'une même adresse IP ;
- signatures Suricata ;
- tentatives d'exploitation ;
- comportements réseau anormaux.

L'objectif est de transformer les événements réseau bruts en alertes exploitables par l'analyste SOC.

## SOAR & réponse à incident

Lorsqu'une alerte est générée, n8n doit permettre d'orchestrer différentes étapes :

1. réception de l'alerte ;
2. récupération des informations associées ;
3. enrichissement des indicateurs ;
4. interrogation de la CTI ;
5. décision sur l'action à effectuer ;
6. exécution d'une action défensive ;
7. génération d'un rapport d'incident.

Les indicateurs peuvent notamment inclure :

- adresses IP ;
- domaines ;
- hashes ;
- signatures ;
- autres indicateurs de compromission (IoC).
## Remédiation

La remédiation reste exclusivement défensive et s'effectue sur l'environnement du laboratoire.

Les actions envisagées comprennent notamment :

- blocage temporaire d'une adresse IP ;
- isolation d'une cible ;
- révocation de sessions ;
- nettoyage d'une persistance ;
- restauration de la machine.

Les actions potentiellement destructives doivent rester soumises à une validation humaine. Le support recommande une automatisation graduée avec un mécanisme de garde-fou contre les faux positifs.

## Scénarios de test

## Rapport d'incident

Le résultat final du workflow est un rapport d'incident structuré.

Le rapport suit les principales phases de la réponse à incident :

1. Préparation
2. Identification
3. Confinement
4. Remédiation
5. Récupération
6. Capitalisation / RETEX

Le SOAR peut générer un premier rapport pré-rempli à partir des informations collectées. L'analyste complète ensuite la chronologie, l'analyse et le retour d'expérience

##  Sécurité
Ce projet est destiné à un environnement de laboratoire contrôlé.
La cible Metasploitable est volontairement vulnérable et doit rester isolée du réseau Internet.

Ne jamais :

- exposer la cible vulnérable sur Internet ;
- commiter de secrets ;
- commiter des clés API ;
- commiter des mots de passe ;
- utiliser les scénarios offensifs contre des systèmes tiers sans autorisation.

La réponse automatisée doit rester défensive et limitée aux systèmes du laboratoire.
##  Documentation

La documentation détaillée du projet est disponible dans `docs/`.
Elle couvre notamment :

- l'architecture ;
- le déploiement ;
- la détection ;
- les workflows SOAR ;
- la réponse à incident ;
- les scénarios de test.
##  Roadmap
## Roadmap

### Phase 0 — Repository

- [x]  Création du dépôt Git
- [x]  README
- [x]  `.gitignore`
- [ ]  `.env.example`
- [ ]  Documentation de l'architecture

### Phase 1 — Infrastructure

- [x]  Réseaux Docker
- [x]  Elasticsearch
- [x]  Kibana
- [x]  Validation de la stack ELK

### Phase 2 — Détection

- [ ]  Suricata
- [ ]  Filebeat
- [ ]  Ingestion des événements
- [ ]  Dashboards Kibana
- [ ]  Règles de détection

### Phase 3 — SOAR

- [ ]  Déploiement n8n
- [ ]  Réception des alertes
- [ ]  Workflow d'enrichissement
- [ ]  Connexion CTI

### Phase 4 — Réponse

- [ ]  Playbook de remédiation
- [ ]  Blocage / isolation
- [ ]  Garde-fous contre les faux positifs
- [ ]  Génération du rapport

### Phase 5 — Documentation

- [ ]  Scénarios d'attaque
- [ ]  Captures d'écran
- [ ]  Rapports d'incident
- [ ]  Documentation finale
- [ ]  Démonstration complète
##  Auteur
Projet personnel de cybersécurité réalisé dans le cadre d'un parcours ESGI 5 par
Abdoul Hamani Bachir Seydou 
