# Docker Observability Platform

A lightweight Docker observability platform built with **Fluent Bit, Loki, and Grafana** for collecting, storing, analyzing, filtering, downloading, and alerting on application logs.

The project is designed for Docker-based environments where multiple application services require centralized log monitoring without introducing a heavy observability stack.

---

## Architecture

```text
Docker Applications
        |
        | Docker fluentd logging driver
        v
    Fluent Bit
     /      \
    /        \
Local Logs   Loki
               |
               v
            Grafana
               |
        +------+------+
        |             |
     Dashboard      Alerts
                       |
                       v
                    Email
Components
Component	Purpose
Docker	Runs application and monitoring containers
Fluent Bit	Receives, parses, processes, and forwards logs
Loki	Centralized log storage and query engine
Grafana	Dashboard, filtering, visualization, and alerts
SMTP	Sends email notifications
Docker Fluentd Driver	Sends container stdout/stderr logs to Fluent Bit
Features
Centralized Docker application logging
Service-wise log filtering
Log-level filtering
INFO / WARNING / ERROR / NETWORK_ERROR monitoring
Grafana dashboard
Loki-based log storage
Local service log files
Real-time dashboard refresh
Email alerting
Date/time filtering
Service-specific log download
Infrastructure-as-code style Grafana provisioning
Separate local and production Compose files
Persistent Loki and Grafana data
Production-safe internal monitoring ports
Repository Structure
.
├── README.md
├── docker-compose.yml
├── docker-compose.prod.yml
├── .env.example
├── .gitignore
│
├── config/
│   └── fluent-bit.yaml
│
├── loki/
│   └── loki-config.yaml
│
├── grafana/
│   ├── dashboards/
│   │   └── fluent-bit-dashboard.json
│   └── provisioning/
│       ├── datasources/
│       ├── dashboards/
│       └── alerting/
│
└── docs/
    ├── LIVE_DEPLOYMENT.md
    ├── CHANGE_MANAGEMENT.md
    └── INTERVIEW_QUESTIONS.md
Local Environment

The local environment can include test services that continuously generate sample application logs.

Start the local environment:

docker compose up -d

Check services:

docker compose ps
Production Environment

Production uses:

docker compose -f docker-compose.prod.yml up -d

The production monitoring stack should contain only:

Fluent Bit
Loki
Grafana

Real application containers provide the logs.

See:

docs/LIVE_DEPLOYMENT.md
Ports
Port	Component	Recommended Exposure
24224	Fluent Bit Forward Input	localhost only
2020	Fluent Bit HTTP Monitoring	localhost only
3100	Loki	localhost only
3200	Grafana	localhost / reverse proxy

Production recommendation:

127.0.0.1:24224
127.0.0.1:2020
127.0.0.1:3100
127.0.0.1:3200

Do not publicly expose Fluent Bit or Loki unless there is a specific secured requirement.

Environment Configuration

Copy:

cp .env.example .env

Configure:

GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=CHANGE_ME

SMTP_HOST=smtp.example.com:587
SMTP_USER=monitoring@example.com
SMTP_PASSWORD=APP_PASSWORD
SMTP_FROM=monitoring@example.com

ALERT_EMAIL=devteam@example.com

Protect the file:

chmod 600 .env

Never commit .env.

Docker Logging Configuration

Example application configuration:

logging:
  driver: fluentd
  options:
    fluentd-address: "127.0.0.1:24224"
    fluentd-async: "true"
    tag: "docker.auth"

Example tags:

docker.apigateway
docker.auth
docker.catalog
docker.parenting
docker.vendor
docker.vendor_web
Fluent Bit

Fluent Bit receives logs through:

TCP 24224

Monitoring endpoint:

curl http://127.0.0.1:2020/api/v1/health

Expected:

ok

Metrics:

curl -s http://127.0.0.1:2020/api/v1/metrics | jq
Loki

Check Loki:

curl http://127.0.0.1:3100/ready

Expected:

ready

Example LogQL query:

{job="fluentbit"}

Service-specific query:

{job="fluentbit",service="auth"}

Error query:

{job="fluentbit",level=~"ERROR|NETWORK_ERROR"}
Grafana

Default local URL:

http://localhost:3200

Dashboard provides:

Total Logs
INFO
WARNING
ERROR
NETWORK_ERROR
Service filter
Level filter
Time-range filtering
Logs panel
Log download
Email alerts
Production Grafana Access

Recommended method:

ssh -L 3200:127.0.0.1:3200 user@SERVER_IP

Then access:

http://localhost:3200

For shared access, place Grafana behind HTTPS using Nginx, an ingress, load balancer, VPN, or another approved access layer.

Alerting

The project provisions Grafana alerting through files.

Example condition:

sum(count_over_time({job="fluentbit",level=~"ERROR|NETWORK_ERROR"}[1m]))

If the count is greater than zero, Grafana can send an email notification through the configured SMTP server.

Log Download

Logs can be filtered using:

Service
Level
Time Range

The Grafana Logs visualization supports downloading displayed results when download controls are enabled.

For larger exports, query Loki directly instead of relying only on the dashboard.

Health Checks

Check containers:

docker compose ps

Fluent Bit:

curl http://127.0.0.1:2020/api/v1/health

Loki:

curl http://127.0.0.1:3100/ready

Grafana:

curl -I http://127.0.0.1:3200
Troubleshooting
Fluent Bit is not receiving logs

Check:

docker inspect CONTAINER_NAME \
  --format '{{json .HostConfig.LogConfig}}' | jq

Verify:

Type = fluentd
fluentd-address = 127.0.0.1:24224

Check Fluent Bit:

docker logs fluent-bit --tail 100
Loki is not receiving logs

Check:

docker logs loki --tail 100

Then query:

curl -G -s \
  --data-urlencode 'query={job="fluentbit"}' \
  http://127.0.0.1:3100/loki/api/v1/query_range | jq
Grafana cannot query Loki

Inside the Docker environment, the datasource URL should generally use the Docker service name:

http://loki:3100

not:

http://localhost:3100

because localhost inside the Grafana container means the Grafana container itself.

Production Safety

Before production deployment:

Back up the existing application Compose configuration.
Verify available disk space.
Check monitoring ports.
Inspect real application log formats.
Start Fluent Bit, Loki, and Grafana first.
Test with a synthetic log.
Change one application at a time.
Recreate only the changed service.
Verify application health.
Verify log delivery.
Continue with the next service.

Do not unnecessarily run:

docker compose down

against the entire live application stack.

Change Management

All monitoring changes should be performed through Git.

Recommended flow:

main
  |
feature/change-name
  |
development
  |
testing
  |
pull request
  |
review
  |
merge
  |
production deployment

See:

docs/CHANGE_MANAGEMENT.md
Security
Never commit .env
Never commit SMTP passwords
Restrict Fluent Bit ports
Restrict Loki access
Protect Grafana with authentication
Use strong Grafana admin credentials
Use TLS for externally accessible Grafana
Keep Docker and images updated
Review dashboard permissions
Keep alert recipient lists controlled
Rotate credentials if accidentally exposed
License

Internal / project-specific usage unless otherwise defined by the repository owner.
