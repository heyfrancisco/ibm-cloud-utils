#!/usr/bin/env python3

from typing import Any, Literal
from subprocess import CompletedProcess
import subprocess
import json
import sys

def delete_instance_ip(ip_address) -> Literal[1, 0]:
    result: CompletedProcess[str] = subprocess.run(
        ['ibmcloud', 'is', 'instances', '--output', 'json'],
        capture_output=True,
        text=True
    )
    
    instances = json.loads(s=result.stdout)
    vsi_id: Any | None = next(
        (i['id'] for i in instances 
         if i.get('primary_network_interface', {}).get('primary_ip', {}).get('address') == ip_address),
        None
    )
    
    if not vsi_id:
        print(f"❌ Error: No Virtual Server found with IP Address: {ip_address}")
        return 1
    
    print(f"Found Virtual Server ID: {vsi_id}")
    print(f"Deleting VSI {vsi_id}")
    subprocess.run(['ibmcloud', 'is', 'instance-delete', vsi_id, '--force'])
    print(f"✅ VSI {vsi_id} deletion initiated.")
    return 0

if __name__ == "__main__":
    sys.exit(delete_instance_ip(ip_address=sys.argv[1]) if len(sys.argv) == 2 else 1)