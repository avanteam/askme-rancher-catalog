#!/bin/bash
# Script de test pour valider le déploiement multi-tenant MongoDB

set -e

RELEASE_NAME="${1:-askme-test}"
NAMESPACE="${2:-askme-test}"

echo "🚀 Test du déploiement multi-tenant MongoDB"
echo "==========================================="
echo "Release Name: $RELEASE_NAME"
echo "Namespace: $NAMESPACE"
echo ""

# Vérifier que le namespace existe
echo "📋 1. Vérification du namespace..."
if kubectl get namespace "$NAMESPACE" > /dev/null 2>&1; then
    echo "✅ Namespace $NAMESPACE trouvé"
else
    echo "❌ Namespace $NAMESPACE non trouvé"
    exit 1
fi

# Vérifier le job d'initialisation MongoDB
echo ""
echo "📋 2. Vérification du job d'initialisation MongoDB..."
JOB_NAME="${RELEASE_NAME}-mongodb-init"
if kubectl get job "$JOB_NAME" -n "$NAMESPACE" > /dev/null 2>&1; then
    echo "✅ Job $JOB_NAME trouvé"

    JOB_STATUS=$(kubectl get job "$JOB_NAME" -n "$NAMESPACE" -o jsonpath='{.status.conditions[?(@.type=="Complete")].status}')
    if [ "$JOB_STATUS" = "True" ]; then
        echo "✅ Job terminé avec succès"
    else
        echo "⚠️  Job en cours ou échoué - vérifier les logs:"
        echo "   kubectl logs job/$JOB_NAME -n $NAMESPACE"
    fi
else
    echo "❌ Job d'initialisation MongoDB non trouvé"
fi

# Vérifier le secret MongoDB
echo ""
echo "📋 3. Vérification du secret MongoDB..."
SECRET_NAME="${RELEASE_NAME}-mongodb-credentials"
if kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" > /dev/null 2>&1; then
    echo "✅ Secret $SECRET_NAME trouvé"

    # Vérifier les clés du secret
    KEYS=$(kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" -o jsonpath='{.data}' | jq -r 'keys[]' 2>/dev/null || echo "")
    if [[ $KEYS == *"MONGODB_URI"* ]] && [[ $KEYS == *"MONGODB_DATABASE"* ]]; then
        echo "✅ Secret contient les clés nécessaires"
    else
        echo "⚠️  Secret incomplet - clés trouvées: $KEYS"
    fi
else
    echo "❌ Secret MongoDB non trouvé"
fi

# Vérifier le service MongoDB externe
echo ""
echo "📋 4. Vérification du service MongoDB externe..."
SERVICE_NAME="mongodb-external"
if kubectl get service "$SERVICE_NAME" -n "$NAMESPACE" > /dev/null 2>&1; then
    echo "✅ Service $SERVICE_NAME trouvé"

    SERVICE_TYPE=$(kubectl get service "$SERVICE_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.type}')
    if [ "$SERVICE_TYPE" = "ExternalName" ]; then
        echo "✅ Service de type ExternalName correct"
        EXTERNAL_NAME=$(kubectl get service "$SERVICE_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.externalName}')
        echo "   → Pointe vers: $EXTERNAL_NAME"
    else
        echo "⚠️  Service n'est pas de type ExternalName"
    fi
else
    echo "❌ Service MongoDB externe non trouvé"
fi

# Vérifier le déploiement de l'application
echo ""
echo "📋 5. Vérification du déploiement de l'application..."
DEPLOYMENT_NAME="$RELEASE_NAME"
if kubectl get deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" > /dev/null 2>&1; then
    echo "✅ Deployment $DEPLOYMENT_NAME trouvé"

    REPLICAS_READY=$(kubectl get deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" -o jsonpath='{.status.readyReplicas}')
    REPLICAS_DESIRED=$(kubectl get deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.replicas}')

    if [ "$REPLICAS_READY" = "$REPLICAS_DESIRED" ]; then
        echo "✅ Deployment prêt ($REPLICAS_READY/$REPLICAS_DESIRED replicas)"
    else
        echo "⚠️  Deployment pas complètement prêt ($REPLICAS_READY/$REPLICAS_DESIRED replicas)"
        echo "   Vérifier les logs: kubectl logs deployment/$DEPLOYMENT_NAME -n $NAMESPACE"
    fi
else
    echo "❌ Deployment de l'application non trouvé"
fi

# Test de connectivité MongoDB depuis un pod de test
echo ""
echo "📋 6. Test de connectivité MongoDB..."

# Créer un pod de test temporaire
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: mongodb-test-${RELEASE_NAME}
  namespace: ${NAMESPACE}
  labels:
    app: mongodb-test
    test-for: ${RELEASE_NAME}
spec:
  restartPolicy: Never
  containers:
  - name: mongodb-test
    image: mongo:7.0
    command:
    - /bin/bash
    - -c
    - |
      # Récupérer les credentials depuis le secret
      MONGODB_URI=\$(cat /etc/mongodb-credentials/MONGODB_URI)
      MONGODB_DATABASE=\$(cat /etc/mongodb-credentials/MONGODB_DATABASE)

      echo "🔍 Test de connexion MongoDB..."
      echo "Database: \$MONGODB_DATABASE"

      # Test de connexion simple
      if mongosh "\$MONGODB_URI" --eval "db.runCommand({ping: 1})" --quiet; then
        echo "✅ Connexion MongoDB réussie"

        # Test des collections
        COLLECTIONS=\$(mongosh "\$MONGODB_URI" --eval "db.listCollections().forEach(c => print(c.name))" --quiet)
        echo "Collections trouvées: \$COLLECTIONS"

        if [[ \$COLLECTIONS == *"conversations"* ]] && [[ \$COLLECTIONS == *"messages"* ]]; then
          echo "✅ Collections conversations et messages présentes"
        else
          echo "⚠️  Collections manquantes"
        fi

        exit 0
      else
        echo "❌ Connexion MongoDB échouée"
        exit 1
      fi
    volumeMounts:
    - name: mongodb-credentials
      mountPath: /etc/mongodb-credentials
      readOnly: true
  volumes:
  - name: mongodb-credentials
    secret:
      secretName: ${SECRET_NAME}
EOF

echo "⏳ Attente du test de connectivité..."
kubectl wait --for=condition=Ready pod/mongodb-test-${RELEASE_NAME} -n ${NAMESPACE} --timeout=60s > /dev/null 2>&1 || true

# Récupérer les logs du test
echo ""
if kubectl logs pod/mongodb-test-${RELEASE_NAME} -n ${NAMESPACE} 2>/dev/null; then
    TEST_EXIT_CODE=$(kubectl get pod mongodb-test-${RELEASE_NAME} -n ${NAMESPACE} -o jsonpath='{.status.containerStatuses[0].state.terminated.exitCode}' 2>/dev/null || echo "")
    if [ "$TEST_EXIT_CODE" = "0" ]; then
        echo "✅ Test de connectivité réussi"
    else
        echo "❌ Test de connectivité échoué"
    fi
else
    echo "⚠️  Impossible de récupérer les logs du test"
fi

# Nettoyage du pod de test
kubectl delete pod mongodb-test-${RELEASE_NAME} -n ${NAMESPACE} --ignore-not-found=true > /dev/null 2>&1

# Résumé final
echo ""
echo "📋 RÉSUMÉ DU TEST"
echo "================="
echo "Client: $RELEASE_NAME"
echo "Namespace: $NAMESPACE"
echo "Database MongoDB: askme_$(echo $RELEASE_NAME | sed 's/askme-//' | sed 's/\./_/g')"
echo ""
echo "Pour accéder aux logs:"
echo "  kubectl logs job/${JOB_NAME} -n ${NAMESPACE}"
echo "  kubectl logs deployment/${DEPLOYMENT_NAME} -n ${NAMESPACE}"
echo ""
echo "Pour voir la configuration:"
echo "  kubectl get secret ${SECRET_NAME} -n ${NAMESPACE} -o yaml"
echo ""
echo "🎉 Test terminé!"