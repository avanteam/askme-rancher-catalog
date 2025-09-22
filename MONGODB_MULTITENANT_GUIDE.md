# Guide de Déploiement Multi-Tenant MongoDB pour AskMe

## Vue d'ensemble

Ce guide explique comment déployer plusieurs instances d'AskMe avec MongoDB, où chaque client dispose de sa propre base de données isolée et sécurisée.

## Architecture MongoDB Multi-Tenant

### Principe

- **Un seul cluster MongoDB** : Partagé entre tous les clients dans le namespace `askme-mongodb`
- **Une database par client** : Chaque client a sa database dédiée `askme_<client_name>`
- **Credentials uniques** : Chaque client a son utilisateur et mot de passe MongoDB
- **Isolation complète** : Les clients ne peuvent pas accéder aux données des autres

### Structure des databases

```
MongoDB Cluster (askme-mongodb)
├── askme_avanteam          # Client principal Avanteam
│   ├── conversations
│   └── messages
├── askme_qsaas            # Client QSaaS
│   ├── conversations
│   └── messages
└── askme_demo             # Client demo
    ├── conversations
    └── messages
```

## Déploiement via Rancher UI

### 1. Choix du Provider d'Historique

Dans l'interface Rancher, lors du déploiement d'un nouveau client AskMe :

1. **Section "History Configuration"** → `Provider Historique` → Sélectionner **`MONGODB`**

2. **Section "MongoDB Configuration"** → `Activer MongoDB` → **✅ Coché**

### 2. Configuration MongoDB

#### Option Recommandée : Auto-Initialisation (Défaut)

- **`Initialisation Automatique`** → **✅ Coché** (recommandé)
- **`URI Admin MongoDB`** → Laisser la valeur par défaut
- Tous les autres champs peuvent rester par défaut

#### Option Manuelle (Avancée)

Si vous décochez `Initialisation Automatique` :
- Renseigner manuellement `Username Client MongoDB` et `Password Client MongoDB`
- La database devra être créée manuellement

### 3. Déploiement Automatique

Quand vous cliquez sur **"Déployer"** :

1. **Job d'initialisation** : Se lance automatiquement (si auto-init activé)
   - Crée la database `askme_<client_name>`
   - Génère un utilisateur unique avec mot de passe sécurisé
   - Crée les collections `conversations` et `messages`
   - Configure les index de performance

2. **Secret Kubernetes** : Créé automatiquement
   - Contient les credentials générés
   - Stocke l'URI de connexion complète

3. **Application AskMe** : Se connecte automatiquement
   - Utilise les credentials depuis le Secret
   - Prêt à fonctionner immédiatement

## Résultats du Déploiement

### Naming Convention

Pour un déploiement avec Release Name `askme-demo` :

- **Database MongoDB** : `askme_demo`
- **Utilisateur MongoDB** : `askme_demo_user`
- **Secret Kubernetes** : `askme-demo-mongodb-credentials`
- **Service** : `mongodb-external` (dans le namespace du client)

### Credentials Générés

Le Secret contient :
```yaml
MONGODB_URI: mongodb://askme_demo_user:[PASSWORD]@mongodb-external:27017/askme_demo?replicaSet=rs0&readPreference=secondaryPreferred&authSource=askme_demo
MONGODB_DATABASE: askme_demo
MONGODB_USERNAME: askme_demo_user
MONGODB_PASSWORD: [GENERATED_32_CHARS]
```

## Monitoring et Debug

### Vérification du Job d'Initialisation

```bash
# Voir les jobs d'init MongoDB
kubectl get jobs -l askme.avanteam.com/component=mongodb-init-job

# Logs du job d'init
kubectl logs job/askme-demo-mongodb-init
```

### Vérification des Secrets

```bash
# Lister les secrets MongoDB
kubectl get secrets -l askme.avanteam.com/component=mongodb-credentials

# Voir le contenu d'un secret (pour debug)
kubectl get secret askme-demo-mongodb-credentials -o yaml
```

### Connexion directe à MongoDB

```bash
# Se connecter à la database du client
mongosh "mongodb://askme_demo_user:[PASSWORD]@mongodb-shared.askme-mongodb:27017/askme_demo?replicaSet=rs0"

# Vérifier les collections
use askme_demo
show collections
db.conversations.countDocuments()
```

## Sécurité et Isolation

### Principe de Sécurité

1. **Isolation Database** : Chaque client ne peut accéder qu'à sa database
2. **Credentials Uniques** : Mot de passe généré de 32 caractères
3. **Permissions Minimales** : Utilisateur limité à sa database (readWrite)
4. **Secrets Kubernetes** : Credentials stockés sécurisément

### Gestion des Mots de Passe

- **Génération automatique** : Mots de passe de 32 caractères (base64)
- **Rotation** : Possible en relançant le job d'init
- **Backup** : Stockés dans les Secrets Kubernetes uniquement

## Migration CosmosDB vers MongoDB

### Existant avec CosmosDB

Si vous avez déjà des clients avec CosmosDB :

1. **Déployer nouveau client** avec MongoDB
2. **Migrer les données** (script de migration disponible)
3. **Changer la configuration** `HISTORY_PROVIDER=MONGODB`

### Coexistence

CosmosDB et MongoDB peuvent coexister :
- Anciens clients : Restent sur CosmosDB
- Nouveaux clients : Utilisent MongoDB
- Migration progressive possible

## Troubleshooting

### Problèmes Courants

#### Job d'Init Échoué

```bash
# Vérifier les logs du job
kubectl logs job/askme-demo-mongodb-init

# Problèmes fréquents :
# - MongoDB cluster indisponible
# - Credentials admin incorrects
# - Réseau entre namespaces
```

#### Application ne Démarre Pas

```bash
# Vérifier les logs de l'app
kubectl logs deployment/askme-demo

# Vérifier le secret
kubectl get secret askme-demo-mongodb-credentials

# Problèmes fréquents :
# - Secret non créé
# - URI MongoDB incorrecte
# - Service mongodb-external indisponible
```

#### Performance Lente

```bash
# Vérifier les index MongoDB
mongosh "mongodb://..." --eval "db.conversations.getIndexes()"

# Vérifier les performances
kubectl top pods -l app.kubernetes.io/name=askme
```

## Accès Administrateur Global

### Compte Admin MongoDB

Le compte administrateur global permet d'accéder à **toutes** les databases clients pour maintenance et debug.

#### Credentials Admin
```bash
# URI de connexion admin
ADMIN_URI="mongodb://root:AskMe-MongoDB-2024-Secure!@mongodb-shared.askme-mongodb:27017/?authSource=admin&replicaSet=rs0"

# Connexion depuis un pod de maintenance
kubectl run mongodb-admin -it --rm --image=mongo:7.0 --restart=Never -- \
  mongosh "${ADMIN_URI}"
```

#### Opérations Admin

**Lister toutes les databases clients :**
```javascript
// Voir toutes les databases
show dbs

// Filtrer les databases AskMe seulement
db.adminCommand("listDatabases").databases
  .filter(db => db.name.startsWith("askme_"))
  .forEach(db => print(`Database: ${db.name}, Size: ${db.sizeOnDisk} bytes`))
```

**Accéder à une database client spécifique :**
```javascript
// Basculer vers la database d'un client
use askme_avanteam

// Voir les collections
show collections

// Statistiques de la database
db.stats()

// Nombre de conversations par utilisateur
db.conversations.aggregate([
  {$group: {_id: "$userId", count: {$sum: 1}}},
  {$sort: {count: -1}}
])
```

**Maintenance des utilisateurs :**
```javascript
// Voir tous les utilisateurs d'une database
use askme_demo
db.getUsers()

// Réinitialiser le mot de passe d'un utilisateur client
db.updateUser("askme_demo_user", {
  pwd: "nouveau-mot-de-passe-securise"
})

// Vérifier les permissions
db.runCommand({usersInfo: "askme_demo_user", showPrivileges: true})
```

### Sécurité Admin

- ✅ **Accès complet** : Le compte root peut accéder à toutes les databases
- ⚠️ **Usage restreint** : Utiliser uniquement pour maintenance et debug
- 🔐 **Credentials sécurisés** : Mot de passe root stocké dans les secrets Kubernetes
- 📝 **Audit** : Toutes les opérations admin sont loggées

### Scripts de Maintenance

**Script de vérification globale :**
```bash
#!/bin/bash
# maintenance-check.sh

ADMIN_URI="mongodb://root:AskMe-MongoDB-2024-Secure!@mongodb-shared.askme-mongodb:27017/?authSource=admin&replicaSet=rs0"

echo "🔍 Vérification globale des databases AskMe..."

mongosh "${ADMIN_URI}" --eval "
  const databases = db.adminCommand('listDatabases').databases
    .filter(db => db.name.startsWith('askme_'));

  print('📊 DATABASES ASKME TROUVÉES:');
  print('============================');

  databases.forEach(database => {
    use(database.name);
    const convCount = db.conversations.countDocuments();
    const msgCount = db.messages.countDocuments();
    const users = db.conversations.distinct('userId').length;

    print(\`Database: \${database.name}\`);
    print(\`  - Conversations: \${convCount}\`);
    print(\`  - Messages: \${msgCount}\`);
    print(\`  - Utilisateurs uniques: \${users}\`);
    print(\`  - Taille: \${(database.sizeOnDisk / 1024 / 1024).toFixed(2)} MB\`);
    print('');
  });
"
```

## Maintenance

### Backup Automatique

Les databases client sont incluses dans le backup global du cluster MongoDB.

### Monitoring

- **Métriques** : Disponibles via MongoDB exporter
- **Logs** : Centralisés dans le namespace askme-mongodb
- **Alertes** : Configurées au niveau cluster

### Scaling

- **Horizontal** : Ajout de nouveaux clients sans limite
- **Vertical** : Scaling du cluster MongoDB selon les besoins
- **Performance** : Read preference sur nœuds secondaires

## Support

Pour toute question ou problème :

1. **Vérifier les logs** du job d'init et de l'application
2. **Consulter ce guide** pour les cas d'usage courants
3. **Contacter l'équipe** avec les logs détaillés

---

**Date de création** : Septembre 2024
**Version** : 1.0
**Auteur** : AskMe Development Team