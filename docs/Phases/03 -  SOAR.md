
# n8n : 
Qu’est-ce que c’est ? 

n8n est une **plateforme open source d’automatisation de workflows** permettant de connecter différentes applications et services via une interface visuelle. Elle peut être **auto-hébergée**, intégrer des API et du code, et propose de nombreuses intégrations. Elle permet notamment d’**automatiser les tâches répétitives**, de centraliser des processus et d’intégrer des fonctionnalités d’**IA**. 

Qui s’en sert et pourquoi ?
principalement utilisé par des **entreprises, équipes IT, développeurs et équipes cybersécurité** pour automatiser des processus et connecter différents outils.

source : [n8n : Qu'est-ce que c'est ? Qui s'en sert et pourquoi ?](https://liora.io/n8n-tout-savoir)

installation : [Install using Docker Compose | Deploy | n8n Docs](https://docs.n8n.io/deploy/host-n8n/install-options/install-using-docker-compose)

![[Pasted image 20261001171129.png]]



Connecter n8n à Elasticsearch

Créer premier workflow

tester avec une attaque dans ton lab

recuperer :es index

```
curl.exe -k -u elastic:"8mUHwVJPy9s2apk558IH" https://localhost:9200/_cat/indices?v
```

```
curl.exe -k -u elastic:"TON_MDP" https://localhost:9200/_data_stream
```

resultat 

```
{"data_streams":[{"name":".items-default","timestamp_field":{"name":"@timestamp"},"indices":[{"index_name":".ds-.items-default-2026.10.01-000001","index_uuid":"Nu-F1GZSQ4C325mr67l0Hw","prefer_ilm":true,"managed_by":"Data stream lifecycle"}],"generation":1,"status":"YELLOW","template":".items-default","lifecycle":{"enabled":true},"next_generation_managed_by":"Data stream lifecycle","prefer_ilm":true,"hidden":false,"system":false,"allow_custom_routing":false,"replicated":false,"rollover_on_write":false},{"name":".lists-default","timestamp_field":{"name":"@timestamp"},"indices":[{"index_name":".ds-.lists-default-2026.10.01-000001","index_uuid":"fOxjndTTQuSy8jNr1KNoxg","prefer_ilm":true,"managed_by":"Data stream lifecycle"}],"generation":1,"status":"YELLOW","template":".lists-default","lifecycle":{"enabled":true},"next_generation_managed_by":"Data stream lifecycle","prefer_ilm":true,"hidden":false,"system":false,"allow_custom_routing":false,"replicated":false,"rollover_on_write":false},{"name":"filebeat-8.17.0","timestamp_field":{"name":"@timestamp"},"indices":[{"index_name":".ds-filebeat-8.17.0-2026.09.30-000001","index_uuid":"XKnmZMwlQoGSOIzCv5pzrA","prefer_ilm":true,"ilm_policy":"filebeat","managed_by":"Index Lifecycle Management"}],"generation":1,"status":"YELLOW","template":"filebeat-8.17.0","ilm_policy":"filebeat","next_generation_managed_by":"Index Lifecycle Management","prefer_ilm":true,"hidden":false,"system":false,"allow_custom_routing":false,"replicated":false,"rollover_on_write":false}]}
```

ce qu'on veux  `data_streams`
```
filebeat-8.17.0
```