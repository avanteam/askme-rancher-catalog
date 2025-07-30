# AskMe Rancher Catalog

Catalog Rancher officiel pour les déploiements AskMe multi-clients.

## 🎯 Fonctionnalités

- **Déploiement en 1 clic** depuis l'interface Rancher
- **Versioning Git** : Sélection de version (latest, v1.0.0, v1.1.0, etc.)
- **Configuration par client** : Variables d'environnement personnalisables
- **Multi-tenant** : Isolation par namespace et client
- **Production Ready** : Templates testés et validés

## 🚀 Utilisation

### 1. Ajouter le Catalog dans Rancher
```
Type: Git Repository
URL: https://github.com/votre-org/askme-rancher-catalog
Branch: main
```

### 2. Déployer un Client
1. **Apps & Marketplace** → **Charts**
2. Sélectionner **AskMe**
3. Choisir la **version** souhaitée
4. Configurer les **variables client**
5. **Install**

## 📋 Configuration Client

### Variables Obligatoires
- `client.name` : Nom du client (ex: "askme", "qsaas")
- `client.domain` : Domaine du client (ex: "askme.avanteam-online.com")
- `client.namespace` : Namespace Kubernetes

### API Keys
- `azure.openai.key` : Clé Azure OpenAI
- `claude.api.key` : Clé Claude AI
- `azure.search.key` : Clé Azure Search
- etc.

## 🔄 Workflow de Release

1. **Développement** : Modifications locales
2. **Git Push** : Push vers repository
3. **Git Tag** : Création tag version (`git tag v1.1.0`)
4. **GitHub Actions** : Build automatique + Mise à jour catalog
5. **Rancher** : Nouvelle version disponible dans l'interface

## 📁 Structure

```
askme-rancher-catalog/
├── charts/askme/           # Chart Helm principal
│   ├── Chart.yaml          # Métadonnées et version
│   ├── values.yaml         # Valeurs par défaut
│   ├── questions.yaml      # Interface Rancher
│   └── templates/          # Templates Kubernetes
├── docs/                   # Documentation
└── README.md              # Ce fichier
```

## 🏷️ Versions Supportées

- **v1.0.0** : Version initiale avec support multi-LLM
- **v1.1.0** : Ajout intégration Rancher RBAC
- **latest** : Dernière version de développement

## 🆘 Support

Pour toute question ou problème :
- Issues GitHub : [Lien vers issues]
- Documentation : [Lien vers docs]
- Contact : [Contact support]