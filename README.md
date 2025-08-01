# 🚀 AskMe Rancher Catalog

Catalog Rancher officiel pour les déploiements AskMe multi-clients avec support de plusieurs providers LLM.

## 🎯 Fonctionnalités

- **🎛️ Déploiement en 1 clic** depuis l'interface Rancher
- **🏷️ Versioning Git** : Sélection de version (latest, v1.0.0, v1.1.0, etc.)
- **⚙️ Configuration par client** : Variables d'environnement personnalisables via interface web
- **🏢 Multi-tenant** : Isolation complète par namespace et client
- **✅ Production Ready** : Templates testés et validés en production
- **🤖 Multi-LLM Support** : Azure OpenAI, Claude, OpenAI Direct, Mistral, Gemini

## 🚀 Guide de Démarrage Rapide

### 1. Configurer le Catalog dans Rancher

#### Via Interface Web
1. Se connecter à Rancher : `https://jg8s67.9r1m.rancher.ovh.net`
2. **Apps & Marketplace** → **Repositories** → **Create**
3. Configuration :
   ```
   Name: askme-catalog
   Target: Git repository containing Helm chart
   Git Repo URL: https://github.com/avanteam/askme-rancher-catalog
   Git Branch: main
   ```

#### Via kubectl
```bash
kubectl apply -f rancher-catalog-setup.yaml
```

### 2. Déployer un Client
1. **Apps & Marketplace** → **Charts**
2. Rechercher **"AskMe"**
3. **Install** → Sélectionner **version** → Configurer **variables**
4. **Deploy** ✨

## 📋 Configuration Client

### Configuration Essentielle
- **Nom du Client** : `askme-principal`
- **Domaine** : `askme.avanteam-online.com`
- **Namespace** : `askme-app`

### Configuration LLM
- **Provider par défaut** : `CLAUDE`
- **Providers disponibles** : `AZURE_OPENAI,CLAUDE,OPENAI_DIRECT,MISTRAL,GEMINI`

### API Keys (sécurisées)
- **Azure OpenAI** : `Ckt6vNVrM1RMG0z0Zpz...`
- **Claude AI** : `sk-ant-api03-GUzW2wcze...`
- **Azure Search** : `cmAQfwk1UFi0CrA1nu6H...`
- **Azure CosmosDB** : `X1sw13XIqynJYeB2AY6h...`
- **Azure Speech** : `DbsYXoSVuWrPh4cB5fI6...`

### Fonctionnalités Avancées
- **Reconnaissance vocale** : Mots-clés personnalisables
- **Upload d'images** : Support multimodal
- **Historique** : Persistance CosmosDB

## 🔄 Workflow de Release Intégré

### Développement → Production
```bash
# 1. Développement dans askme-app-aoai
git checkout develop
# ... développement ...
git commit -m "feat: nouvelle fonctionnalité"

# 2. Release synchronisée
git tag v1.2.0
git push origin v1.2.0

# 3. Pipeline automatique :
# ✅ Build Docker image avec tag v1.2.0
# ✅ Package Helm chart v1.2.0
# ✅ Mise à jour catalog Rancher
# ✅ Version v1.2.0 disponible dans UI
```

### Déploiement Client
- **Interface Rancher** : Sélection de version dans dropdown
- **Configuration guidée** : Formulaire web avec tous les paramètres
- **Rolling update** : Mise à jour sans interruption
- **Rollback 1-clic** : Retour version précédente

## 🏗️ Architecture

### Structure Repository
```
askme-rancher-catalog/
├── charts/askme/               # Chart Helm principal
│   ├── Chart.yaml              # Métadonnées et version
│   ├── values.yaml             # Configuration par défaut
│   ├── questions.yaml          # Interface Rancher (formulaire)
│   ├── scripts/                # Scripts DNS OVH
│   └── templates/              # Manifestes Kubernetes
│       ├── configmap.yaml      # Configuration application
│       ├── secret.yaml         # API keys sécurisées
│       ├── deployment.yaml     # Déploiement principal
│       ├── service.yaml        # Service Kubernetes
│       ├── ingress.yaml        # Exposition HTTPS
│       └── dns-job.yaml        # Création DNS automatique
├── docs/                       # Documentation spécialisée
│   └── rancher-setup.md        # Guide configuration Rancher
├── .github/workflows/          # Pipeline CI/CD
├── index.yaml                  # Index catalog Helm
└── test-catalog.sh            # Tests automatisés
```

### Intégrations
- **Harbor Registry OVH** : Images Docker privées
- **DNS OVH** : Création automatique sous-domaines
- **Let's Encrypt** : Certificats SSL automatiques
- **Rancher RBAC** : Permissions granulaires par projet

## 🏷️ Versions et Compatibilité

| Version | Date | Features | Status |
|---------|------|----------|--------|
| **v1.0.0** | 2025-07-30 | Multi-LLM support initial | ✅ Stable |
| **v1.1.0** | TBD | RBAC + DNS automatique | 🚧 Développement |
| **latest** | Continue | Dernières fonctionnalités | ⚠️ Dev only |

## 🔧 Gestion et Maintenance

### Mise à Jour Client
1. **Installed Apps** → Sélectionner client → **Upgrade**
2. Choisir nouvelle version → Ajuster configuration → **Upgrade**

### Monitoring
- **Rancher Dashboard** : Métriques temps réel
- **Logs centralisés** : Via interface Rancher
- **Alerting** : Intégration Prometheus/Grafana

### Rollback
- **1-clic rollback** depuis interface Rancher
- **Préservation configuration** : Les settings restent intacts
- **Zero downtime** : Bascule sans interruption service

## 🛡️ Sécurité

- **API Keys** : Stockage Kubernetes Secrets (encodage base64)
- **RBAC** : Isolation par namespace et projet Rancher
- **Network Policies** : Contrôle trafic réseau
- **Image Scanning** : Vérification sécurité Harbor

## 📊 Tests et Validation

```bash
# Tests automatisés
./test-catalog.sh validate

# Tests d'intégration
./test-catalog.sh deploy test-client
```

## 🆘 Support et Documentation

- **Documentation détaillée** : [`docs/rancher-setup.md`](docs/rancher-setup.md)
- **Tests de validation** : `test-catalog.sh`
- **Repository source** : [askme-app-aoai](https://github.com/avanteam/askme-app-aoai)
- **Issues** : GitHub Issues pour rapports bugs/demandes fonctionnalités

---

## 🎯 Workflow Complet

```mermaid
graph TD
    A[Développement askme-app-aoai] --> B[Git Tag v1.x.x]
    B --> C[GitHub Actions Pipeline]
    C --> D[Build Docker Image]
    C --> E[Package Helm Chart]
    D --> F[Push Harbor Registry]
    E --> G[Update Catalog Index]
    G --> H[Rancher UI Sync]
    H --> I[Version Disponible]
    I --> J[Deploy Client 1-Click]
    J --> K[Client Opérationnel]
```

**🚀 Déploiement AskMe simplifié : du code source au client final en quelques clics !**