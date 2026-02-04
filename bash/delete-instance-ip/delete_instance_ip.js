#!/usr/bin/env node

const { execSync } = require('child_process');

function deleteInstanceIp(ipAddress) {
    const result = execSync('ibmcloud is instances --output json', { encoding: 'utf8' });
    const instances = JSON.parse(result);
    
    const vsiId = instances.find(i => 
        i.primary_network_interface?.primary_ip?.address === ipAddress
    )?.id;
    
    if (!vsiId) {
        console.log(`❌ Error: No Virtual Server found with IP Address: ${ipAddress}`);
        return 1;
    }
    
    console.log(`Found Virtual Server ID: ${vsiId}`);
    console.log(`Deleting VSI ${vsiId}`);
    execSync(`ibmcloud is instance-delete ${vsiId} --force`);
    console.log(`✅ VSI ${vsiId} deletion initiated.`);
    return 0;
}

process.exit(process.argv.length === 3 ? deleteInstanceIp(process.argv[2]) : 1);