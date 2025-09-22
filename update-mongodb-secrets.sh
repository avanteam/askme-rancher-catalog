#!/bin/bash

# Script de mise à jour des secrets MongoDB pour askme-rancher-catalog
# Usage: ./update-mongodb-secrets.sh <namespace>
# Exemple: ./update-mongodb-secrets.sh askme-platform

if [ -z "$1" ]; then
    echo "Usage: $0 <namespace>"
    echo "Exemple: $0 askme-platform"
    exit 1
fi

NAMESPACE="$1"

echo "🔐 Mise à jour des secrets MongoDB pour namespace: $NAMESPACE"

# Vérifier que le namespace existe
kubectl get namespace $NAMESPACE > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "❌ Namespace $NAMESPACE n'existe pas"
    echo "Créez-le d'abord: kubectl create namespace $NAMESPACE"
    exit 1
fi

# Vérifier que MongoDB est accessible
echo "🔍 Vérification de MongoDB..."
kubectl get service mongodb-shared -n askme-mongodb > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "❌ MongoDB service non trouvé dans askme-mongodb namespace"
    echo "Installez MongoDB d'abord"
    exit 1
fi

# Récupérer le mot de passe root MongoDB
echo "🔑 Récupération credentials MongoDB..."
MONGODB_ROOT_PASSWORD=$(kubectl get secret mongodb-shared -n askme-mongodb -o jsonpath='{.data.mongodb-root-password}' | base64 -d)

if [ -z "$MONGODB_ROOT_PASSWORD" ]; then
    echo "❌ Impossible de récupérer le mot de passe MongoDB"
    exit 1
fi

echo "✅ Mot de passe MongoDB récupéré"

# Mettre à jour ou créer le secret askme-local-tokens avec les clés MongoDB
echo "🔄 Mise à jour du secret askme-local-tokens..."

# Récupérer le secret existant s'il existe
SECRET_EXISTS=$(kubectl get secret askme-local-tokens -n $NAMESPACE --ignore-not-found=true)

if [ -z "$SECRET_EXISTS" ]; then
    echo "⚠️  Secret askme-local-tokens n'existe pas dans $NAMESPACE"
    echo "Créez-le d'abord avec vos clés API existantes"
    echo "Puis relancez ce script pour ajouter les clés MongoDB"
    exit 1
fi

# Créer un fichier temporaire avec les nouvelles variables MongoDB
cat > /tmp/mongodb-secrets.env << EOF
# MongoDB Configuration pour historique conversations
MONGODB_URI=mongodb://root:${MONGODB_ROOT_PASSWORD}@mongodb-external:27017/?replicaSet=rs0&readPreference=secondaryPreferred
MONGODB_DATABASE=askme_default
MONGODB_ENABLE_FEEDBACK=false
EOF

# Ajouter les variables MongoDB au secret existant
kubectl create secret generic askme-local-tokens-new \
  --from-env-file=/tmp/mongodb-secrets.env \
  --from-secret=askme-local-tokens \
  --namespace=$NAMESPACE \
  --dry-run=client -o yaml | kubectl apply -f -

# Renommer le secret (technique pour fusionner)
kubectl delete secret askme-local-tokens -n $NAMESPACE
kubectl patch secret askme-local-tokens-new -n $NAMESPACE -p '{"metadata":{"name":"askme-local-tokens"}}'

if [ $? -eq 0 ]; then
    echo "✅ Secret askme-local-tokens mis à jour avec les clés MongoDB"
    echo ""
    echo "🔍 Variables MongoDB ajoutées:"
    echo "   MONGODB_URI: mongodb://root:***@mongodb-external:27017/..."
    echo "   MONGODB_DATABASE: askme_default"
    echo "   MONGODB_ENABLE_FEEDBACK: false"
    echo ""
    echo "📋 Pour utiliser MongoDB avec un client:"
    echo "   ./deploy-client.sh <client> --mongodb"
else
    echo "❌ Échec de la mise à jour du secret"
    exit 1
fi

# Nettoyer le fichier temporaire
rm -f /tmp/mongodb-secrets.env

echo "✅ Mise à jour terminée!"
echo ""
echo "⚠️  IMPORTANT: Redémarrez les déploiements existants pour prendre en compte les nouvelles variables:"
echo "   kubectl rollout restart deployment -n $NAMESPACE"