![Image of Azure Montior Tracking the Metrics Below](../docs/azure.png)

# Installation


# Log Collection

## Docker Version of the OMS Agent

Terraform Enterprise runs entirely on docker containers and as a result, the easiest OMS Agent to utilize is the Docker variant as it is able to tap directly into the Docker logs rather than having to watch the container log files on disk. If you're looking to replicate this in your own environment, the command below details how to start the OMS agent container. There are two parameters required for the OMS agent to function and that is the Log Analytics Workspace ID and Workspace Key which can be pulled from the Azure UI or CLI.

```
sudo docker run --privileged -d -v /var/run/docker.sock:/var/run/docker.sock -v /var/log:/var/log -v /var/lib/docker/containers:/var/lib/docker/containers -e WSID="${WORKSPACE_ID}" -e KEY="${WORKSPACE_KEY}" -p 127.0.0.1:25225:25225 -p 127.0.0.1:25224:25224/udp --name="omsagent" -h=`hostname` --restart=always microsoft/oms
```

# Metrics

- Host CPU
- Host Memory
- Host Disk
- Containers CPU

```
Perf
| make-series avgif(CounterValue, CounterName == "% Processor Time"), default=0 on TimeGenerated from ago(3h) to now() step 20m by InstanceName
```

- Containers RAM

```
Perf
| make-series avgif(CounterValue, CounterName == "Memory Usage MB"), default=0 on TimeGenerated from ago(3h) to now() step 20m by InstanceName
```

- Errors over time

```
ContainerLog
| where Name == "replicated" and LogEntry contains "ERROR" or 
    Name == "replicated-premkit" and LogEntry contains "level=error" or 
    Name == "replicated-ui" and LogEntry contains "ERROR" or
    Name == "retraced-api" and LogEntry contains "\\\"level\\\":40" or
    Name == "retraced-processor" and LogEntry contains "\\\"level\\\":40" or
    Name == "replicated-statsd" and LogEntry contains "[ERROR]" or
    Name == "replicated-operator" and LogEntry contains "ERROR" or
    Name == "influxdb" and LogEntry contains "HTTP/1.1\\\" 500" or
    Name == "ptfe_ingress" and LogEntry contains "\\\"error\\\"" or
    Name == "ptfe_redis" and LogEntry contains "ERROR" or
    Name == "ptfe_state_parser" and LogEntry contains "[ERROR]" or
    Name == "rabbitmq" and LogEntry contains "[error]" or
    Name == "ptfe_backup_restore" and LogEntry contains "Error" or
    Name == "ptfe-health-check" and LogEntry contains "[ERROR]" or
    Name == "ptfe_nomad" and LogEntry contains "[ERROR]" or
    Name == "telegraf" and LogEntry contains "Error" or
    Name == "ptfe_nginx" and LogEntry contains "HTTP/1.1\\\" 500" or
    Name == "ptfe_vault" and LogEntry contains "[ERROR]" or
    Name == "ptfe_build_manager" and LogEntry contains "[ERROR]" or
    Name == "ptfe_archivist" and LogEntry contains "[ERROR]" or
    Name == "ptfe_sidekiq" and LogEntry contains "[ERROR]" or
    Name == "ptfe_atlas" and LogEntry contains "[ERROR]" or
    Name == "ptfe_registry_worker" and LogEntry contains "[ERROR]" or
    Name == "ptfe_registry_api" and LogEntry contains "[ERROR]"
| make-series count(), default=0 on TimeGenerated from ago(24h) to now() step 20m by Name
```

- Number of Active Workers

```
ContainerServiceLog
| where Image == "hashicorp/build-worker:now"
| make-series dcountif(ContainerID, Command != "destroy"), default=0 on TimeOfCommand from ago(5h) to now() step 1m
```

- Terraform Healthcheck

[Healtcheck Endpoint](https://www.terraform.io/docs/enterprise/admin/monitoring.html#health-check)

- SQL Healthcheck

Active vs. Failed Connections

- Blob Storage Healthcheck

Availability Chart

- Vault Healthcheck (Optional)