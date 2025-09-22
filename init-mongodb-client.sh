#!/bin/bash

# Script d'initialisation MongoDB pour un client AskMe
# Usage: ./init-mongodb-client.sh <nom-client>
# Exemple: ./init-mongodb-client.sh avanteam

if [ -z "$1" ]; then
    echo "Usage: $0 <nom-client>"
    echo "Exemple: $0 avanteam"
    exit 1
fi

CLIENT_NAME="$1"
DATABASE_NAME="askme_${CLIENT_NAME}"
USERNAME="askme_${CLIENT_NAME}_user"
PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)

echo "🍃 Initialisation MongoDB pour client: $CLIENT_NAME"
echo "📦 Base de données: $DATABASE_NAME"
echo "👤 Utilisateur: $USERNAME"

# Vérifier que MongoDB est accessible
echo "🔍 Vérification de MongoDB..."
kubectl get pods -n askme-mongodb -l app.kubernetes.io/name=mongodb > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "❌ MongoDB pods non trouvés dans askme-mongodb namespace"
    exit 1
fi

# Obtenir le nom du pod MongoDB primary
MONGODB_POD=$(kubectl get pods -n askme-mongodb -l app.kubernetes.io/name=mongodb,app.kubernetes.io/component=mongodb -o jsonpath='{.items[0].metadata.name}')
if [ -z "$MONGODB_POD" ]; then
    echo "❌ Impossible de trouver le pod MongoDB"
    exit 1
fi

echo "🔧 Pod MongoDB trouvé: $MONGODB_POD"

# Créer le script d'initialisation MongoDB
cat > /tmp/init-${CLIENT_NAME}.js << EOF
// Initialisation MongoDB pour client ${CLIENT_NAME}
use ${DATABASE_NAME};

// Créer l'utilisateur pour ce client
db.createUser({
  user: "${USERNAME}",
  pwd: "${PASSWORD}",
  roles: [
    {
      role: "readWrite",
      db: "${DATABASE_NAME}"
    }
  ]
});

// Créer les collections avec index optimisés
db.createCollection("conversations");
db.createCollection("messages");

// Index pour conversations
db.conversations.createIndex({"userId": 1, "updatedAt": -1});
db.conversations.createIndex({"id": 1}, {"unique": true});

// Index pour messages
db.messages.createIndex({"conversationId": 1, "timestamp": 1});
db.messages.createIndex({"id": 1}, {"unique": true});

// Vérification
print("✅ Database ${DATABASE_NAME} initialisée");
print("✅ Utilisateur ${USERNAME} créé");
print("✅ Collections et index créés");
EOF

# Copier le script dans le pod et l'exécuter
echo "🚀 Exécution du script d'initialisation..."
kubectl cp /tmp/init-${CLIENT_NAME}.js askme-mongodb/${MONGODB_POD}:/tmp/init-${CLIENT_NAME}.js

kubectl exec -n askme-mongodb ${MONGODB_POD} -- mongosh --eval "load('/tmp/init-${CLIENT_NAME}.js')"

if [ $? -eq 0 ]; then
    echo "✅ Initialisation MongoDB réussie pour $CLIENT_NAME"
    echo ""
    echo "📋 Informations de connexion:"
    echo "Database: $DATABASE_NAME"
    echo "Username: $USERNAME"
    echo "Password: $PASSWORD"
    echo ""
    echo "🔗 URI de connexion:"
    echo "mongodb://${USERNAME}:${PASSWORD}@mongodb-external:27017/${DATABASE_NAME}?replicaSet=rs0&readPreference=secondaryPreferred"
else
    echo "❌ Échec de l'initialisation MongoDB"
    exit 1
fi

# Nettoyer le fichier temporaire
rm -f /tmp/init-${CLIENT_NAME}.js

echo ""
echo "⚠️  IMPORTANT: Sauvegardez ces informations de connexion!"
echo "💾 Vous pouvez les utiliser dans votre values.yaml:"
echo ""
echo "mongodb:"
echo "  enabled: true"
echo "  uri: \"mongodb://${USERNAME}:${PASSWORD}@mongodb-external:27017/${DATABASE_NAME}?replicaSet=rs0&readPreference=secondaryPreferred\""
echo "  database: \"${DATABASE_NAME}\""