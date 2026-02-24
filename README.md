# WSO2 Sandbox (MI + ICP) for Lakehouse Ingest Integrations

This repository runs:
- **WSO2 Micro Integrator (MI)** — integration runtime (APIs, transformations, routing)
- **WSO2 Integration Control Plane (ICP)** — web management GUI for MI runtime monitoring
- Optional: **WSO2 API Manager (API-M)** — API governance (enabled by env flag)

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

## Run everything (MI + ICP + APIM)
```bash
./scripts/install.sh
./scripts/restart.sh
```

To disable APIM, set `ENABLE_APIM=0` in `env/.env`.

## Check status
```bash
./scripts/status.sh
```

## Logs
```bash
./scripts/logs.sh icp
./scripts/logs.sh mi
./scripts/logs.sh apim
```

## Access
- ICP UI: https://<host>:9743/
- MI HTTP: http://<host>:8290/
- MI HTTPS: https://<host>:8253/
- API-M Publisher: https://localhost:${APIM_HTTPS_PORT}/publisher
- API-M Devportal: https://localhost:${APIM_HTTPS_PORT}/devportal
- API-M Gateway HTTP: http://localhost:${APIM_GW_HTTP_PORT}/
- API-M Gateway HTTPS: https://localhost:${APIM_GW_HTTPS_PORT}/

## Deploy integrations
Put exported `.car` files into:

```text
mi/carbonapps/
```

They will be hot-deployed into MI.
