# pg4ai: PostgreSQL 16 + Apache AGE + pgvector

Multi-Arch Docker Image (`linux/amd64`, `linux/arm64`) auf Basis von `postgres:16` mit:

- Apache AGE `PG16/v1.5.0-rc0` (Upstream-Tag fuer PG16)
- pgvector `v0.7.0`

Die Extensions werden beim ersten DB-Start automatisch via Init-Skript aktiviert.

## Lokale Nutzung

Build und Start mit Compose:

```bash
docker compose up --build
```

Smoke-Test gegen ein gebautes Image:

```bash
IMAGE_REF=pg4ai:dev ./scripts/smoke-test.sh
```

## Make Targets

```bash
make build-amd64
make build-arm64
make test-amd64
make test-arm64
make build-multiarch REGISTRY_IMAGE=ghcr.io/<owner>/<repo> IMAGE_TAG=latest
```

## GitHub Actions

Workflow: `.github/workflows/ci-multiarch.yml`

- PRs: Build fuer `amd64` + `arm64` (QEMU), Smoke-Tests auf `amd64`.
- Push auf Branches: identische Tests.
- Push auf Default-Branch: Publish nach GHCR mit Tags `sha-<shortsha>` und `latest`.
- Push auf `v*` Tag: Publish nach GHCR mit Versionstag.

## Lizenz

- Dieses Projekt: `Apache-2.0` (siehe `LICENSE`)
- Drittkomponenten im Image: siehe `THIRD_PARTY_LICENSES.md`
