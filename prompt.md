# PRD: Multi-Arch PostgreSQL Container with Apache AGE & pgvector

## 1. Zielsetzung

Bereitstellung eines produktionsreifen Docker-Images, das die Graph-Datenbank-Funktionalität von **Apache AGE** mit der Vektorsuche von **pgvector** kombiniert. Das Image muss nativ auf **amd64** (Intel/AMD) und **arm64** (Apple Silicon/AWS Graviton) laufen.

## 2. Technische Spezifikationen

### 2.1 Basis-Komponenten

* **Base Image:** `postgres:16` (Debian-basiert für maximale Kompatibilität beim Kompilieren).
* **Apache AGE:** Version `v1.5.0` (kompatibel mit PG16).
* **pgvector:** Version `v0.7.0` oder aktuellster Stable-Release.

### 2.2 Build-Anforderungen

* **Multi-Stage Build:** * *Stage 1 (Builder):* Installation von `build-essential`, `postgresql-server-dev-16`, `bison`, `flex`, `git`. Kompilierung beider Extensions.
* *Stage 2 (Final):* Kopieren der `.so` Dateien und Control-Files in ein sauberes `postgres:16` Image, um die Image-Größe minimal zu halten (~250MB statt >800MB).


* **Architektur-Support:** Volle Unterstützung für `linux/amd64` und `linux/arm64` via Docker Buildx.

### 2.3 Runtime-Konfiguration

* Automatisches Laden der Extensions beim Datenbank-Start über ein Init-Skript in `/docker-entrypoint-initdb.d/`.
* Standard-User/Passwort/DB über offizielle Postgres-Umgebungsvariablen.

---

## 3. User Stories für Claude Code

| ID | Story | Akzeptanzkriterien |
| --- | --- | --- |
| **US.1** | **Multi-Stage Dockerfile** | Erstelle ein Dockerfile, das AGE und pgvector aus den Sourcen baut und in ein schlankes Final-Image überführt. |
| **US.2** | **Extension Init** | Erzeuge ein Shell- oder SQL-Skript, das `CREATE EXTENSION age;` und `CREATE EXTENSION vector;` beim ersten Start ausführt. |
| **US.3** | **Build-Automatisierung** | Erstelle ein `Makefile` oder ein Bash-Skript, das den `docker buildx` Befehl für beide Plattformen kapselt. |
| **US.4** | **Infrastruktur-Test** | Erstelle eine `docker-compose.yml` zur Validierung, inklusive eines Healthchecks. |

---

## 4. Erfolgskriterien (Test-Suite)

Nach dem Start des Containers müssen folgende Befehle erfolgreich sein:

1. **Vektor-Check:** `SELECT '[1,2,3]'::vector;`
2. **Graph-Check:** `SELECT * FROM ag_catalog.create_graph('my_graph');`
3. **Architektur-Check:** `docker inspect <image_id>` zeigt das korrekte `Architecture` Flag für das jeweilige Host-System.

---

## 5. Deployment & Release

* **Registry:** Ziel ist ein Public Repository (z.B. GitHub Packages oder Docker Hub).
* **CI/CD:** GitHub Action Workflow zur automatischen Erstellung bei Änderungen am Dockerfile.


