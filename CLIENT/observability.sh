#!/bin/bash
set -e

BASE_DIR="/opt/observability"
PROMTAIL_VERSION="3.5.5"
OTELCOL_VERSION="0.135.0"
PROMETHEUS_VERSION="2.55.1"   # pick latest stable
SERVER_IP="YOUR_SERVER_IP"

# Create base dirs
mkdir -p $BASE_DIR/promtail $BASE_DIR/otelcol $BASE_DIR/prometheus

########################################
# PROMTAIL
########################################
echo "=== Setting up Promtail ==="
cd $BASE_DIR/promtail

if [ ! -f "promtail-linux-amd64" ]; then
  wget -q https://github.com/grafana/loki/releases/download/v${PROMTAIL_VERSION}/promtail-linux-amd64.zip
  unzip -o promtail-linux-amd64.zip
  chmod +x promtail-linux-amd64
  rm -f promtail-linux-amd64.zip
fi

# Ensure config exists
if [ ! -f "promtail-config.yml" ]; then
  cat > promtail-config.yml <<EOF
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: ./positions.yaml

clients:
  - url: http://\${SERVER_IP}:3100/loki/api/v1/push

scrape_configs:
  - job_name: system
    static_configs:
      - targets: [localhost]
        labels:
          job: varlogs
          __path__: /var/log/*.log

  - job_name: applogs
    static_configs:
      - targets: [localhost]
        labels:
          job: applogs
          __path__: /var/log/*/*.log
EOF
fi

echo "=== Starting Promtail ==="
nohup ./promtail-linux-amd64 -config.file=promtail-config.yml -config.expand-env=true > promtail.log 2>&1 &

########################################
# OPENTELEMETRY COLLECTOR
########################################
echo "=== Setting up OpenTelemetry Collector ==="
cd $BASE_DIR/otelcol

if [ ! -f "otelcol" ]; then
  wget -q https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v${OTELCOL_VERSION}/otelcol_${OTELCOL_VERSION}_linux_amd64.tar.gz
  tar -xvzf otelcol_${OTELCOL_VERSION}_linux_amd64.tar.gz
  rm -f otelcol_${OTELCOL_VERSION}_linux_amd64.tar.gz
  chmod +x otelcol
fi

# Ensure config exists
if [ ! -f "otel-config.yml" ]; then
  cat > otel-config.yml <<EOF
receivers:
  otlp:
    protocols:
      grpc:
      http:

exporters:
  otlp:
    endpoint: \${SERVER_IP}:4317
    tls:
      insecure: true

service:
  pipelines:
    traces:
      receivers: [otlp]
      exporters: [otlp]
EOF
fi

echo "=== Starting OpenTelemetry Collector ==="
export SERVER_IP=$SERVER_IP
nohup ./otelcol --config=file:otel-config.yml > otel.log 2>&1 &

########################################
# PROMETHEUS
########################################
echo "=== Setting up Prometheus ==="
cd $BASE_DIR/prometheus

if [ ! -f "prometheus" ]; then
  wget -q https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz
  tar -xvzf prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz --strip-components=1
  rm -f prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz
  chmod +x prometheus promtool
fi

# Ensure config exists
if [ ! -f "prometheus.yml" ]; then
  cat > prometheus.yml <<EOF
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'promtail'
    static_configs:
      - targets: ['localhost:9080']

  - job_name: 'otelcol'
    static_configs:
      - targets: ['localhost:8888']   # otelcol metrics endpoint
EOF
fi

echo "=== Starting Prometheus ==="
nohup ./prometheus --config.file=prometheus.yml --web.listen-address=":9090" > prometheus.log 2>&1 &

echo "✅ Promtail, Otelcol, and Prometheus started successfully!"
