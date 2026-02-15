# Contributing

Danke fuer dein Interesse an Beitragen zu `pg4ai`.

## Voraussetzungen

- Docker mit Buildx
- GNU Make
- Bash

## Lokale Checks

Vor einem Pull Request bitte folgende Checks lokal ausfuehren:

```bash
make test-amd64
```

Hinweis: `arm64`-Builds werden in CI gebaut. Runtime-Smoke-Tests laufen in CI nur auf `amd64`.

## Pull Requests

- Erstelle kleine, fokussierte Aenderungen.
- Aktualisiere Dokumentation bei Verhaltensaenderungen.
- Beschreibe im PR klar: Problem, Loesung, Auswirkungen.

## Commit-Konvention

Empfohlenes Format:

- `feat: ...`
- `fix: ...`
- `ci: ...`
- `docs: ...`

## Lizenz

Mit einem Beitrag bestaetigst du, dass dein Code unter der Projektlizenz (`Apache-2.0`) veroeffentlicht werden darf.
