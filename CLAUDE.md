# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands
- Package Helm chart: `helm package charts/askme --destination ./`
- Update Helm repository index: `helm repo index . --url https://raw.githubusercontent.com/avanteam/askme-rancher-catalog/prod`
- Validate Helm chart: `helm lint charts/askme`
- Test chart templates: `helm template test-release charts/askme --dry-run`
- Run catalog tests: `./test-catalog.sh [client-name]`
- Test chart validation only: `./test-catalog.sh validate`
- Test deployment: `./test-catalog.sh deploy [client-name]`
- Clean up test resources: `./test-catalog.sh cleanup`
- Deploy test client: `./deploy-client.sh`

## Project Structure and Architecture

### Rancher Catalog Repository
This repository implements a **Rancher Catalog** for deploying AskMe AI assistant applications with multi-LLM support. The catalog enables 1-click deployments via Rancher's web interface with version selection and configuration management.

### Core Architecture
```
askme-rancher-catalog/
├── charts/askme/               # Main Helm chart
│   ├── Chart.yaml              # Chart metadata and versioning
│   ├── values.yaml             # Default configuration values
│   ├── questions.yaml          # Rancher UI form configuration
│   ├── scripts/                # DNS automation scripts
│   └── templates/              # Kubernetes manifests (9 files)
├── docs/                       # Rancher setup documentation
├── .github/workflows/          # CI/CD automation
├── index.yaml                  # Helm repository index
└── test-catalog.sh            # Automated testing script
```

### Helm Chart Templates
The chart contains 10 Kubernetes resource templates:
- **configmap.yaml**: Application configuration (non-sensitive variables only)
- **secret.yaml**: Client-specific API tokens and sensitive keys
- **deployment.yaml**: Main application deployment with initContainer
- **dns-job.yaml**: Automated DNS record creation (OVH)
- **global-secret-rbac.yaml**: RBAC for global secrets access
- **global-secret-sync.yaml**: Intelligent secret fusion (global + local)
- **ingress.yaml**: HTTPS ingress with Let's Encrypt
- **rancher-project.yaml**: Rancher project isolation
- **rancher-rbac.yaml**: Rancher role-based access control
- **service.yaml**: Kubernetes service for pod exposure

### Multi-LLM Support
The application supports multiple LLM providers:
- **Azure OpenAI**: Primary provider with GPT-4o models
- **Claude AI**: Anthropic Claude Sonnet models
- **OpenAI Direct**: Direct OpenAI API integration
- **Mistral AI**: Mistral large models
- **Gemini**: Google Gemini models

Each provider has individual configuration sections in values.yaml with API keys, endpoints, and model parameters.

### Configuration Management
- **values.yaml**: 386 lines of comprehensive configuration covering all LLM providers, Azure services, UI customization, DNS automation, and deployment settings
- **questions.yaml**: Rancher UI form definitions for easy configuration via web interface
- **Global secrets**: Shared API keys across multiple clients via `askme-tokens`, `harbor-keys`, and `ovh-global-dns-keys` secrets in `askme-platform` namespace

### Infrastructure Integration
- **Harbor Registry**: Private Docker images at `7wpjr0wh.c1.gra9.container-registry.ovh.net`
- **OVH DNS**: Automated subdomain creation via Python script
- **Let's Encrypt**: Automatic SSL certificate provisioning
- **Azure Services**: Integration with Azure OpenAI, Cognitive Search, CosmosDB, Speech Services

### Deployment Workflow
1. **Development**: Changes made in companion `askme-app-aoai` repository
2. **Release**: Git tags trigger automated Docker builds and Helm packaging
3. **Catalog Sync**: Rancher automatically detects new chart versions
4. **Deployment**: 1-click deployment via Rancher UI with form-based configuration
5. **Secret Synchronization**: Global secrets from `askme-platform` namespace are automatically synchronized to deployment namespace
6. **DNS**: Automatic subdomain creation and SSL certificate provisioning with security validation
7. **Verification**: All jobs complete successfully and application pods start running

### Version Management
- Semantic versioning (v1.0.0, v1.0.1, etc.)
- Chart versions synchronized with application versions
- Release notes documented in Chart.yaml annotations
- Backward compatibility maintained across versions

### Security Architecture
- **Kubernetes Secrets**: Base64-encoded API key storage
- **RBAC**: Namespace-based isolation with Rancher integration
- **Network Policies**: Controlled traffic between services
- **Image Security**: Harbor registry scanning for vulnerabilities
- **Secret Management**: Global vs. client-specific secret handling
- **DNS Security**: RFC 1035 validation and URL escaping to prevent injection attacks
- **Input Validation**: Strict validation of DNS zones, subdomains, and IP addresses
- **Container Security**: Use of `alpine/k8s:1.30.0` image with proper shell support

### Testing and Validation
The `test-catalog.sh` script provides comprehensive testing:
- **Chart Validation**: Helm lint and template validation
- **Kubernetes Testing**: Dry-run deployments with realistic configurations
- **Questions Validation**: YAML syntax and required field checks
- **End-to-End Testing**: Full deployment cycle with cleanup

### Operations and Monitoring
- **Rancher Dashboard**: Real-time metrics and log aggregation
- **Health Probes**: Liveness and readiness checks configured
- **Resource Management**: CPU/memory limits and requests defined
- **Scaling**: Horizontal pod autoscaling support via replicaCount
- **Updates**: Rolling updates with zero-downtime deployments
- **Rollback**: 1-click rollback functionality via Rancher UI

This catalog architecture enables enterprise-grade multi-tenant AI assistant deployments with complete automation from code to production.
- tu es un expert Rancher et Kubernetes, tu proposes toujours des solutions propres et efficaces