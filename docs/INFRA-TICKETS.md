# Shared Infrastructure — Platform-Level Backlog

**Location:** `FraudPreventionSystem/docs/` (root, shared across all repos)
**Owner:** BragDev LLC

> This backlog covers the **shared infrastructure layer** that connects the three
> repos: `backend/` (Java), `ml-service/` (Python), and `frontend/` (Angular).
> Each repo has its own `docs/TICKETS.md` for repo-specific work. This file covers
> what must exist at the root level for all three to function together.
>
> Tickets start at **FRAUD-260** to avoid collisions with platform (001–161),
> ML (162–207), backend (208–236), and frontend (237–259).

---

## Summary

| Epic | Title | Tickets | Primary skills |
|---|---|---|---|
| **EPIC-43** | Root Docker Compose & Local Stack | FRAUD-260–264 | Docker, compose, healthchecks |
| **EPIC-44** | Shared CI/CD Pipeline | FRAUD-265–268 | GitHub Actions, multi-repo |
| **EPIC-45** | Integration Testing | FRAUD-269–271 | Testcontainers, cross-service |
| **EPIC-46** | Deployment & Environments | FRAUD-272–274 | Docker, env config, staging |
| **EPIC-47** | Documentation & Onboarding | FRAUD-275–278 | Docs, diagrams, contributing |
| **EPIC-48** | Terraform Multi-Cloud Infrastructure | FRAUD-279–289 | Terraform, AWS, GCP Firebase, Azure AI |

---

## Cross-Repo Architecture

```
FraudPreventionSystem/          ← Root (this file lives here)
├── backend/                    ← Java 21 / Spring Boot 3.5 (FRAUD-208–236)
│   └── docs/TICKETS.md
├── ml-service/                 ← Python 3.12 / FastAPI (FRAUD-162–207)
│   └── docs/TICKETS.md
├── frontend/                   ← Angular 19 / TypeScript (FRAUD-237–259)
│   └── docs/TICKETS.md
├── docs/                       ← Shared infrastructure (this file, FRAUD-260–278)
│   ├── ROADMAP.md
│   ├── TICKETS.md              ← Platform tickets (FRAUD-001–161)
│   ├── INFRA-TICKETS.md        ← This file
│   └── diagrams/
└── docker-compose.yml          ← Root compose (all services)
```

---

## Service Ports

| Service | Container Port | Host Port | Notes |
|---|---|---|---|
| PostgreSQL | 5432 | 5432 | Shared across backend + ml-service |
| Redis | 6379 | 6379 | Shared across backend + ml-service |
| Kafka | 9092 | 9092 | KRaft mode, shared |
| Backend | 8080 | 8080 | Spring Boot |
| ML Service | 8001 | 8001 | FastAPI (offset from 8000 to avoid conflicts) |
| Frontend | 4200 | 4200 | Angular dev server |

---

# PHASE 12 — SHARED INFRASTRUCTURE

## EPIC-43 — Root Docker Compose & Local Stack
*Phase 12 · Lead: DO · Depends on: backend/FRAUD-208, ml-service/FRAUD-163*

Root-level Docker Compose that brings up all three services + shared infra in one command.

### FRAUD-260 — Root docker-compose.yml (all services)
**Type:** Infrastructure · **Epic:** EPIC-43 · **Complexity:** L · **Owner:** DO
**Description:** Create `FraudPreventionSystem/docker-compose.yml` at the project root that orchestrates: Postgres 16, Redis 7, Kafka KRaft, backend (Spring Boot), ml-service (FastAPI), and frontend (Angular dev server). All services start with healthchecks and `depends_on` conditions. Named volumes for Postgres and Redis. `.env` loaded at root level.
**Business Value:** One command brings up the entire platform for development and demos.
**Acceptance Criteria:**
- `docker compose up --build` starts all 6 services.
- All healthchecks pass within 60 seconds.
- Backend connects to Postgres, Redis, Kafka.
- ML service connects to Postgres, Redis.
- Frontend proxies `/api` to backend:8080.
- `.env` at root configures all services.
**Technical Notes:** Use `extends` or `profiles` to reference per-repo docker-compose files where possible. Healthchecks: Postgres (`pg_isready`), Redis (`redis-cli ping`), Kafka (`kafka-broker-api-versions`), Backend (`curl /actuator/health`), ML (`curl /health`), Frontend (`curl localhost:4200`).
**Dependencies:** —

### FRAUD-261 — Root .env.example (all services)
**Type:** Technical Task · **Epic:** EPIC-43 · **Complexity:** S · **Owner:** DO
**Description:** Create `FraudPreventionSystem/.env.example` documenting every environment variable needed by the root compose stack: database credentials, Redis config, Kafka bootstrap servers, JWT signing keys, ML service URL, LLM provider toggle, API keys. Include comments explaining each var.
**Business Value:** New developers can configure the full stack from a template.
**Acceptance Criteria:**
- Every env var used by any service is documented.
- Comments explain purpose and default value.
- `.env` is in `.gitignore` (never committed).
- `.env.example` is committed and always up to date.
**Technical Notes:** Use the `backend/.env` as a base and extend with ML service vars (`LLM_PROVIDER`, `MLFLOW_TRACKING_URI`) and frontend vars (`API_URL`).
**Dependencies:** FRAUD-260

### FRAUD-262 — Root Makefile (one-command dev loop)
**Type:** Infrastructure · **Epic:** EPIC-43 · **Complexity:** S · **Owner:** DO
**Description:** Create `FraudPreventionSystem/Makefile` with targets: `up` (docker compose up -d), `down` (docker compose down), `build` (build all services), `test` (run all tests), `logs` (follow logs), `reset` (down -v + up), `seed` (run Flyway migrations + dbt seed), `status` (docker compose ps), `health` (curl all health endpoints). Include `help` target.
**Business Value:** Single command to manage the full development environment.
**Acceptance Criteria:**
- `make up` brings all services healthy.
- `make test` runs backend tests + ml-service tests + frontend tests.
- `make reset` cleans volumes and re-creates.
- `make health` curls all health endpoints and reports status.
- Each target has a help comment.
**Technical Notes:** Use `.PHONY` for all targets. Chain into per-repo Makefiles where they exist.
**Dependencies:** FRAUD-260

### FRAUD-263 — Kafka topic provisioning (7 topics)
**Type:** Infrastructure · **Epic:** EPIC-43 · **Complexity:** M · **Owner:** DO
**Description:** Ensure all 7 Kafka topics are created on startup: `transactions.created`, `fraud.scored`, `fraud.review.required`, `fraud.confirmed`, `fraud.falsepositive`, `fraud.model.deployed`, `fraud.retraining.requested`. Use an init container or startup script that waits for Kafka to be healthy and creates topics with proper partition/replication config.
**Business Value:** All services can produce/consume from the correct topics without manual setup.
**Acceptance Criteria:**
- All 7 topics created automatically on `docker compose up`.
- Topics have correct partition counts (3 for local, 1 for single-broker).
- Init container waits for Kafka health before creating topics.
- Topics are idempotent (re-running doesn't fail).
**Technical Notes:** Use `confluentinc/cp-kafka` image with `kafka-topics --create` commands. Alternatively, use a lightweight init container with a shell script.
**Dependencies:** FRAUD-260

### FRAUD-264 — Database initialization script (backend + ml-service schemas)
**Type:** Infrastructure · **Epic:** EPIC-43 · **Complexity:** M · **Owner:** DO
**Description:** Create an initialization script that sets up the database for both backend and ml-service: creates the `fraud_db` database, runs Flyway migrations (backend), seeds reference data (merchants, users, devices), and optionally seeds ml-service data (synthetic transactions). Script runs on first `docker compose up` or via `make seed`.
**Business Value:** Fresh database ready for development in one command.
**Acceptance Criteria:**
- `docker compose up` creates database and runs migrations.
- `make seed` inserts demo data (users, merchants, devices, sample transactions).
- Script is idempotent (safe to run multiple times).
- Both backend and ml-service schemas coexist without conflicts.
**Technical Notes:** Use a `flyway` init container for backend migrations. For ml-service data, use a Python script that seeds via SQL or the data generator. Consider using `pg_isready` to wait for Postgres before running migrations.
**Dependencies:** FRAUD-260, backend/FRAUD-211

---

## EPIC-44 — Shared CI/CD Pipeline
*Phase 12 · Lead: DO · Depends on: EPIC-43*

Root-level CI that validates integration across all three repos.

### FRAUD-265 — Root CI workflow (multi-service build + test)
**Type:** Infrastructure · **Epic:** EPIC-44 · **Complexity:** L · **Owner:** DO
**Description:** Create `FraudPreventionSystem/.github/workflows/ci.yml` that runs on push/PR to `main`: starts Docker Compose stack, runs backend tests (Gradle), ml-service tests (pytest), and frontend tests (ng test + Playwright). Each service runs in parallel jobs. Integration step validates the full stack boots and health endpoints pass.
**Business Value:** Every PR validated against the full platform, not just individual repos.
**Acceptance Criteria:**
- CI runs on PR to `main`.
- Backend, ml-service, and frontend tests run in parallel jobs.
- Integration job starts Docker Compose and validates health endpoints.
- Any test failure blocks merge.
- Status badge in root README.
**Technical Notes:** Use GitHub Actions matrix strategy for parallel service jobs. Integration job uses `docker compose up --build` and waits for health. Cache Docker layers for faster builds.
**Dependencies:** —

### FRAUD-266 — Cross-service contract validation
**Type:** Technical Task · **Epic:** EPIC-44 · **Complexity:** M · **Owner:** DO
**Description:** Validate that the backend API contract matches the frontend's expected contract and the ml-service's scoring interface. Use OpenAPI spec diffing (backend exports spec, frontend imports it) or a lightweight contract test that verifies key endpoints match expected schemas.
**Business Value:** Catches contract drift between repos before it breaks integration.
**Acceptance Criteria:**
- Backend OpenAPI spec is exported as a CI artifact.
- Contract test validates that key endpoints (login, cases, transactions) match expected shapes.
- Frontend MSW handlers are validated against the backend spec.
- ML service `/predict` contract matches backend's ML client expectations.
**Technical Notes:** Use `openapi-diff` or similar tool. For ML service, compare Pydantic schema with backend's `MlPredictionResponse` DTO.
**Dependencies:** FRAUD-265, backend/FRAUD-214

### FRAUD-267 — Integration test suite (full stack)
**Type:** Story · **Epic:** EPIC-44 · **Complexity:** L · **Owner:** DO
**Description:** Write integration tests that run against the full Docker Compose stack: (1) login → get token → access protected endpoint, (2) create transaction → verify scoring, (3) verify case created for high-risk transaction, (4) SSE connection receives real-time events, (5) admin can manage users and rules. Tests run after `docker compose up` in CI.
**Business Value:** Validates the entire platform works end to end.
**Acceptance Criteria:**
- 5+ integration test scenarios passing in CI.
- Tests run against live Docker Compose stack.
- Tests validate auth, transactions, cases, SSE, and admin flows.
- Tests clean up after themselves (don't leave state).
**Technical Notes:** Use a test runner (Python pytest or Newman/Postman) that makes real HTTP calls to the Docker Compose stack. Wait for health endpoints before running tests.
**Dependencies:** FRAUD-265

### FRAUD-268 — Release tagging (cross-repo version alignment)
**Type:** Technical Task · **Epic:** EPIC-44 · **Complexity:** S · **Owner:** DO
**Description:** Define a release strategy that aligns versions across the three repos: when one repo has breaking changes, the others are updated. Use a root-level `VERSION` file or git tags. Create a `release.sh` script that tags all repos with a shared version and updates cross-repo dependencies.
**Business Value:** Consistent versioning across the platform.
**Acceptance Criteria:**
- `VERSION` file at root tracks current platform version.
- `release.sh` tags all three repos with the same version.
- Breaking API changes trigger version bumps in dependent repos.
- README shows current platform version.
**Technical Notes:** Use semantic versioning. `release.sh` uses `git tag` on each repo. Consider a `versions.lock` file if pinning cross-repo dependencies.
**Dependencies:** —

---

## EPIC-45 — Integration Testing
*Phase 12 · Lead: QA/DO · Depends on: EPIC-44*

Cross-service testing infrastructure.

### FRAUD-269 — Test environment setup (Docker Compose test profile)
**Type:** Infrastructure · **Epic:** EPIC-45 · **Complexity:** M · **Owner:** DO
**Description:** Create a Docker Compose test profile that spins up a minimal test environment: Postgres + Redis + Kafka (no app containers). Use Testcontainers in backend/ml-service tests to connect to these shared infra containers. Frontend tests use MSW (no real backend needed).
**Business Value:** Fast, isolated integration tests without starting the full stack.
**Acceptance Criteria:**
- `docker compose --profile test up` starts Postgres, Redis, Kafka only.
- Backend tests connect via Testcontainers to shared infra.
- ML service tests connect via Testcontainers to shared infra.
- Frontend tests run with MSW (no Docker needed).
- Tests can run in parallel without port conflicts.
**Technical Notes:** Use Docker Compose profiles. Testcontainers connects to Docker-exposed ports. Use `@Testcontainers` + `@Container` in JUnit.
**Dependencies:** FRAUD-260

### FRAUD-270 — E2E test framework (full user journey)
**Type:** Story · **Epic:** EPIC-45 · **Complexity:** L · **Owner:** QA
**Description:** Set up an E2E testing framework that validates the full user journey: login → dashboard → case queue → case detail → investigation → label → logout. Use Playwright against the Angular dev server with MSW for API mocking, and a separate suite that runs against the real backend (Docker Compose).
**Business Value:** Confidence that the full user experience works end to end.
**Acceptance Criteria:**
- Playwright test suite with 10+ scenarios.
- Mock suite runs without Docker (MSW only).
- Real suite runs against Docker Compose stack.
- CI runs both suites.
**Technical Notes:** Use `@playwright/test`. Create page object models. Use `test.describe` for mock vs real suites.
**Dependencies:** FRAUD-267, frontend/FRAUD-257

### FRAUD-271 — Contract test between backend and ml-service
**Type:** Technical Task · **Epic:** EPIC-45 · **Complexity:** M · **Owner:** DO
**Description:** Validate that the backend's ML client (FRAUD-229) can communicate with the ml-service's `/predict` endpoint. Test: (1) request shape matches ml-service's Pydantic schema, (2) response shape matches backend's `MlPredictionResponse`, (3) error responses are compatible, (4) circuit breaker works on timeout.
**Business Value:** Prevents ML integration failures at deployment time.
**Acceptance Criteria:**
- Contract test validates request/response shapes.
- Test runs in CI against both services.
- Error responses (422, 500) are handled correctly by both sides.
- Circuit breaker fallback verified.
**Technical Notes:** Use the ml-service's Pydantic schema as the source of truth. Export the schema as JSON and validate against it in Java tests.
**Dependencies:** backend/FRAUD-229, ml-service/FRAUD-059

---

## EPIC-46 — Deployment & Environments
*Phase 12 · Lead: DO · Depends on: EPIC-43*

Environment configuration and deployment readiness.

### FRAUD-272 — Environment configuration matrix
**Type:** Technical Task · **Epic:** EPIC-46 · **Complexity:** M · **Owner:** DO
**Description:** Document the environment configuration matrix: what env vars are needed per service per environment (local, dev, staging, prod). Create `env/` directory with `local.env`, `dev.env`, `staging.env`, `prod.env` templates. Each template has comments explaining purpose and required values.
**Business Value:** Consistent configuration across environments; no missing vars at deploy time.
**Acceptance Criteria:**
- `env/local.env` template with all vars.
- `env/dev.env`, `env/staging.env`, `env/prod.env` templates.
- Every env var documented with purpose and default.
- Templates reference secrets (never commit actual values).
**Technical Notes:** Use `envsubst` or Spring Cloud Config for prod. Local uses `.env` at root. Secrets always via env vars or secrets manager, never in files.
**Dependencies:** FRAUD-261

### FRAUD-273 — Health check aggregation (root health endpoint)
**Type:** Story · **Epic:** EPIC-46 · **Complexity:** S · **Owner:** DO
**Description:** Create a root-level health aggregation endpoint or script that checks all three services' health endpoints and reports overall status. Useful for deployment verification and monitoring.
**Business Value:** Single health check for the entire platform.
**Acceptance Criteria:**
- Script or endpoint checks backend `/actuator/health`, ml-service `/health`, frontend `/`.
- Returns overall UP/DOWN status.
- Reports per-service status with latency.
- Can be used as a Docker healthcheck for the root compose.
**Technical Notes:** Simple shell script or Python script. Could be a lightweight HTTP endpoint in a new `health-aggregator` service, or just a Makefile target.
**Dependencies:** FRAUD-260

### FRAUD-274 — Staging environment configuration
**Type:** Infrastructure · **Epic:** EPIC-46 · **Complexity:** M · **Owner:** DO
**Description:** Configure the staging environment: separate Postgres/Redis/Kafka instances, backend with `ddl-auto=validate`, ml-service with real Anthropic API (optional), frontend built and served by nginx. Include staging-specific Docker Compose override and env vars.
**Business Value:** A pre-production environment that mirrors production.
**Acceptance Criteria:**
- `docker-compose.staging.yml` override file.
- Backend uses `staging` profile (ddl-auto=validate, no seed data).
- ML service uses real API if `ANTHROPIC_API_KEY` provided.
- Frontend builds to static and serves via nginx.
- Staging env vars documented and templated.
**Technical Notes:** Use Docker Compose override files (`docker-compose.staging.yml`). nginx config for frontend static files.
**Dependencies:** FRAUD-272

---

## EPIC-47 — Documentation & Onboarding
*Phase 12 · Lead: DO/BE · Depends on: EPIC-43*

Root-level documentation and developer onboarding.

### FRAUD-275 — Root README (platform overview + quickstart)
**Type:** Story · **Epic:** EPIC-47 · **Complexity:** M · **Owner:** DO
**Description:** Create `FraudPreventionSystem/README.md` as the platform entry point: architecture overview (link to `docs/ROADMAP.md`), quickstart (clone + make up), service links (backend:8080, ml:8001, frontend:4200, swagger:8080/swagger-ui.html), JD skill map linking to each repo's README, and contributing guide.
**Business Value:** First thing a recruiter/interviewer or new developer sees.
**Acceptance Criteria:**
- README works on GitHub with rendered markdown and mermaid diagrams.
- Quickstart takes < 5 minutes from clone to running platform.
- JD skill map links every skill to a concrete file/dir in the repos.
- Links to each repo's README for deep dives.
**Technical Notes:** Include screenshots or GIFs of the dashboard. Use GitHub badges for CI status.
**Dependencies:** FRAUD-260, backend/FRAUD-233, frontend/FRAUD-259

### FRAUD-276 — Architecture diagram (full platform C4)
**Type:** Story · **Epic:** EPIC-47 · **Complexity:** M · **Owner:** DO
**Description:** Update `docs/diagrams/01-architecture-c4.md` to reflect the actual implementation: backend Spring Boot, ml-service FastAPI, frontend Angular, root Docker Compose. Add component diagrams for each service. Ensure diagrams render on GitHub.
**Business Value:** The "walk me through your system" artifact for the interview.
**Acceptance Criteria:**
- C4 Level 2 (container) diagram shows all 3 services + infra.
- C4 Level 3 (component) diagrams for each service.
- Mermaid syntax renders on GitHub.
- Diagrams match actual implementation (not just plans).
**Technical Notes:** Use Mermaid flowcharts. Link to actual source files where possible.
**Dependencies:** FRAUD-275

### FRAUD-277 — CONTRIBUTING.md (multi-repo workflow)
**Type:** Technical Task · **Epic:** EPIC-47 · **Complexity:** S · **Owner:** DO
**Description:** Create `FraudPreventionSystem/CONTRIBUTING.md` explaining the polyrepo workflow: how to clone all repos, how to run tests per repo, how to make cross-repo changes, PR review process, and branch naming conventions.
**Business Value:** Clear contribution guidelines for a multi-repo project.
**Acceptance Criteria:**
- Step-by-step clone and setup instructions.
- Test commands for each repo.
- Cross-repo change workflow explained.
- PR template included.
**Dependencies:** —

### FRAUD-278 — Developer onboarding script
**Type:** Infrastructure · **Epic:** EPIC-47 · **Complexity:** S · **Owner:** DO
**Description:** Create `scripts/setup.sh` that automates the full developer onboarding: clone all repos, install dependencies (Java 21, Node 20, Python 3.12, uv), copy `.env.example` → `.env`, run `make up`, run migrations, seed data, and print service URLs. Run on first clone only.
**Business Value:** New developer goes from zero to running platform in one command.
**Acceptance Criteria:**
- `./scripts/setup.sh` completes without errors.
- Checks for prerequisites (Java, Node, Python, Docker).
- Skips steps already completed (idempotent).
- Prints service URLs and credentials at the end.
**Technical Notes:** Use `set -euo pipefail`. Check prerequisites with `command -v`. Use `make` targets where available.
**Dependencies:** FRAUD-262

---

## EPIC-48 — Terraform Multi-Cloud Infrastructure
*Phase 13 · Lead: DO · Depends on: EPIC-43*

Terraform modules for provisioning the Fraud Prevention Platform. Multi-cloud strategy:
- **AWS** → primary infrastructure (ECS, RDS, ElastiCache, MSK, Secrets Manager)
- **GCP** → Firebase Authentication for frontend (Angular SDK, social login, MFA)
- **Azure** → AI/ML services (Azure OpenAI, Foundry for model deployment/eval)

### FRAUD-279 — Terraform project structure + provider config
**Type:** Infrastructure · **Epic:** EPIC-48 · **Complexity:** M · **Owner:** DO
**Description:** Create `infrastructure/terraform/` with modular structure: `modules/aws/` (primary infra), `modules/gcp/` (Firebase auth), `modules/azure/` (AI/ML), `environments/{dev,staging,prod}/` (per-env configs). Configure Terraform >= 1.5 with required providers (aws, google, azurerm). Remote state in S3 (primary) with DynamoDB locking.
**Business Value:** Single Terraform codebase provisions all cloud resources with consistent naming.
**Acceptance Criteria:**
- `terraform init` succeeds for all three providers.
- `terraform validate` passes for all modules.
- Remote state in S3 with DynamoDB locking.
- Workspaces separate dev/staging/prod.
- `.terraform.lock.hcl` committed.
**Technical Notes:** Directory layout: `infrastructure/terraform/{modules,environments,providers}`. Use `modules/aws/{networking,compute,database,cache,messaging,secrets}`, `modules/gcp/firebase-auth`, `modules/azure/ai-ml`. Providers: `hashicorp/aws ~> 5.0`, `hashicorp/google ~> 5.0`, `hashicorp/azurerm ~> 3.0`.
**Dependencies:** —

### FRAUD-280 — AWS networking module (VPC + subnets + security groups)
**Type:** Infrastructure · **Epic:** EPIC-48 · **Complexity:** M · **Owner:** DO
**Description:** Create `modules/aws/networking` with VPC, public/private subnets across 2 AZs, NAT Gateway, Internet Gateway, security groups for app/data/messaging tiers. Tag all resources with `project`, `environment`, `managed_by=terraform`.
**Business Value:** Network foundation for all AWS services with proper isolation.
**Acceptance Criteria:**
- VPC with 2 public + 2 private subnets across 2 AZs.
- NAT Gateway for private subnet internet access.
- Security groups: `app-sg` (8080,8001,4200), `data-sg` (5432,6379), `messaging-sg` (9092).
- All resources tagged for cost tracking.
- Outputs: `vpc_id`, `private_subnet_ids`, `public_subnet_ids`, `security_group_ids`.
**Technical Notes:** Use `aws_vpc`, `aws_subnet`, `aws_nat_gateway`, `aws_security_group`. CIDR: `10.0.0.0/16`. Public: `10.0.1.0/24`, `10.0.2.0/24`. Private: `10.0.10.0/24`, `10.0.11.0/24`.
**Dependencies:** FRAUD-279

### FRAUD-281 — AWS compute module (ECS Fargate for backend + ml-service + frontend)
**Type:** Infrastructure · **Epic:** EPIC-48 · **Complexity:** L · **Owner:** DO
**Description:** Create `modules/aws/compute` with ECS Fargate cluster, task definitions, and services for backend (Spring Boot), ml-service (FastAPI), and frontend (nginx). Application Load Balancer with path-based routing (`/api` → backend, `/ml` → ml-service, `/` → frontend). Auto-scaling policies.
**Business Value:** Containerized workloads running on managed compute with auto-scaling.
**Acceptance Criteria:**
- ECS Fargate cluster with 3 services.
- ALB with path-based routing.
- Task definitions reference secrets from Secrets Manager.
- Auto-scaling: CPU 70% target, min 1 / max 10 tasks.
- Health checks on `/actuator/health`, `/health`, `/`.
- Outputs: `alb_dns_name`, `ecs_cluster_arn`, `service_arns`.
**Technical Notes:** Use `aws_ecs_cluster`, `aws_ecs_task_definition`, `aws_ecs_service`, `aws_lb_listener_rule`. Use `aws_ecs_task_definition` with `secrets` block referencing Secrets Manager ARNs. ALB `aws_lb` with `aws_lb_target_group` per service.
**Dependencies:** FRAUD-280

### FRAUD-282 — AWS data layer (RDS PostgreSQL 16 + ElastiCache Redis)
**Type:** Infrastructure · **Epic:** EPIC-48 · **Complexity:** M · **Owner:** DO
**Description:** Create `modules/aws/database` with RDS PostgreSQL 16 (Multi-AZ for prod, single for dev) and ElastiCache Redis 7 (cluster mode). Both in private subnets with encryption at rest and in transit. Automated backups, parameter groups tuned for fraud detection workload.
**Business Value:** Managed database and cache with automated backups and HA.
**Acceptance Criteria:**
- RDS PostgreSQL 16 with `fraud_db` database created.
- ElastiCache Redis 7 cluster with encryption.
- Both in private subnets, accessible only from app security group.
- Automated backups: 7 days (prod), 1 day (dev).
- Parameter group: `shared_preload_libraries=pg_stat_statements`.
- Outputs: `rds_endpoint`, `redis_endpoint`, `rds_port`, `redis_port`.
**Technical Notes:** RDS: `aws_db_instance` with `engine=postgres` `engine_version=16`. ElastiCache: `aws_elasticache_replication_group` with `engine=redis` `engine_version=7.0`. Use `aws_db_subnet_group` and `aws_elasticache_subnet_group`. Store passwords in Secrets Manager.
**Dependencies:** FRAUD-280

### FRAUD-283 — AWS messaging layer (MSK Kafka with 7 topics)
**Type:** Infrastructure · **Epic:** EPIC-48 · **Complexity:** M · **Owner:** DO
**Description:** Create `modules/aws/messaging` with MSK (Managed Streaming for Kafka) cluster, 7 domain topics, and IAM policies for produce/consume. Topics: `transactions.created`, `fraud.scored`, `fraud.review.required`, `fraud.confirmed`, `fraud.falsepositive`, `fraud.retraining.requested`, `fraud.model.deployed`.
**Business Value:** Managed Kafka for event-driven architecture with automatic topic provisioning.
**Acceptance Criteria:**
- MSK cluster with 3 brokers (prod) or 1 broker (dev).
- 7 topics created via `aws_msk_cluster` configuration or Lambda.
- Topics: 3 partitions (prod), 1 partition (dev), replication factor 2 (prod).
- IAM policies for backend (produce + consume) and ml-service (consume + produce).
- Outputs: `bootstrap_brokers`, `zookeeper_connect`, `topic_arns`.
**Technical Notes:** Use `aws_msk_cluster` with `kafka_version=3.6.0`. Use `aws_msk_configuration` for server properties. For topic creation, use `aws_msk_cluster_policy` or a Lambda function triggered on cluster creation. Use IAM auth (SASL/IAM) for production.
**Dependencies:** FRAUD-280

### FRAUD-284 — AWS secrets management (Secrets Manager + IAM)
**Type:** Technical Task · **Epic:** EPIC-48 · **Complexity:** M · **Owner:** DO
**Description:** Create `modules/aws/secrets` with AWS Secrets Manager for all sensitive values: DB password, JWT secret, Anthropic API key, Redis password. ECS task definitions reference secrets via `secrets` block. IAM roles with least-privilege access.
**Business Value:** Secrets never in environment variables or Terraform state; rotated via console.
**Acceptance Criteria:**
- Secrets created for: `POSTGRES_PASSWORD`, `JWT_SECRET`, `ANTHROPIC_API_KEY`, `REDIS_PASSWORD`.
- ECS task role has `secretsmanager:GetSecretValue` only.
- Secrets referenced in task definition via `valueFrom`.
- Terraform uses `ignore_changes` on secret values.
- Outputs: `secret_arns` map.
**Technical Notes:** Use `aws_secretsmanager_secret` with `recovery_window_in_days=7`. Use `aws_iam_role` with `aws_iam_policy_attachment`. Task definition `secrets` block: `valueFrom = aws_secretsmanager_secret.arn:secret_key::`.
**Dependencies:** FRAUD-281, FRAUD-282, FRAUD-283

### FRAUD-285 — GCP Firebase Auth module (Angular frontend authentication)
**Type:** Infrastructure · **Epic:** EPIC-48 · **Complexity:** M · **Owner:** DO
**Description:** Create `modules/gcp/firebase-auth` with Firebase project, Authentication (email/password + Google social login), and IAM bindings. Configure Firebase Auth for Angular frontend with `@angular/fire`. Output Firebase config for `environment.ts`.
**Business Value:** Production-grade auth with social login, MFA, and email verification.
**Acceptance Criteria:**
- Firebase project created with Authentication enabled.
- Email/password provider enabled.
- Google social login provider enabled.
- Firebase config outputs: `apiKey`, `authDomain`, `projectId`, `storageBucket`, `messagingSenderId`, `appId`.
- IAM binding for Firebase Admin SDK (backend service account).
- Outputs: `firebase_config` map, `firebase_project_id`.
**Technical Notes:** Use `google_firebase_project`, `google_identity_platform_config`. Use `google_service_account` for backend. Use `google_iam_binding` for `firebaseauth.admin` role. Firebase config from `google_firebase_web_app`.
**Dependencies:** FRAUD-279

### FRAUD-286 — Azure AI/ML module (Azure OpenAI + Foundry)
**Type:** Infrastructure · **Epic:** EPIC-48 · **Complexity:** L · **Owner:** DO
**Description:** Create `modules/azure/ai-ml` with Azure OpenAI Service (GPT-4 for investigation copilot, embeddings for fraud patterns), Azure AI Foundry for model deployment/evaluation, and Key Vault for API keys. Configure RBAC for ml-service to call Azure OpenAI.
**Business Value:** Enterprise-grade AI services for fraud investigation copilot and model evaluation.
**Acceptance Criteria:**
- Azure OpenAI Service with GPT-4 deployment.
- Azure AI Foundry project for model evaluation.
- Key Vault stores Azure OpenAI keys.
- RBAC: ml-service managed identity has `Cognitive Services OpenAI User` role.
- Outputs: `openai_endpoint`, `openai_deployment_name`, `foundry_project_id`, `keyvault_uri`.
**Technical Notes:** Use `azurerm_cognitive_account` with `kind=OpenAI`. Use `azurerm_cognitive_deployment` for GPT-4. Use `azurerm_machine_learning_workspace` for Foundry. Use `azurerm_key_vault` with RBAC model. Use `azurerm_user_assigned_identity` for ml-service.
**Dependencies:** FRAUD-279

### FRAUD-287 — Environment configs (dev/staging/prod per cloud)
**Type:** Technical Task · **Epic:** EPIC-48 · **Complexity:** M · **Owner:** DO
**Description:** Create `environments/{dev,staging,prod}/main.tf` that instantiates modules with environment-specific variables. Dev: single-AZ, small instances, no HA. Staging: multi-AZ, medium instances, HA. Prod: multi-AZ, large instances, HA, backups, monitoring.
**Business Value:** Consistent environments with appropriate sizing and HA per stage.
**Acceptance Criteria:**
- `environments/dev/main.tf` provisions minimal stack.
- `environments/staging/main.tf` provisions HA stack.
- `environments/prod/main.tf` provisions full production stack.
- Each environment has `terraform.tfvars` with sizing parameters.
- `terraform plan` shows correct diff per environment.
**Technical Notes:** Use `module` blocks referencing `../../modules/aws`, `../../modules/gcp`, `../../modules/azure`. Variables: `instance_size`, `multi_az`, `backup_retention`, `min_capacity`, `max_capacity`. Use `count` or `for_each` to toggle HA features.
**Dependencies:** FRAUD-280, FRAUD-285, FRAUD-286

### FRAUD-288 — CI/CD for Terraform (GitHub Actions plan/apply)
**Type:** Infrastructure · **Epic:** EPIC-48 · **Complexity:** M · **Owner:** DO
**Description:** Create `.github/workflows/terraform.yml` that runs `terraform plan` on PR and `terraform apply` on merge to main. Separate jobs per cloud provider. Require manual approval for prod. Post plan output as PR comment. Use OIDC for cloud auth.
**Business Value:** Infrastructure changes reviewed and applied through PRs with full audit trail.
**Acceptance Criteria:**
- `terraform plan` runs on PR for all 3 providers.
- `terraform apply` runs on merge to main (dev only).
- Prod requires manual approval (GitHub environment protection).
- OIDC auth: AWS (IAM OIDC), GCP (Workload Identity), Azure (Federated Credentials).
- Plan output posted as PR comment.
**Technical Notes:** Use `hashicorp/setup-terraform`. AWS: `aws-actions/configure-aws-credentials` with OIDC. GCP: `google-github-actions/auth` with Workload Identity. Azure: `azure/login` with federated credentials. Use `terraform-plan` + `terraform-apply` with `comment` feature.
**Dependencies:** FRAUD-287, FRAUD-265

### FRAUD-289 — Terraform documentation + cost estimation
**Type:** Story · **Epic:** EPIC-48 · **Complexity:** M · **Owner:** DO
**Description:** Create `infrastructure/terraform/README.md` with architecture overview (AWS primary, GCP auth, Azure AI), module reference, deployment guide, cost estimation per environment, and troubleshooting. Use `infracost` for PR cost diffs.
**Business Value:** Clear deployment documentation; cost visibility before provisioning.
**Acceptance Criteria:**
- README covers all three clouds with architecture diagram.
- Cost estimation table per environment (dev/staging/prod).
- Module reference with inputs/outputs.
- Mermaid diagram showing multi-cloud topology.
- `infracost` integration for PR cost comments.
**Technical Notes:** Use `infracost/infracost` GitHub Action. Mermaid diagram showing AWS (primary) + GCP (auth) + Azure (AI). Use `terraform-docs` for auto-generated module docs.
**Dependencies:** FRAUD-287

---

# Importing into Linear

- **Phase 12** → `phase:12` label.
- **Epic (EPIC-43…48)** → project **milestone** and `Epic`-labelled **parent issue** inside the "Fraud Detection" project.
- **Ticket (FRAUD-260…289)** → **sub-issue** of its epic's parent issue, assigned to that epic's milestone.

**Field mapping**:
- Title → `FRAUD-### — Title`
- Description / Business Value / Acceptance Criteria / Technical Notes → issue description.
- Complexity → **Estimate**: `XS=1, S=2, M=3, L=5, XL=8`.
- Type → Story→`type:story`, Technical Task→`type:tech-task`, Infrastructure→`type:infra`.
- Domain → `domain:infra` on every ticket; plus area: `area:docker` (E43), `area:ci-cd` (E44), `area:testing` (E45), `area:deployment` (E46), `area:docs` (E47), `area:terraform` (E48).
- Team → `team:devops` (DO).
- `Dependencies` → add as **"blocked by"** relations.

---

## Cross-Repo Dependency Map

| Ticket | Depends On (other repos) |
|---|---|
| FRAUD-260 | backend/FRAUD-208 (Docker Compose), ml-service/FRAUD-163 (Docker Compose) |
| FRAUD-264 | backend/FRAUD-211 (Flyway migrations) |
| FRAUD-265 | All repos' CI pipelines |
| FRAUD-266 | backend/FRAUD-214 (OpenAPI), ml-service/FRAUD-059 (POST /predict) |
| FRAUD-267 | backend/FRAUD-234 (SSE), frontend/FRAUD-245 (SSE client) |
| FRAUD-271 | backend/FRAUD-229 (ML client), ml-service/FRAUD-059 (POST /predict) |
| FRAUD-275 | backend/FRAUD-233 (CI), frontend/FRAUD-259 (README) |
| FRAUD-276 | backend/FRAUD-214 (OpenAPI), ml-service/FRAUD-203 (ARCHITECTURE.md) |
| FRAUD-285 | GCP Firebase project setup |
| FRAUD-286 | Azure OpenAI + Foundry provisioning |

> Import these as **"blocked by"** relations in Linear after the ticket import.

---

*Shared infrastructure backlog — 6 epics (EPIC-43 → EPIC-48), 30 tickets (FRAUD-260 → FRAUD-289), Phase 12–13. Connects the platform backlog (FRAUD-001 → 161), ML backlog (FRAUD-162 → 207), backend backlog (FRAUD-208 → 236), and frontend backlog (FRAUD-237 → 259).*