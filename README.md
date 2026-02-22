# WSO2 Sandbox (MI + ICP) for Lakehouse Ingest Integrations

This repository runs:
- **WSO2 Micro Integrator (MI)** — integration runtime (APIs, transformations, routing)
- **WSO2 Integration Control Plane (ICP)** — web management GUI for MI runtime monitoring
- Optional: **WSO2 API Manager (API-M)** — API governance (separate compose file)

## What is NOT included here
**WSO2 Integration Studio** is a developer IDE (desktop application) used to build MI integrations and export `.car` files.
Install it on your workstation, not on the server.

## Prerequisites
- Ubuntu host with Docker + Docker Compose
- Ports open (at least): 9743, 8290, 8253

## Install & Run (Ubuntu)
Recommended folder: `/home/wso2`

```bash
sudo mkdir -p /home/wso2
sudo chown -R $USER:$USER /home/wso2
cd /home/wso2

git clone https://github.com/rg4444/wso2.git .
./scripts/install.sh
./scripts/up.sh
```

## Check status
```bash
./scripts/status.sh
```

## Logs
```bash
./scripts/logs.sh icp
./scripts/logs.sh mi
```

## Access
- ICP UI: https://<host>:9743/
- MI HTTP: http://<host>:8290/
- MI HTTPS: https://<host>:8253/

## Deploy integrations
Put exported `.car` files into:

```text
mi/carbonapps/
```

They will be hot-deployed into MI.

## Optional: start API Manager
```bash
docker compose -f docker-compose.yml -f docker-compose.apim.yml --env-file ./env/.env up -d
```

> NOTE: API Manager is optional. Start only if you need full API lifecycle/governance features.
