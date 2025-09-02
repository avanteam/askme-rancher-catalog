#!/bin/bash

# Script de déploiement multi-client AskMe
# Usage: ./deploy-client.sh <nom-client>
# Exemple: ./deploy-client.sh rh

if [ -z "$1" ]; then
    echo "Usage: $0 <nom-client>"
    echo "Exemple: $0 rh"
    exit 1
fi

CLIENT_NAME="askme-$1"
NAMESPACE="askme-platform"

echo "🚀 Déploiement du client: $CLIENT_NAME"
echo "📦 Namespace: $NAMESPACE"

# Vérifier que le namespace existe
kubectl get namespace $NAMESPACE > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "❌ Namespace $NAMESPACE n'existe pas"
    echo "Créez-le d'abord: kubectl create namespace $NAMESPACE"
    exit 1
fi

# Vérifier que le secret global existe
kubectl get secret askme-global-api-keys -n $NAMESPACE > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "❌ Secret global 'askme-global-api-keys' manquant dans $NAMESPACE"
    echo "Créez-le d'abord avec votre fichier clean.env"
    exit 1
fi

# Déployer avec Helm
helm install $CLIENT_NAME ./charts/askme \
    --namespace $NAMESPACE \
    --set client.name=$CLIENT_NAME \
    --set client.namespace=$NAMESPACE

if [ $? -eq 0 ]; then
    echo "✅ Client $CLIENT_NAME déployé avec succès!"
    echo "🌐 Vérifiez: kubectl get pods -n $NAMESPACE -l app.kubernetes.io/instance=$CLIENT_NAME"
else
    echo "❌ Échec du déploiement"
    exit 1
fi