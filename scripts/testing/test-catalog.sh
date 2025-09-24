#!/bin/bash

# Script de test pour le Rancher Catalog AskMe
# Usage: ./test-catalog.sh [client-name]

set -e

CLIENT_NAME=${1:-"test-client"}
NAMESPACE="askme-test"
CHART_DIR="charts/askme"

# Couleurs pour les logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE} $1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

# Vérification des prérequis
check_prerequisites() {
    log_header "Vérification des Prérequis"
    
    if ! command -v helm &> /dev/null; then
        log_error "Helm n'est pas installé"
        exit 1
    fi
    
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl n'est pas installé"
        exit 1
    fi
    
    log_info "✅ Prérequis vérifiés"
}

# Validation du chart Helm
validate_chart() {
    log_header "Validation du Chart Helm"
    
    log_info "Validation de la syntaxe Chart.yaml..."
    helm lint "$CHART_DIR"
    
    log_info "Validation des templates..."
    helm template test-release "$CHART_DIR" \
        --set client.name="$CLIENT_NAME" \
        --set client.domain="test.example.com" \
        --set azure.openai.endpoint="https://test.openai.azure.com" \
        --set azure.openai.key="test-key" \
        --set azure.search.service="test-search" \
        --set azure.search.index="test-index" \
        --set azure.search.key="test-key" \
        --set azure.cosmosdb.account="test-cosmos" \
        --set azure.cosmosdb.key="test-key" \
        --dry-run > /tmp/askme-templates.yaml
    
    log_info "Validation des ressources Kubernetes..."
    kubectl apply --dry-run=client -f /tmp/askme-templates.yaml
    
    log_info "✅ Chart validé avec succès"
}

# Test de déploiement local
test_deployment() {
    log_header "Test de Déploiement Local"
    
    # Créer le namespace de test
    log_info "Création du namespace de test..."
    kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
    
    # Déploiement avec valeurs de test
    log_info "Déploiement du chart avec valeurs de test..."
    helm upgrade --install "askme-$CLIENT_NAME" "$CHART_DIR" \
        --namespace "$NAMESPACE" \
        --set client.name="$CLIENT_NAME" \
        --set client.namespace="$NAMESPACE" \
        --set client.domain="$CLIENT_NAME.test.local" \
        --set image.tag="latest" \
        --set azure.openai.endpoint="https://test.openai.azure.com" \
        --set azure.openai.key="test-key-placeholder" \
        --set azure.openai.model="gpt-4o" \
        --set claude.apiKey="test-claude-key" \
        --set azure.search.service="test-search" \
        --set azure.search.index="test-index" \
        --set azure.search.key="test-search-key" \
        --set azure.cosmosdb.account="test-cosmos" \
        --set azure.cosmosdb.key="test-cosmos-key" \
        --set azure.speech.key="test-speech-key" \
        --set azure.speech.region="francecentral" \
        --set replicaCount=1 \
        --wait --timeout=5m
    
    log_info "✅ Déploiement réussi"
}

# Vérification du déploiement
verify_deployment() {
    log_header "Vérification du Déploiement"
    
    log_info "Status Helm..."
    helm status "askme-$CLIENT_NAME" --namespace "$NAMESPACE"
    
    log_info "Pods Kubernetes..."
    kubectl get pods -n "$NAMESPACE" -l "app.kubernetes.io/instance=askme-$CLIENT_NAME"
    
    log_info "Services..."
    kubectl get services -n "$NAMESPACE"
    
    log_info "ConfigMaps..."
    kubectl get configmaps -n "$NAMESPACE"
    
    log_info "Secrets..."
    kubectl get secrets -n "$NAMESPACE"
    
    log_info "✅ Vérification terminée"
}

# Nettoyage
cleanup() {
    log_header "Nettoyage"
    
    log_info "Suppression de la release Helm..."
    helm uninstall "askme-$CLIENT_NAME" --namespace "$NAMESPACE" || true
    
    log_info "Suppression du namespace..."
    kubectl delete namespace "$NAMESPACE" || true
    
    log_info "✅ Nettoyage terminé"
}

# Test des questions Rancher
test_questions() {
    log_header "Test des Questions Rancher"
    
    if [[ -f "$CHART_DIR/questions.yaml" ]]; then
        log_info "Validation questions.yaml..."
        
        # Vérifier la syntaxe YAML
        python3 -c "
import yaml
import sys
try:
    with open('$CHART_DIR/questions.yaml', 'r') as f:
        questions = yaml.safe_load(f)
    
    if 'questions' not in questions:
        print('❌ Section questions manquante')
        sys.exit(1)
    
    required_fields = ['variable', 'type', 'label']
    for i, q in enumerate(questions['questions']):
        for field in required_fields:
            if field not in q:
                print(f'❌ Question {i}: champ {field} manquant')
                sys.exit(1)
    
    print('✅ questions.yaml valide')
except Exception as e:
    print(f'❌ Erreur questions.yaml: {e}')
    sys.exit(1)
"
    else
        log_warn "questions.yaml non trouvé"
    fi
}

# Menu principal
main() {
    log_header "Test AskMe Rancher Catalog"
    
    case "${2:-all}" in
        "validate")
            check_prerequisites
            validate_chart
            test_questions
            ;;
        "deploy")
            check_prerequisites
            validate_chart
            test_deployment
            verify_deployment
            ;;
        "cleanup")
            cleanup
            ;;
        "all"|*)
            check_prerequisites
            validate_chart
            test_questions
            test_deployment
            verify_deployment
            
            log_info "Test terminé. Nettoyage dans 30 secondes..."
            sleep 30
            cleanup
            ;;
    esac
    
    log_info "🎉 Test du catalog terminé avec succès!"
}

# Gestion des erreurs
trap 'log_error "Test interrompu"; cleanup; exit 1' INT TERM

# Exécution
main "$@"