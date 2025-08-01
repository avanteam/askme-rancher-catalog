#!/usr/bin/env python3
"""
OVH DNS Manager - Gestion automatique des entrées DNS pour AskMe
Crée automatiquement les sous-domaines clients dans la zone avanteam-saas.com
"""
import requests
import json
import time
import hashlib
import os
import sys
from typing import Dict, List, Optional

class OVHDNSManager:
    """Gestionnaire DNS OVH pour la création automatique de sous-domaines clients"""
    
    def __init__(self, app_key: str, app_secret: str, consumer_key: str, endpoint: str = "ovh-eu"):
        self.app_key = app_key
        self.app_secret = app_secret
        self.consumer_key = consumer_key
        self.endpoint = endpoint
        
        # Endpoints API selon la région
        self.api_endpoints = {
            "ovh-eu": "https://eu.api.ovh.com/1.0",
            "ovh-ca": "https://ca.api.ovh.com/1.0",
            "ovh-us": "https://api.us.ovhcloud.com/1.0"
        }
        
        self.base_url = self.api_endpoints.get(endpoint, self.api_endpoints["ovh-eu"])
        
    def _generate_signature(self, method: str, url: str, body: str, timestamp: str) -> str:
        """Génère la signature OVH pour l'authentification"""
        raw_data = f"{self.app_secret}+{self.consumer_key}+{method}+{url}+{body}+{timestamp}"
        return "$1$" + hashlib.sha1(raw_data.encode()).hexdigest()
    
    def _make_request(self, method: str, path: str, data: Optional[Dict] = None) -> Dict:
        """Effectue une requête authentifiée vers l'API OVH"""
        url = f"{self.base_url}{path}"
        timestamp = str(int(time.time()))
        body = json.dumps(data) if data else ""
        
        signature = self._generate_signature(method, url, body, timestamp)
        
        headers = {
            "X-Ovh-Application": self.app_key,
            "X-Ovh-Consumer": self.consumer_key,
            "X-Ovh-Timestamp": timestamp,
            "X-Ovh-Signature": signature,
            "Content-Type": "application/json"
        }
        
        response = requests.request(method, url, headers=headers, data=body)
        
        if response.status_code not in [200, 201]:
            raise Exception(f"Erreur API OVH {response.status_code}: {response.text}")
            
        return response.json() if response.text else {}
    
    def list_dns_records(self, zone: str, subdomain: Optional[str] = None) -> List[Dict]:
        """Liste les enregistrements DNS d'une zone"""
        params = f"?fieldType=A" + (f"&subDomain={subdomain}" if subdomain else "")
        records_ids = self._make_request("GET", f"/domain/zone/{zone}/record{params}")
        
        records = []
        for record_id in records_ids:
            record = self._make_request("GET", f"/domain/zone/{zone}/record/{record_id}")
            records.append(record)
            
        return records
    
    def create_dns_record(self, zone: str, subdomain: str, target_ip: str, ttl: int = 300) -> Dict:
        """Crée un enregistrement DNS de type A"""
        data = {
            "fieldType": "A",
            "subDomain": subdomain,
            "target": target_ip,
            "ttl": ttl
        }
        
        print(f"🌐 Création entrée DNS: {subdomain}.{zone} -> {target_ip}")
        record = self._make_request("POST", f"/domain/zone/{zone}/record", data)
        
        # Appliquer les changements
        self._make_request("POST", f"/domain/zone/{zone}/refresh")
        print(f"✅ DNS mis à jour et propagé")
        
        return record
    
    def delete_dns_record(self, zone: str, record_id: int) -> None:
        """Supprime un enregistrement DNS"""
        print(f"🗑️ Suppression entrée DNS ID: {record_id}")
        self._make_request("DELETE", f"/domain/zone/{zone}/record/{record_id}")
        
        # Appliquer les changements
        self._make_request("POST", f"/domain/zone/{zone}/refresh")
        print(f"✅ Entrée DNS supprimée et propagée")
    
    def update_client_dns(self, zone: str, client_name: str, target_ip: str, action: str = "create") -> Dict:
        """Met à jour l'entrée DNS d'un client (create/delete)"""
        subdomain = client_name.lower().replace("_", "-")
        
        # Vérifier si l'entrée existe déjà
        existing_records = self.list_dns_records(zone, subdomain)
        
        if action == "create":
            if existing_records:
                print(f"⚠️ Entrée DNS {subdomain}.{zone} existe déjà")
                return existing_records[0]
            else:
                return self.create_dns_record(zone, subdomain, target_ip)
                
        elif action == "delete":
            if existing_records:
                for record in existing_records:
                    self.delete_dns_record(zone, record["id"])
                return {"status": "deleted", "count": len(existing_records)}
            else:
                print(f"⚠️ Aucune entrée DNS {subdomain}.{zone} à supprimer")
                return {"status": "not_found"}
        
        else:
            raise ValueError(f"Action non supportée: {action}")


def main():
    """Fonction principale - Interface CLI"""
    import argparse
    
    parser = argparse.ArgumentParser(description="Gestionnaire DNS OVH pour AskMe")
    parser.add_argument("--action", choices=["create", "delete", "list"], required=True,
                       help="Action à effectuer")
    parser.add_argument("--zone", default="avanteam-saas.com",
                       help="Zone DNS à gérer")
    parser.add_argument("--client", 
                       help="Nom du client (pour create/delete)")
    parser.add_argument("--ip", 
                       help="IP cible (pour create)")
    parser.add_argument("--app-key", 
                       help="OVH Application Key")
    parser.add_argument("--app-secret", 
                       help="OVH Application Secret")
    parser.add_argument("--consumer-key", 
                       help="OVH Consumer Key")
    
    args = parser.parse_args()
    
    # Récupérer les credentials depuis les variables d'environnement ou arguments
    app_key = args.app_key or os.getenv("OVH_APP_KEY")
    app_secret = args.app_secret or os.getenv("OVH_APP_SECRET")
    consumer_key = args.consumer_key or os.getenv("OVH_CONSUMER_KEY")
    
    if not all([app_key, app_secret, consumer_key]):
        print("❌ Erreur: Credentials OVH manquants")
        print("Définissez: OVH_APP_KEY, OVH_APP_SECRET, OVH_CONSUMER_KEY")
        sys.exit(1)
    
    try:
        dns_manager = OVHDNSManager(app_key, app_secret, consumer_key)
        
        if args.action == "list":
            records = dns_manager.list_dns_records(args.zone)
            print(f"📋 Enregistrements DNS pour {args.zone}:")
            for record in records:
                print(f"  - {record['subDomain']}.{args.zone} -> {record['target']} (TTL: {record['ttl']})")
        
        elif args.action == "create":
            if not args.client or not args.ip:
                print("❌ Erreur: --client et --ip requis pour create")
                sys.exit(1)
                
            result = dns_manager.update_client_dns(args.zone, args.client, args.ip, "create")
            print(f"🎉 Succès: {args.client}.{args.zone} créé")
            
        elif args.action == "delete":
            if not args.client:
                print("❌ Erreur: --client requis pour delete")
                sys.exit(1)
                
            result = dns_manager.update_client_dns(args.zone, args.client, "", "delete")
            print(f"🗑️ Succès: {args.client}.{args.zone} supprimé")
            
    except Exception as e:
        print(f"❌ Erreur: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()