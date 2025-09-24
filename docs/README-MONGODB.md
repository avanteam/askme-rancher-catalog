# 🍃 AskMe MongoDB Integration Guide

Ce guide explique comment utiliser MongoDB avec le catalog Rancher AskMe au lieu d'Azure CosmosDB.

## 🎯 Vue d'ensemble

Le catalog AskMe supporte maintenant MongoDB comme alternative à Azure CosmosDB pour stocker l'historique des conversations. Cette solution offre :

- ✅ **Indépendance Cloud** : Infrastructure sous votre contrôle
- ✅ **Coût réduit** : Pas de frais CosmosDB
- ✅ **Performance** : MongoDB Replica Set avec répartition de charge
- ✅ **Multi-tenant** : Une instance MongoDB, bases séparées par client

## 🏗️ Architecture

```
┌─────────────────────────────────────────┐
│          KUBERNETES CLUSTER             │
│                                         │
│  Namespace: askme-platform              │
│  ┌─────────────┐    ┌─────────────┐    │
│  │ AskMe       │────│             │    │
│  │ Client 1    │    │             │    │
│  └─────────────┘    │   MongoDB   │    │
│                      │ Replica Set │    │
│  ┌─────────────┐    │             │    │
│  │ AskMe       │────│  - Primary  │    │
│  │ Client 2    │    │  - Secondary│    │
│  └─────────────┘    │  - Secondary│    │
│                      └─────────────┘    │
│  Namespace: askme-mongodb               │
└─────────────────────────────────────────┘
```

## 📋 Prérequis

1. **MongoDB déployé** : Instance MongoDB avec Replica Set
2. **Kubernetes cluster** : Cluster fonctionnel avec Helm
3. **Catalog AskMe** : Version avec support MongoDB

## 🚀 Déploiement MongoDB

### Option 1 : Installation via Helm CLI

```bash
# Ajouter le repository Bitnami
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Installer MongoDB avec les valeurs optimisées
helm install mongodb-shared bitnami/mongodb \
  --namespace askme-mongodb \
  --create-namespace \
  --values ../askme-app-aoai/mongodb-values-minimal.yaml
```

### Option 2 : Installation via Rancher UI

1. **Apps & Marketplace** → **Repositories** → **Add Repository**
   - Name: `bitnami`
   - URL: `https://charts.bitnami.com/bitnami`

2. **Charts** → **MongoDB** (by Bitnami) → **Install**
   - Namespace: `askme-mongodb`
   - Utilisez la configuration dans `mongodb-values-minimal.yaml`

## 🔧 Configuration Client

### 1. Prérequis - Mise à jour des Secrets

**IMPORTANT** : Avant le premier déploiement MongoDB, mettre à jour les secrets :

```bash
# Mettre à jour le secret global avec les clés MongoDB
./update-mongodb-secrets.sh askme-platform

# Vérifier que les variables MongoDB sont présentes
kubectl get secret askme-local-tokens -n askme-platform -o yaml | grep MONGODB
```

### 2. Déploiement avec MongoDB

```bash
# Déployer un nouveau client avec MongoDB
./deploy-client.sh <nom-client> --mongodb

# Exemples
./deploy-client.sh avanteam --mongodb
./deploy-client.sh qsaas --mongodb
```

### 2. Configuration Manuelle values.yaml

```yaml
# Activer MongoDB
mongodb:
  enabled: true
  uri: "mongodb://root:AskMe-MongoDB-2024-Secure!@mongodb-external:27017/?replicaSet=rs0&readPreference=secondaryPreferred"
  database: "askme_<client>"  # Remplacé automatiquement
  enableFeedback: false

# Configurer le provider d'historique
config:
  historyProvider: "MONGODB"  # Au lieu de COSMOSDB
```

### 3. Déploiement Rancher UI

1. **Apps & Marketplace** → **AskMe** → **Install/Upgrade**
2. **MongoDB Configuration** :
   - Cocher `MongoDB Enabled`
   - Laisser les autres valeurs par défaut
3. **General Configuration** :
   - History Provider: `MONGODB`

## 🔄 Migration depuis CosmosDB

### 1. Préparer la Migration

```bash
# Définir les variables CosmosDB
export COSMOS_ENDPOINT='https://your-cosmos.documents.azure.com:443/'
export COSMOS_KEY='your-cosmos-key'

# Initialiser la base MongoDB pour le client
./init-mongodb-client.sh <nom-client>
```

### 2. Migration Dry-Run

```bash
# Test de migration sans modification
./migrate-client-to-mongodb.sh <nom-client> --dry-run
```

### 3. Migration Production

```bash
# Migration réelle des données
./migrate-client-to-mongodb.sh <nom-client>
```

### 4. Basculement Application

```bash
# Mettre à jour l'application pour utiliser MongoDB
helm upgrade askme-<client> ./charts/askme \
  --namespace askme-platform \
  --set mongodb.enabled=true \
  --set config.historyProvider=MONGODB
```

## 📁 Scripts Disponibles

| Script | Description |
|--------|-------------|
| `deploy-client.sh` | Déploiement client avec option `--mongodb` |
| `init-mongodb-client.sh` | Initialisation database MongoDB pour un client |
| `migrate-client-to-mongodb.sh` | Migration CosmosDB → MongoDB |

## 🔍 Vérifications

### Status MongoDB

```bash
# Vérifier les pods MongoDB
kubectl get pods -n askme-mongodb

# Vérifier le Replica Set
kubectl exec -n askme-mongodb mongodb-shared-0 -- \
  mongosh --eval "rs.status()"

# Vérifier les databases
kubectl exec -n askme-mongodb mongodb-shared-0 -- \
  mongosh --eval "show databases"
```

### Status Application

```bash
# Vérifier les services externes
kubectl get services -n askme-platform -l askme.avanteam.com/component=mongodb-external-service

# Vérifier les secrets MongoDB
kubectl get secrets -n askme-platform -l askme.avanteam.com/component=mongodb-credentials

# Tester l'API historique
curl http://askme-<client>.domain.com/history/ensure
```

## 🆚 Comparaison CosmosDB vs MongoDB

| Aspect | CosmosDB | MongoDB |
|--------|----------|---------|
| **Coût** | ⚠️ Facturé par Azure | ✅ Gratuit (self-hosted) |
| **Performance** | ✅ Global, faible latence | ✅ Replica Set, load balancing |
| **Maintenance** | ✅ Managé Azure | ⚠️ À maintenir |
| **Indépendance** | ❌ Dépendant Azure | ✅ Infrastructure contrôlée |
| **Multi-tenant** | ✅ Containers séparés | ✅ Databases séparées |

## 🚨 Rollback vers CosmosDB

En cas de problème, rollback possible :

```bash
# Revenir à CosmosDB
helm upgrade askme-<client> ./charts/askme \
  --namespace askme-platform \
  --set mongodb.enabled=false \
  --set config.historyProvider=COSMOSDB
```

## 📞 Support & Troubleshooting

### Erreurs Communes

1. **"Connection refused"** : Vérifier que MongoDB est démarré
2. **"Authentication failed"** : Vérifier les credentials MongoDB
3. **"Database not found"** : Exécuter `init-mongodb-client.sh`

### Logs Utiles

```bash
# Logs MongoDB
kubectl logs -n askme-mongodb deployment/mongodb-shared

# Logs application
kubectl logs -n askme-platform deployment/askme-<client>

# Événements Kubernetes
kubectl get events -n askme-platform --sort-by=.metadata.creationTimestamp
```

---

📖 **Documentation complète** : Voir `MIGRATION_GUIDE.md` dans askme-app-aoai