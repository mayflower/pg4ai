# pg4ai: PostgreSQL 18.3 + Graph + Vector + Hybrid Search

Multi-Arch Docker Image (`linux/amd64`, `linux/arm64`) auf Basis von `postgres:18.3` fuer AI-nahe Workloads.

## Enthaltene Funktionalitaet

- Apache AGE `PG18/v1.7.0-rc0`: Property-Graph und Cypher fuer Graph-RAG und Beziehungsabfragen.
- pgvector `v0.8.2`: Embeddings, ANN-Indizes und semantische Aehnlichkeitssuche.
- `pg_trgm` + `unaccent`: typo-tolerante und sprachrobuste lexikalische Suche.

Alle Extensions werden beim ersten DB-Start automatisch aktiviert (`docker/init/01-extensions.sql`).

## Wo Das Fuer AI Eingesetzt Wird

1. Ingestion-Pipeline:
- Dokumente/Chunks schreiben, Embeddings erzeugen und als `vector` speichern.
- Optional Entitaeten/Beziehungen parallel als Graphknoten/-kanten ablegen.

2. Online Retrieval Layer:
- Semantische Suche mit `pgvector` (k-nearest neighbors auf Embeddings).
- Lexikalische Suche mit FTS + `pg_trgm` + `unaccent`.
- Hybrid Retrieval: beide Scores zusammenfuehren und als Kontext fuer das LLM liefern.

3. Reasoning / Context Expansion:
- Mit AGE Nachbarschaften, Pfade oder Abhaengigkeiten aus dem Graphen ziehen.
- Ergebnis mit Vektor/FTS-Hits mergen (Graph-RAG).

## Schnelle SQL-Muster

### 1. Semantische Suche mit pgvector

```sql
CREATE TABLE documents (
  id bigserial PRIMARY KEY,
  content text NOT NULL,
  embedding vector(1536) NOT NULL
);

-- Beispiel: ANN-Index (Operator Class je nach Distanzmetrik auswaehlen)
CREATE INDEX documents_embedding_hnsw_idx
  ON documents USING hnsw (embedding vector_l2_ops);

-- Top-k nearest neighbors
SELECT id, content
FROM documents
ORDER BY embedding <-> '[0.01,0.02,0.03]'::vector
LIMIT 10;
```

### 2. Lexikalische/typo-tolerante Suche

```sql
-- FTS + unaccent
SELECT id, content
FROM documents
WHERE to_tsvector('simple', unaccent(content))
      @@ plainto_tsquery('simple', unaccent('hotel berlin'));

-- Trigram similarity (fuzzy matching)
SELECT id, content, similarity(content, 'hotle berln') AS sim
FROM documents
WHERE content % 'hotle berln'
ORDER BY sim DESC
LIMIT 10;
```

### 3. Graph-RAG mit AGE

```sql
LOAD 'age';
SET search_path = ag_catalog, "$user", public;

SELECT *
FROM cypher('knowledge_graph', $$
  MATCH (q:Entity {name: 'PostgreSQL'})-[:RELATED_TO]->(n)
  RETURN n.name
$$) AS (name agtype);
```

## Lokale Nutzung

```bash
docker compose up --build
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

## CI / Quality

Workflow: `.github/workflows/ci-multiarch.yml`

- Quality-Gates: `actionlint`, `hadolint`, `shellcheck`.
- Build/Test: `amd64` + `arm64` (QEMU), Smoke-Tests auf `amd64`.
- Publish: auf Default-Branch und `v*` Tags nach GHCR.

## Lizenz

- Dieses Projekt: `Apache-2.0` (siehe `LICENSE`)
- Drittkomponenten im Image: siehe `THIRD_PARTY_LICENSES.md`
