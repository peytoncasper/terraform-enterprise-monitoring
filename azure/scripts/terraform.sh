#!/bin/bash

cat << EOF | sudo tee -a /etc/application.json
{
    "hostname": {
        "value": "${PUBLIC_IP_ADDRESS}"
    },
    "installation_type": {
        "value": "production"
    },
    "enc_password": {
        "value": "${ENCRYPTION_PASSWORD}"
    },
    "production_type": {
        "value": "external"
    },
    "pg_dbname": {
        "value": "${PG_DB_NAME}"
    },
    "pg_netloc": {
        "value": "${PG_ENDPOINT}:5432"
    },
    "pg_password": {
        "value": "${PG_PASSWORD}"
    },
    "pg_user": {
        "value": "${PG_USERNAME}"
    },
    "placement": {
        "value": "placement_azure"
    },
    "azure_account_key": {
        "value": "${AZURE_ACCOUNT_KEY}"
    },
    "azure_account_name": {
        "value": "${AZURE_ACCOUNT_NAME}"
    },
    "azure_container": {
        "value": "${AZURE_CONTAINER}"
    }
}
EOF

cat << EOF | sudo tee -a /etc/license.rli
${LICENSE}
EOF

cat << EOF | sudo tee -a /etc/replicated.conf
{
    "DaemonAuthenticationType":     "password",
    "DaemonAuthenticationPassword": "${ENCRYPTION_PASSWORD}",
    "TlsBootstrapType":             "server-path",
    "TlsBootstrapHostname":         "${PUBLIC_IP_ADDRESS}",
    "TlsBootstrapCert":             "/etc/server.crt",
    "TlsBootstrapKey":              "/etc/server.key",
    "BypassPreflightChecks":        true,
    "ImportSettingsFrom":           "/etc/application.json",
    "LicenseFileLocation":          "/etc/license.rli"
}
EOF

curl -o install.sh https://install.terraform.io/ptfe/stable

bash ./install.sh \
    no-proxy \
    private-address=${PRIVATE_IP_ADDRESS} \
    public-address=${PUBLIC_IP_ADDRESS}

sudo docker run --privileged -d -v /var/run/docker.sock:/var/run/docker.sock -v /var/log:/var/log -v /var/lib/docker/containers:/var/lib/docker/containers -e WSID="${WORKSPACE_ID}" -e KEY="${WORKSPACE_KEY}" -p 127.0.0.1:25227:25225 -p 127.0.0.1:25226:25224/udp --name="omsagent" -h=`hostname` --restart=always microsoft/oms