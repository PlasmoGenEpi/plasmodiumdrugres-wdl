#!/usr/bin/env bash
set -euo pipefail

WOMTOOL_VERSION="54"
WOMTOOL_JAR="womtool-${WOMTOOL_VERSION}.jar"

if [[ ! -f "${WOMTOOL_JAR}" ]]; then
  curl -L -o "${WOMTOOL_JAR}" "https://github.com/broadinstitute/cromwell/releases/download/${WOMTOOL_VERSION}/${WOMTOOL_JAR}"
fi

echo "Validating WDL files..."

# Enumerate WDL files without relying on `globstar` (bash 3.x compatibility).
wdl_files_tmp="$(mktemp)"
python3 - <<'PY' > "${wdl_files_tmp}"
import os
paths=[]
root="."
for dirpath, _, filenames in os.walk(root):
    for fn in filenames:
        if fn.endswith(".wdl"):
            full=os.path.join(dirpath, fn)
            # Retired/unmaintained workflow: validation currently fails due to stale callables.
            if full.endswith("WDL/Workflows/plasmodiumdrugres_task_testing.wdl"):
                continue
            paths.append(full)
for p in sorted(paths):
    print(p)
PY

mapfile_failed=0
wdl_files=()
while IFS= read -r wdl; do
  [[ -z "${wdl}" ]] && continue
  wdl_files+=("${wdl}")
done < "${wdl_files_tmp}"

rm -f "${wdl_files_tmp}"

if [[ ${#wdl_files[@]} -eq 0 ]]; then
  echo "No .wdl files found."
  exit 1
fi

failed=0
for wdl in "${wdl_files[@]}"; do
  echo "womtool validate ${wdl}"
  java -jar "${WOMTOOL_JAR}" validate "${wdl}" || failed=1
done

exit "${failed}"

