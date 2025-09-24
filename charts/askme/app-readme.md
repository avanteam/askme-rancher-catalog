# AskMe - Assistant IA Multi-LLM

## Vue d'ensemble

AskMe est une solution complète d'assistant IA développée par Avanteam, supportant multiple fournisseurs LLM (Large Language Models) pour répondre aux besoins diversifiés des entreprises.

## Fonctionnalités principales

### 🤖 **Support Multi-LLM**
- **Azure OpenAI** : GPT-4o, GPT-4o-mini avec modèles optimisés
- **Claude AI** : Claude Sonnet 3.5 d'Anthropic
- **OpenAI Direct** : Accès direct à l'API OpenAI
- **Mistral AI** : Modèles Mistral Large pour les entreprises
- **Google Gemini** : Intelligence artificielle de Google

### 🎯 **Architecture Multi-Tenant**
- **Isolation par namespace** : Chaque client dispose de son environnement isolé
- **Secrets partagés** : Gestion centralisée des clés API via `askme-platform` namespace
- **RBAC Rancher** : Contrôle d'accès basé sur les rôles intégré

### 🔗 **Intégrations Enterprise**

#### **Bases de données**
- **Azure CosmosDB** : Base de données principale avec API MongoDB
- **MongoDB natif** : Alternative open-source avec support complet
- **Azure Cognitive Search** : Recherche sémantique et vectorielle avancée

#### **Services Azure**
- **Speech Services** : Reconnaissance et synthèse vocale
- **Content Safety** : Modération automatique du contenu
- **Application Insights** : Monitoring et télémétrie

### 🌐 **Infrastructure Cloud**

#### **Container Registry**
- **Harbor privé** : `7wpjr0wh.c1.gra9.container-registry.ovh.net`
- **Images sécurisées** : Scan automatique des vulnérabilités
- **Versioning automatique** : Synchronisation avec les tags Git

#### **DNS & SSL**
- **OVH DNS** : Création automatique de sous-domaines
- **Let's Encrypt** : Certificats SSL automatiques
- **Ingress NGINX** : Reverse proxy haute performance

### 🔧 **Configuration Avancée**

#### **Interface Rancher**
- **77 paramètres configurables** via l'interface web
- **Formulaires dynamiques** avec validation en temps réel
- **Configuration conditionnelle** selon le provider sélectionné
- **Messages système personnalisés** par LLM

#### **Sécurité**
- **Validation DNS** : Protection contre les injections
- **Secrets Kubernetes** : Chiffrement des clés API
- **Isolation réseau** : Network policies dédiées
- **Authentification multi-facteur** : Support OAuth2/SAML

### 🚀 **Déploiement**

#### **Automatisation complète**
1. **Déploiement 1-click** depuis l'interface Rancher
2. **Configuration DNS automatique** avec validation de sécurité
3. **Synchronisation des secrets** depuis le namespace global
4. **Provisioning SSL** automatique avec Let's Encrypt
5. **Validation sanitaire** des paramètres et URLs

#### **Monitoring & Observabilité**
- **Health checks** : Probes de vivacité et disponibilité
- **Métriques Prometheus** : Monitoring des performances
- **Logs centralisés** : Agrégation via Rancher Logging
- **Alerting** : Notifications automatiques en cas d'incident

## Cas d'usage

### 🏢 **Entreprise**
- **Support client intelligent** avec historique de conversations
- **Assistance interne** pour les équipes techniques
- **Analyse documentaire** avec recherche sémantique
- **Formation et onboarding** du personnel

### 🔬 **R&D**
- **Analyse de code** avec suggestions d'amélioration
- **Revue documentaire** scientifique et technique
- **Prototypage rapide** d'assistants spécialisés
- **Tests A/B** sur différents modèles LLM

### 🏛️ **Secteur Public**
- **Accueil citoyen** 24/7 avec réponses personnalisées
- **Support administratif** pour les démarches
- **Analyse de documents** officiels
- **Compliance RGPD** intégrée

## Prérequis techniques

### **Kubernetes**
- Version ≥ 1.21.0
- Namespace `askme-platform` pour les secrets globaux
- Support Ingress NGINX
- Stockage persistant (optionnel pour MongoDB)

### **Rancher**
- Version ≥ 2.6.0
- Accès aux charts custom
- RBAC activé
- DNS configuré

### **Secrets requis**
- Clés API des fournisseurs LLM choisis
- Credentials Azure (si CosmosDB/Search utilisés)
- Token OVH DNS (pour l'automatisation DNS)
- Credentials Harbor Registry

## Support et documentation

- **Documentation complète** : [GitHub Repository](https://github.com/avanteam/askme-rancher-catalog)
- **Support technique** : info@avanteam.com
- **Guides de déploiement** : Voir dossier `docs/`
- **Scripts utilitaires** : Voir dossier `scripts/`

---

**Version actuelle** : 1.0.30
**Maintenu par** : Avanteam DevOps
**Licence** : Propriétaire Avanteam