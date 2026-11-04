#!/usr/bin/env bash
# Build the python-scripts-only image and push it to Artifact Registry.
# Usage: scripts/build_and_push_python_docker.sh [tag]   (default tag: short git SHA, or timestamp)
set -euo pipefail


REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
#IMAGE="us-central1-docker.pkg.dev/operations-portal-427515/mad4hatter-drugres/python-scripts"
IMAGE="us.gcr.io/broad-dsp-lrma/mad4hatter-drugres-python"
TAG="${1:-$(git -C "$REPO_ROOT" rev-parse --short HEAD 2>/dev/null || date +%Y%m%d-%H%M%S)}"

# Let docker authenticate to Artifact Registry (needs `gcloud auth login` done once)
#gcloud auth configure-docker us-central1-docker.pkg.dev --quiet

# Terra runs on linux/amd64, so force that platform (matters on Apple Silicon)
docker build --platform linux/amd64 \
  -t "${IMAGE}:${TAG}" \
  -t "${IMAGE}:latest" \
  -f "${REPO_ROOT}/Dockerfile.python" \
  "${REPO_ROOT}"

docker push "${IMAGE}:${TAG}"
docker push "${IMAGE}:latest"

echo "Pushed ${IMAGE}:${TAG} and ${IMAGE}:latest"
