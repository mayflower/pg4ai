#!/usr/bin/env bash
set -Eeuo pipefail

IMAGE_REF="${IMAGE_REF:-}"
EXPECT_ARCH="${EXPECT_ARCH:-}"
POSTGRES_USER="${POSTGRES_USER:-postgres}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-postgres}"
POSTGRES_DB="${POSTGRES_DB:-pg4ai}"
STARTUP_TIMEOUT="${STARTUP_TIMEOUT:-90}"
CONTAINER_NAME="${CONTAINER_NAME:-pg4ai-smoke-$$-$RANDOM}"
RUN_PLATFORM="${RUN_PLATFORM:-}"

if [[ -z "${IMAGE_REF}" ]]; then
  echo "IMAGE_REF is required."
  exit 64
fi

cleanup() {
  docker rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true
}
trap cleanup EXIT

echo "Starting container ${CONTAINER_NAME} from ${IMAGE_REF} ..."
run_args=()
if [[ -n "${RUN_PLATFORM}" ]]; then
  run_args+=(--platform "${RUN_PLATFORM}")
elif [[ -n "${EXPECT_ARCH}" ]]; then
  run_args+=(--platform "linux/${EXPECT_ARCH}")
fi

if ! docker run -d \
  "${run_args[@]}" \
  --name "${CONTAINER_NAME}" \
  -e POSTGRES_USER="${POSTGRES_USER}" \
  -e POSTGRES_PASSWORD="${POSTGRES_PASSWORD}" \
  -e POSTGRES_DB="${POSTGRES_DB}" \
  "${IMAGE_REF}" >/dev/null; then
  echo "Container failed to start."
  exit 10
fi

elapsed=0
until docker exec "${CONTAINER_NAME}" pg_isready -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" >/dev/null 2>&1; do
  if (( elapsed >= STARTUP_TIMEOUT )); then
    echo "Database readiness timeout after ${STARTUP_TIMEOUT}s."
    docker logs "${CONTAINER_NAME}" || true
    exit 20
  fi
  sleep 2
  elapsed=$((elapsed + 2))
done

ext_wait=0
until docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" "${CONTAINER_NAME}" \
  psql -v ON_ERROR_STOP=1 -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -Atqc \
  "SELECT count(*) FROM pg_extension WHERE extname IN ('age', 'vector');" 2>/dev/null | grep -qx "2"; do
  if (( ext_wait >= STARTUP_TIMEOUT )); then
    echo "Extension init timeout after ${STARTUP_TIMEOUT}s."
    docker logs "${CONTAINER_NAME}" || true
    exit 20
  fi
  sleep 2
  ext_wait=$((ext_wait + 2))
done

echo "Running vector extension check ..."
if ! docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" "${CONTAINER_NAME}" \
  psql -v ON_ERROR_STOP=1 -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" \
  -c "SELECT '[1,2,3]'::vector;" >/dev/null; then
  echo "Vector SQL check failed."
  docker logs "${CONTAINER_NAME}" || true
  exit 30
fi

echo "Running Apache AGE graph check ..."
if ! docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" "${CONTAINER_NAME}" \
  psql -v ON_ERROR_STOP=1 -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" \
  -c "SELECT * FROM ag_catalog.create_graph('my_graph');" >/dev/null; then
  echo "AGE SQL check failed."
  docker logs "${CONTAINER_NAME}" || true
  exit 30
fi

if [[ -n "${EXPECT_ARCH}" ]]; then
  actual_arch="$(docker image inspect "${IMAGE_REF}" --format '{{.Architecture}}')"
  if [[ "${actual_arch}" != "${EXPECT_ARCH}" ]]; then
    echo "Architecture mismatch: expected ${EXPECT_ARCH}, got ${actual_arch}."
    exit 40
  fi
fi

echo "Smoke test passed for ${IMAGE_REF}."
