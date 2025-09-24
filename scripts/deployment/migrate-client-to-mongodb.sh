#!/bin/bash

# Script de migration CosmosDB vers MongoDB pour un client AskMe
# Usage: ./migrate-client-to-mongodb.sh <nom-client> [--dry-run]
# Exemple: ./migrate-client-to-mongodb.sh avanteam --dry-run

if [ -z "$1" ]; then
    echo "Usage: $0 <nom-client> [--dry-run]"
    echo "Exemple: $0 avanteam --dry-run"
    echo "Exemple: $0 avanteam"
    exit 1
fi

CLIENT_NAME="$1"
DRY_RUN=false

# Parse options
for arg in "$@"; do
    case $arg in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
    esac
done

echo "🔄 Migration CosmosDB vers MongoDB pour client: $CLIENT_NAME"
if [ "$DRY_RUN" = true ]; then
    echo "🧪 Mode DRY-RUN activé (pas de modifications)"
fi

# Vérifier les prérequis
echo "🔍 Vérification des prérequis..."

# 1. Vérifier que MongoDB est accessible
kubectl get pods -n askme-mongodb -l app.kubernetes.io/name=mongodb > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "❌ MongoDB pods non trouvés dans askme-mongodb namespace"
    exit 1
fi

# 2. Vérifier que le script Python de migration existe
MIGRATION_SCRIPT="../askme-app-aoai/scripts/migrate-cosmosdb-to-mongodb.py"
if [ ! -f "$MIGRATION_SCRIPT" ]; then
    echo "❌ Script de migration non trouvé: $MIGRATION_SCRIPT"
    echo "Copiez le script de migration depuis askme-app-aoai/scripts/"
    exit 1
fi

# 3. Vérifier les variables d'environnement nécessaires
if [ -z "$COSMOS_ENDPOINT" ] || [ -z "$COSMOS_KEY" ]; then
    echo "❌ Variables d'environnement manquantes:"
    echo "   COSMOS_ENDPOINT: URL CosmosDB"
    echo "   COSMOS_KEY: Clé d'accès CosmosDB"
    echo ""
    echo "💡 Définissez-les avec:"
    echo "   export COSMOS_ENDPOINT='https://your-cosmos.documents.azure.com:443/'"
    echo "   export COSMOS_KEY='your-cosmos-key'"
    exit 1
fi

# Configuration
DATABASE_NAME="askme_${CLIENT_NAME}"
COSMOS_DATABASE="db_conversation_history"
MONGODB_URI="mongodb://root:AskMe-MongoDB-2024-Secure!@mongodb-shared.askme-mongodb.svc.cluster.local:27017/?replicaSet=rs0&readPreference=secondaryPreferred"
REPORT_FILE="migration-${CLIENT_NAME}-$(date +%Y%m%d-%H%M%S).json"

echo "📋 Configuration de migration:"
echo "   Client: $CLIENT_NAME"
echo "   CosmosDB: $COSMOS_DATABASE"
echo "   MongoDB: $DATABASE_NAME"
echo "   Rapport: $REPORT_FILE"

# Port-forward vers MongoDB pour la migration
echo "🔌 Configuration du port-forward vers MongoDB..."
kubectl port-forward -n askme-mongodb service/mongodb-shared 27017:27017 &
PORT_FORWARD_PID=$!

# Attendre que le port-forward soit prêt
sleep 5

# Fonction de nettoyage
cleanup() {
    echo "🧹 Nettoyage..."
    kill $PORT_FORWARD_PID 2>/dev/null
    wait $PORT_FORWARD_PID 2>/dev/null
}

# Trap pour nettoyer même en cas d'interruption
trap cleanup EXIT

# Préparer les arguments de migration
MIGRATION_ARGS="--cosmos-endpoint '$COSMOS_ENDPOINT' --cosmos-key '$COSMOS_KEY' --cosmos-database '$COSMOS_DATABASE' --mongo-uri 'mongodb://root:AskMe-MongoDB-2024-Secure!@localhost:27017/?replicaSet=rs0&readPreference=secondaryPreferred' --mongo-database '$DATABASE_NAME' --report '$REPORT_FILE'"

if [ "$DRY_RUN" = true ]; then
    MIGRATION_ARGS="$MIGRATION_ARGS --dry-run"
fi

# Lancer la migration
echo "🚀 Démarrage de la migration..."
cd "$(dirname "$MIGRATION_SCRIPT")"

python3 migrate-cosmosdb-to-mongodb.py \
    --cosmos-endpoint "$COSMOS_ENDPOINT" \
    --cosmos-key "$COSMOS_KEY" \
    --cosmos-database "$COSMOS_DATABASE" \
    --mongo-uri "mongodb://root:AskMe-MongoDB-2024-Secure!@localhost:27017/?replicaSet=rs0&readPreference=secondaryPreferred" \
    --mongo-database "$DATABASE_NAME" \
    --report "../../askme-rancher-catalog/$REPORT_FILE" \
    $([ "$DRY_RUN" = true ] && echo "--dry-run")

MIGRATION_STATUS=$?

# Retourner au répertoire original
cd - > /dev/null

if [ $MIGRATION_STATUS -eq 0 ]; then
    if [ "$DRY_RUN" = true ]; then
        echo "✅ Migration DRY-RUN terminée avec succès!"
        echo "📊 Consultez le rapport: $REPORT_FILE"
        echo ""
        echo "🔄 Pour effectuer la migration réelle:"
        echo "   $0 $CLIENT_NAME"
    else
        echo "✅ Migration terminée avec succès!"
        echo "📊 Consultez le rapport: $REPORT_FILE"
        echo ""
        echo "🔄 Prochaines étapes:"
        echo "1. Vérifiez les données migrées"
        echo "2. Configurez HISTORY_PROVIDER=MONGODB"
        echo "3. Redémarrez l'application"
        echo "4. Testez le bon fonctionnement"
    fi
else
    echo "❌ Migration échouée (code: $MIGRATION_STATUS)"
    echo "📊 Consultez le rapport d'erreur: $REPORT_FILE"
fi

exit $MIGRATION_STATUS