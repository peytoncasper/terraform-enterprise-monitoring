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
        "value": "placement_gcs"
    },
    "gcs_credentials": {
        "value": "${GCS_CREDENTIALS}"
    },
    "gcs_project": {
        "value": "${GCS_PROJECT}"
    },
    "gcs_bucket": {
        "value": "${GCS_BUCKET}"
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

# sudo sed -i '/#module(load="imtcp")/c\module(load="imtcp")' /etc/rsyslog.conf
# sudo sed -i '/#input(type="imtcp" port="514")/c\input(type="imtcp" port="514")' /etc/rsyslog.conf

# sudo systemctl restart rsyslog

# sudo docker run --name="logspout" \
#   --volume=/var/run/docker.sock:/var/run/docker.sock \
#   gliderlabs/logspout \
#   syslog+tls://${PRIVATE_IP_ADDRESS}:514


# curl -sSO https://dl.google.com/cloudagents/add-monitoring-agent-repo.sh
# sudo bash add-monitoring-agent-repo.sh
# sudo apt-get update
# sudo apt-get install -y stackdriver-agent
# sudo service stackdriver-agent start


# docker run --name="logspout" \
# 	--volume=/var/run/docker.sock:/var/run/docker.sock \
# 	gliderlabs/logspout \
# 	syslog+tls://localhost:5140