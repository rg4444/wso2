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

`./scripts/install.sh` now keeps `env/.env` in sync by appending any missing variables from `env/.env.example` without overwriting your existing values.

## Run everything (MI + ICP + APIM)
```bash
./scripts/install.sh
./scripts/restart.sh
```

Set `ENABLE_APIM=1` in `env/.env` to include API-M in the one-command `./scripts/restart.sh` flow.
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
- API-M Publisher (HTTP UI mode): http://<APIM_PUBLIC_HOST>:<APIM_HTTP_PORT>/publisher
- API-M Devportal (HTTP UI mode): http://<APIM_PUBLIC_HOST>:<APIM_HTTP_PORT>/devportal
- API-M Gateway HTTP: http://localhost:${APIM_GW_HTTP_PORT}/
- API-M Gateway HTTPS: https://localhost:${APIM_GW_HTTPS_PORT}/

If API-M login redirects to `localhost`, update Service Provider callback URLs in Carbon at `https://<host>:9443/carbon` for both **API Publisher** and **Devportal** applications to use your LAN host.

If `ENABLE_APIM=1`, Publisher is available at `http://<APIM_PUBLIC_HOST>:<APIM_HTTP_PORT>/publisher` when `APIM_UI_PROTOCOL=http`. `APIM_HTTP_PORT` defaults to `9763` if not set.


## Deploy integrations
Put exported `.car` files into:

```text
mi/carbonapps/
```

They will be hot-deployed into MI.

## APIM HTTP UI workaround (LAN/lab)
For one-command startup with APIM portal auto-patching:

- Ensure `ENABLE_APIM=1` in `env/.env`.
- Set `APIM_PUBLIC_HOST=10.0.0.5` (or your LAN IP/DNS).
- Set `APIM_UI_PROTOCOL=http`.

Then run:

```bash
./scripts/restart.sh
```

Access:
- `http://10.0.0.5:9763/publisher`
- `http://10.0.0.5:9763/devportal`
- `http://10.0.0.5:9763/admin`

> ⚠️ This HTTP mode is for LAN/lab use only; do not use it for production internet-facing deployments.

