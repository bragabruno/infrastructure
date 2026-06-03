# Fraud Prevention Platform — Infrastructure

Infrastructure-as-Code for the **AI-Powered Fraud Prevention Platform**. Manages cloud provisioning (Terraform), CI/CD pipelines, integration tests, and operational scripts.

## Repository Structure

```
infrastructure/
├── .github/workflows/
│   ├── ci.yml                    # Multi-service CI (backend, ml-service, frontend)
│   └── terraform.yml             # Terraform plan/apply CI/CD
├── terraform/
│   ├── modules/
│   │   ├── aws/                  # VPC, ECS, RDS, Redis, MSK, Secrets
│   │   ├── gcp/                  # Firebase Auth
│   │   └── azure/                # Azure OpenAI, Foundry
│   └── environments/
│       ├── dev/                  # Single-AZ, small instances
│       ├── staging/              # Multi-AZ, medium instances
│       └── prod/                 # Multi-AZ, large instances, HA
├── tests/integration/            # Smoke tests against Docker Compose stack
├── scripts/
│   ├── kafka-init.sh             # Kafka topic provisioning (7 topics)
│   ├── db-init.sh                # DB init + Flyway migration + seed
│   ├── health-aggregate.sh       # Aggregate health check
│   ├── validate-contracts.sh     # Cross-service contract validation
│   ├── release.sh                # Cross-repo version tagging
│   ├── setup.sh                  # Developer onboarding (one command)
│   └── health.sh                 # Health check for all services
├── docker-compose.staging.yml    # Staging override
├── docs/
│   └── INFRA-TICKETS.md          # Infrastructure backlog (FRAUD-260–289)
└── VERSION                       # Platform version (semantic)
```

## Quickstart

```bash
# 1. Clone all repos
git clone https://github.com/bragabruno/infrastructure.git
git clone https://github.com/bragabruno/backend.git
git clone https://github.com/bragabruno/ml-service.git
git clone https://github.com/bragabruno/frontend.git

# 2. One-command setup
cd FraudPreventionSystem
./infrastructure/scripts/setup.sh

# 3. Or manually
cp .env.example .env
doppler setup --project fraud-prevention --config dev_main
make up
```

## Cloud Architecture

| Cloud | Purpose | Services |
|-------|---------|----------|
| **AWS** | Primary infrastructure | VPC, ECS Fargate, RDS PostgreSQL 16, ElastiCache Redis 7, MSK Kafka, Secrets Manager |
| **GCP** | Frontend authentication | Firebase Auth (email/password + Google OAuth) |
| **Azure** | AI/ML services | Azure OpenAI (GPT-4), AI Foundry, Key Vault |

## CI/CD

| Workflow | Trigger | Actions |
|----------|---------|---------|
| `ci.yml` | Push/PR to main | Build + test backend, ml-service, frontend in parallel. Integration tests on merge. |
| `terraform.yml` | Push/PR to terraform/ | Plan on PR, apply on merge (dev auto, staging/prod manual approval) |

## Scripts

| Script | Purpose |
|--------|---------|
| `setup.sh` | Full developer onboarding (prereqs, env, build, start, seed) |
| `health.sh` | Check health of all services |
| `health-aggregate.sh` | Aggregate health with latency reporting |
| `kafka-init.sh` | Create 7 Kafka topics (idempotent) |
| `db-init.sh` | Init PostgreSQL, run Flyway, seed reference data |
| `validate-contracts.sh` | Cross-service contract validation |
| `release.sh` | Bump version and tag all repos |

## Infrastructure Tickets

See [docs/INFRA-TICKETS.md](docs/INFRA-TICKETS.md) for the full backlog.

| EPIC | Tickets | Status |
|------|---------|--------|
| EPIC-43 | FRAUD-260–264 | Done |
| EPIC-44 | FRAUD-265–268 | Done |
| EPIC-45 | FRAUD-269–271 | Planned |
| EPIC-46 | FRAUD-272–274 | Done |
| EPIC-47 | FRAUD-275–278 | Done |
| EPIC-48 | FRAUD-279–289 | Done |

## License

BragDev LLC
