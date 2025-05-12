# Champions of Mirra Deployment Architecture

This document outlines the two server roles (**Central** and **Arena**) and the associated Makefile targets used to deploy its correspondent applications. The Central server hosts core game services and dashboards (Grafana), while each Arena server runs the game logic for individual battles. Caddy is used on each server as a reverse proxy (with automatic HTTPS) for the main app, Grafana, and Prometheus. DNS is managed via AWS Route 53.

## Central vs. Arena Servers

- **Central server:** Hosts the general backend services for the Mirra game (e.g. the **ChampionsOfMirra** app). This includes modules for battles, campaigns, items, units, and user management. It also runs shared infrastructure like Grafana and Prometheus for monitoring.

- **Arena server:** Hosts the Arena service that runs the actual game logic and physics for matches. Each Arena server manages player connections and game simulation (including a 2D physics engine). In other words, Arena servers handle live gameplay and the matchmaking queues.

## Arena Monitoring (Prometheus + Grafana)

Monitoring is a shared responsibility between the Central and Arena servers:

- **Prometheus** is installed on both Central and Arena servers.
- **Grafana** runs only on the Central server and serves as the primary dashboard interface.
- The Central server holds the `prometheus.yml` configuration, which is set up to **scrape metrics from all Arena servers** via their `/metrics` endpoints.
- Each Arena server exposes its metrics endpoint through Caddy.
- Grafana dashboards on the Central server visualize the collected data from all servers.
- The Central server exposes Grafana over a public DNS name using AWS Route 53. Arena servers similarly expose their Prometheus metrics (auth required) for Central to scrape.

## Makefile Deployment Targets

Key Makefile targets automate server provisioning and configuration. In general, the `admin-setup-*` targets perform initial OS setup (users, packages, firewall, SSH keys, etc.), while `setup-*` targets configure specific services.

- `make admin-setup-arena-server` — Bootstraps a new Arena machine. Installs system packages, creates an `admin` user with SSH keys, disables root login, and configures the firewall (e.g. allow SSH and app ports). These are standard initial setup tasks.

- `make admin-setup-central-server` — Same as above but for a Central machine. It prepares the OS and network settings needed for Central role.

- `make setup-caddy-arena` — Configures Caddy on the Arena server. This sets up Caddy as a reverse proxy for the Arena app and any monitoring UIs (Prometheus) on that host, obtaining TLS certificates automatically.

- `make setup-central-caddy` — Installs/configures Caddy on the Central server. It reverse-proxies the ChampionsOfMirra API and Grafana.

- `make setup-prometheus` — Configures Prometheus for Central server. It includes the `prometheus.yml` that scrapes the `/metrics` endpoints exposed by Arena services. Prometheus automatically collects time-series metrics by scraping HTTP endpoints.

- `make create-env-file` — Generates the environment file (e.g. `.env`) with environment secrets and variables.

- `make setup-aws-central-dns` — Updates DNS records in AWS Route 53 for the Central server. It creates or modifies the hosted zone entries (e.g. `central.example.com`) so that client requests resolve to the correct IP.
    * Note: for Arena server, we do this in `.github/workflows/deploy-new-arena-server.yml` already.
