# Observability Stack with Grafana, Loki, Tempo, and Prometheus

This project provides a complete, self-contained observability stack using Docker and Docker Compose. It combines Grafana for visualization, Loki for log aggregation, Tempo for distributed tracing, and Prometheus for metrics.

## Overview

The setup allows you to collect, store, and visualize metrics, logs, and traces from your applications in a single unified dashboard. This makes it easier to monitor the health and performance of your systems and troubleshoot issues.

## Prerequisites

Before you begin, ensure you have the following software installed on your system:

- **Docker**: Follow the official installation guide
- **Docker Compose**: This is typically installed with Docker, but you can verify with `docker compose version`

## Getting Started

To get the project up and running, follow these simple steps:

1. Clone the repository:
```bash
git clone https://github.com/Aniljahangir8/observability.git
cd observability
```

2. Build and run the services:
```bash
docker compose up --build -d
```
The `--build` flag ensures that the images are built before starting the containers, and the `-d` flag runs the containers in detached mode (in the background).

## Services

| Service    | Description                       | Port      |         
|------------|-----------------------------------|-----------|
| Grafana    | Dashboard and visualization tool  | 3000:3000 |
| Loki       | A log aggregation system          | 3100:3100 |
| Tempo      | A distributed tracing backend     | 3200:3200 (http)<br/>4318:4318 (otlp) |
| Prometheus | A monitoring and alerting toolkit | 9090:9090 |

## Usage

Once the services are running, you can access the Grafana dashboard to start visualizing your data.

1. **Grafana**: Open your browser and navigate to `http://localhost:3000`

To stop the services, run:
```bash
docker compose down
```

## Configuration

This setup relies on local configuration files that are mounted as volumes into the containers. You can modify the configuration for each service by editing the files in the corresponding directories:

- `./grafana`
- `./loki/config.yml`
- `./tempo/config.yml`
- `./prometheus/prometheus.yml`
