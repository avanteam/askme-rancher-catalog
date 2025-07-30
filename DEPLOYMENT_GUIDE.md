# 🚀 Guide de Déploiement AskMe Rancher Catalog

Guide complet pour déployer l'architecture Rancher Catalog pour AskMe.

## 🎯 Architecture Complète

```
Repository Git (askme-rancher-catalog)
├── charts/askme/                    # Chart Helm versioned
│   ├── Chart.yaml                   # Métadonnées + version Git
│   ├── values.yaml                  # Template configurable
│   ├── questions.yaml               # Interface Rancher
│   └── templates/                   # Templates Kubernetes
├── .github/workflows/release.yml    # Pipeline CI/CD
├── docs/rancher-setup.md            # Documentation Rancher
└── test-catalog.sh                  # Tests automatisés
```

## 📦 Étapes de Déploiement

### 1. **Créer le Repository Git**

```bash
# Créer repository sur GitHub/GitLab
# Nom: askme-rancher-catalog
# Visibilité: Privé (pour Avanteam)

# Push du catalog
cd askme-rancher-catalog
git init
git add .
git commit -m "feat: Initial AskMe Rancher Catalog"
git branch -M main
git remote add origin https://github.com/avanteam/askme-rancher-catalog.git
git push -u origin main
```

### 2. **Configurer les Secrets GitHub**

Dans **GitHub → Settings → Secrets and Variables → Actions** :

```
HARBOR_USERNAME=nhPynZRKec
HARBOR_PASSWORD=<votre-password-harbor>
```

### 3. **Créer la Première Release**

```bash
# Tag version initiale
git tag v1.0.0
git push origin v1.0.0

# GitHub Actions va automatiquement :
# ✅ Build Docker image
# ✅ Package Helm chart  
# ✅ Create GitHub Release
# ✅ Publish catalog
```

### 4. **Configurer Rancher**

#### Via Interface Web

1. **Se connecter à Rancher** : `https://jg8s67.9r1m.rancher.ovh.net`
2. **Apps & Marketplace** → **Repositories** → **Create**
3. **Configuration** :
   ```
   Name: askme-catalog
   Target: Git repository containing Helm chart
   Git Repo URL: https://github.com/avanteam/askme-rancher-catalog
   Git Branch: main
   ```

#### Via kubectl

```bash
kubectl apply -f - <<EOF
apiVersion: catalog.cattle.io/v1
kind: ClusterRepo
metadata:
  name: askme-catalog
spec:
  gitRepo: https://github.com/avanteam/askme-rancher-catalog
  gitBranch: main
EOF
```

### 5. **Déployer un Client**

#### Via Rancher UI

1. **Apps & Marketplace** → **Charts**
2. **Chercher "AskMe"**
3. **Install** → **Sélectionner version** → **Configurer variables**
4. **Deploy** ✨

#### Variables Client Exemple

```yaml
# Configuration Client
client.name: "askme-principal"
client.domain: "askme.avanteam-online.com"
client.namespace: "askme-app"

# LLM Configuration
llm.defaultProvider: "CLAUDE"
azure.openai.endpoint: "https://askmeopenai.openai.azure.com/"
azure.openai.key: "Ckt6vNVrM1RMG0z0Zpz..."
claude.apiKey: "sk-ant-api03-GUzW2wcze..."

# Azure Services
azure.search.service: "askmesearchprod"
azure.search.index: "idx-v-avanteam-qualitysaas-dev"
azure.search.key: "cmAQfwk1UFi0CrA1nu6H..."
azure.cosmosdb.account: "db-askme-avanteam-qualitysaas-dev-historique"
azure.cosmosdb.key: "X1sw13XIqynJYeB2AY6h..."
azure.speech.key: "DbsYXoSVuWrPh4cB5fI6..."

# Voice Features
voice.wakeWords: "Sarah,Richard,Patrick,Mérade"
```

## 🔄 Workflow de Développement

### Développement Local

```bash
# 1. Modifications du code AskMe
git checkout develop
# ... développement ...

# 2. Test local
./test-catalog.sh test-client validate

# 3. Commit & Push
git add .
git commit -m "feat: nouvelle fonctionnalité"
git push origin develop
```

### Release en Production

```bash
# 1. Merge vers main
git checkout main
git merge develop

# 2. Tag nouvelle version
git tag v1.1.0
git push origin main --tags

# 3. GitHub Actions automatique :
# - Build image Docker
# - Package Helm chart
# - Create GitHub Release
# - Update catalog
```

### Déploiement Client

```bash
# Via Rancher UI :
# 1. Apps & Marketplace → Installed Apps
# 2. Sélectionner client → Upgrade
# 3. Choisir v1.1.0 → Configure → Upgrade
```

## 🎨 Interface Rancher

L'interface Rancher affichera automatiquement :

### **Onglets de Configuration**

1. **Configuration Client**
   - Nom, domaine, namespace
   
2. **Interface Utilisateur**  
   - Titre, logos, description
   
3. **Configuration LLM**
   - Provider par défaut, providers disponibles
   
4. **Azure OpenAI**
   - Endpoint, API key, modèle (si activé)
   
5. **Claude AI**
   - API key, modèle (si activé)
   
6. **Azure Search**
   - Service, index, API key
   
7. **Azure CosmosDB**
   - Compte, database, API key
   
8. **Services Vocaux**
   - Azure Speech, wake words
   
9. **Ressources**
   - CPU, RAM, nombre de pods
   
10. **Configuration Avancée**
    - Debug, version image

### **Fonctionnalités Rancher**

✅ **Sélection de version** : Dropdown avec toutes les releases Git  
✅ **Validation des champs** : Types, requis, conditionnels  
✅ **Champs sécurisés** : API keys masquées  
✅ **Grouping logique** : Configuration organisée par thème  
✅ **Help tooltips** : Description pour chaque champ  
✅ **Preview YAML** : Voir les valeurs avant déploiement  

## 🔧 Maintenance

### Mise à Jour du Catalog

```bash
# Modifier questions.yaml ou templates
vim charts/askme/questions.yaml

# Incrémenter version
vim charts/askme/Chart.yaml  # version: 1.1.0

# Release
git add . && git commit -m "feat: nouvelle configuration"
git tag v1.1.0 && git push origin main --tags
```

### Debug Déploiement

```bash
# Logs Rancher
kubectl logs -n cattle-system deployment/rancher

# Status catalog
kubectl get clusterrepo askme-catalog -o yaml

# Forcer sync
kubectl annotate clusterrepo askme-catalog catalog.cattle.io/last-refresh-
```

## 📊 Monitoring

### Dashboard Rancher

- **Apps & Marketplace** → **Installed Apps** : Vue d'ensemble
- **Workloads** → **Deployments** : État des pods
- **Service Discovery** → **Ingresses** : URLs publiques

### Métriques Clients

```bash
# Status tous les clients
helm list -A | grep askme

# Logs client spécifique  
kubectl logs deployment/askme-app -n askme-app --tail=50

# Métriques ressources
kubectl top pods -n askme-app
```

## 🎉 Résultat Final

Avec cette architecture, tu auras :

### ✅ **App Store AskMe dans Rancher**
- Liste des versions disponibles
- Formulaire de configuration intuitif  
- Déploiement en 1 clic

### ✅ **Gestion Multi-Clients**
- Chaque client dans son namespace
- Configuration indépendante
- Mise à jour selective

### ✅ **Pipeline CI/CD Complet**
- Build automatique sur Git tag
- Tests de validation
- Déploiement sans friction

### ✅ **Versioning et Rollback**
- Historique des versions
- Rollback en 1 clic  
- Migration progressive

### 🚀 **Workflow Final**

```
Dev Local → Git Push → GitHub Actions → Harbor Registry
                                      ↓
                     Rancher Catalog ← Package Helm
                           ↓
Interface Rancher → Select Version → Configure → Deploy
                           ↓
                   Client AskMe Opérationnel 🎉
```

**Tu peux maintenant déployer des clients AskMe en quelques clics depuis Rancher !** 🚀