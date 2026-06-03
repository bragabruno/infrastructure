# Contributing to Fraud Prevention Platform — Infrastructure

## Prerequisites

- Docker Desktop (with Compose v2)
- Terraform >= 1.5
- Git
- [Doppler CLI](https://docs.doppler.com/docs/cli) (for secrets)

## Repository Layout

This is the **infrastructure** repo for the Fraud Prevention Platform polyrepo:

| Repo | Purpose |
|------|---------|
| `infrastructure` | Terraform, CI/CD, scripts, integration tests |
| `backend` | Java 21 / Spring Boot API |
| `ml-service` | Python 3.12 / FastAPI ML inference |
| `frontend` | Angular 19 analyst dashboard |

## Local Development

```bash
# Clone all repos into the same parent directory
mkdir FraudPreventionSystem && cd FraudPreventionSystem
git clone https://github.com/bragabruno/infrastructure.git
git clone https://github.com/bragabruno/backend.git
git clone https://github.com/bragabruno/ml-service.git
git clone https://github.com/bragabruno/frontend.git

# One-command setup
./infrastructure/scripts/setup.sh
```

## Branch Naming

- `feat/epic-XX-description` — feature work tied to an EPIC
- `fix/ticket-description` — bug fixes
- `chore/description` — maintenance tasks

## Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat(epic-48): add Terraform AWS networking module
fix(backend): correct Flyway migration ordering
chore: bump version to 0.2.0
```

## Pull Requests

1. Create a branch from `main`
2. Make changes and commit
3. Push branch and create PR
4. Fill in PR template (problem, solution, testing, limitations)
5. Link to Linear ticket
6. Wait for CI checks to pass
7. Request review if needed
8. Merge when approved

## Terraform

```bash
cd infrastructure/terraform/environments/dev
terraform init
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

Never commit secrets. Use `terraform.tfvars` for non-secret values and Doppler/Secrets Manager for secrets.

## CI/CD

- **ci.yml**: Runs on every push/PR. Backend, ml-service, frontend tests in parallel. Integration tests on merge to main.
- **terraform.yml**: Plan on PR, apply on merge. Dev auto-applies, staging/prod require manual approval.

## Scripts

| Script | What it does |
|--------|--------------|
| `scripts/setup.sh` | Full developer onboarding |
| `scripts/health.sh` | Health check all services |
| `scripts/kafka-init.sh` | Create Kafka topics |
| `scripts/db-init.sh` | Init DB + seed data |
| `scripts/validate-contracts.sh` | Cross-service contract validation |
| `scripts/release.sh` | Bump version and tag |

## Questions?

Open an issue or reach out to the team.
