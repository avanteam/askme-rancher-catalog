#!/bin/bash

# Script de déploiement multi-client AskMe avec support MongoDB
# Usage: ./deploy-client.sh <nom-client> [OPTIONS]
# Exemple: ./deploy-client.sh rh
# Exemple: ./deploy-client.sh rh --mongodb

if [ -z "$1" ]; then
    echo "Usage: $0 <nom-client> [OPTIONS]"
    echo "Exemple: $0 rh"
    echo "Exemple: $0 rh --mongodb      # Utiliser MongoDB au lieu de CosmosDB"
    exit 1
fi

CLIENT_NAME="askme-$1"
NAMESPACE="askme-platform"
USE_MONGODB=false

# Parse options
for arg in "$@"; do
    case $arg in
        --mongodb)
            USE_MONGODB=true
            shift
            ;;
    esac
done

echo "🚀 Déploiement du client: $CLIENT_NAME"
echo "📦 Namespace: $NAMESPACE"
if [ "$USE_MONGODB" = true ]; then
    echo "🍃 Provider historique: MongoDB"
else
    echo "🌐 Provider historique: CosmosDB"
fi

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

# Si MongoDB est demandé, vérifier que MongoDB est disponible
if [ "$USE_MONGODB" = true ]; then
    echo "🔍 Vérification de MongoDB..."
    kubectl get service mongodb-shared -n askme-mongodb > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "❌ MongoDB service non trouvé dans askme-mongodb namespace"
        echo "Installez MongoDB d'abord: helm install mongodb-shared bitnami/mongodb --namespace askme-mongodb --create-namespace"
        exit 1
    fi

    # Vérifier que les secrets MongoDB sont configurés
    echo "🔐 Vérification des secrets MongoDB..."
    kubectl get secret askme-local-tokens -n $NAMESPACE -o jsonpath='{.data.MONGODB_URI}' > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "⚠️  Secrets MongoDB manquants dans askme-local-tokens"
        echo "Exécutez d'abord: ./update-mongodb-secrets.sh $NAMESPACE"
        read -p "Voulez-vous mettre à jour les secrets maintenant? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            ./update-mongodb-secrets.sh $NAMESPACE
            if [ $? -ne 0 ]; then
                echo "❌ Échec de la mise à jour des secrets"
                exit 1
            fi
        else
            echo "❌ Secrets MongoDB requis pour continuer"
            exit 1
        fi
    fi

    # Initialiser la database MongoDB pour ce client si nécessaire
    echo "🔧 Initialisation database MongoDB pour $CLIENT_NAME..."
    CLIENT_SHORT_NAME=$(echo $1 | sed 's/askme-//g')
    DATABASE_NAME="askme_${CLIENT_SHORT_NAME}"

    # Exécuter le script d'initialisation MongoDB
    echo "📦 Database MongoDB: $DATABASE_NAME"
    ./init-mongodb-client.sh $CLIENT_SHORT_NAME
    if [ $? -ne 0 ]; then
        echo "⚠️  Initialisation MongoDB échouée, mais déploiement continue..."
        echo "Vous pourrez initialiser manuellement plus tard"
    fi
fi

# Préparer les paramètres Helm
HELM_ARGS="--namespace $NAMESPACE --set client.name=$CLIENT_NAME --set client.namespace=$NAMESPACE"

if [ "$USE_MONGODB" = true ]; then
    HELM_ARGS="$HELM_ARGS --set mongodb.enabled=true --set config.historyProvider=MONGODB"
else
    HELM_ARGS="$HELM_ARGS --set mongodb.enabled=false --set config.historyProvider=COSMOSDB"
fi

# Déployer avec Helm
echo "🚀 Déploiement avec Helm..."
helm install $CLIENT_NAME ./charts/askme $HELM_ARGS

if [ $? -eq 0 ]; then
    echo "✅ Client $CLIENT_NAME déployé avec succès!"
    echo "🌐 Vérifiez: kubectl get pods -n $NAMESPACE -l app.kubernetes.io/instance=$CLIENT_NAME"

    if [ "$USE_MONGODB" = true ]; then
        echo "🍃 MongoDB configuré pour ce client"
        echo "📦 Service ExternalName créé: mongodb-external"
        echo "🔐 Secret MongoDB créé: mongodb-credentials"
    fi
else
    echo "❌ Échec du déploiement"
    exit 1
fi