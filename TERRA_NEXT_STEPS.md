# Next steps: GitHub, Dockstore, and Terra

## GitHub repo setup

- **Default branch**: use `main` (this repo’s CI expects `main`).
- **Tagging/versioning**: create a release/tag whenever you want a stable Dockstore version (e.g. `v0.1.0`, `v1.0.0`).
- **CI**: confirm GitHub Actions runs `Validate WDLs` on push/PR.

## Docker image (DockerHub: `plasmogenepi`)

This repo’s `Dockerfile` builds a pipeline runtime image that **clones** the Nextflow repository at build time and copies its `bin/` scripts into the image.

Recommended steps:

- Decide the exact **pipeline git ref** to bundle:
  - `PLASMODIUMDRUGRES_REF=<tag-or-commit>`
  - `PMOTOOLS_REF=<tag-or-commit>`
- Build and push:
  - `docker build --build-arg PLASMODIUMDRUGRES_REF=... --build-arg PMOTOOLS_REF=... -t plasmogenepi/plasmodiumdrugres:<version> .`
  - `docker push plasmogenepi/plasmodiumdrugres:<version>`
- Update Terra inputs (or workflow defaults) to use the pushed tag.

## Dockstore setup

- Ensure `.dockstore.yml` is present at repo root and references:
  - `primaryDescriptorPath: /WDL/Workflows/plasmodiumdrugres.wdl`
  - `readMePath: /PLASMODIUMDRUGRES_INTERFACE.md`
- In Dockstore:
  - Register the GitHub repo
  - Enable automatic refresh on new tags/releases
  - Select the `plasmodiumdrugres` workflow entry

## Terra setup + running

### 1) Add workflow from Dockstore

- In Terra, open your workspace → **Workflows** tab → find/import from Dockstore.

### 2) Provide inputs

See `PLASMODIUMDRUGRES_INTERFACE.md` for the input contract. Key rules:

- Provide **exactly one** of `pmo` or `allele_table`.
- Always provide:
  - `loci_of_interest_bed`
  - `loci_groups`
- If using `allele_table`, also provide `panel_info_bed`.
- To run per-population, provide either:
  - `population_assignment`, or
  - `pmo_population_fields` (with `pmo`)

### 3) Outputs

Terra will collect outputs from the workflow outputs:

- Final deliverables:
  - `sl_summary.tsv`
  - `ml_summary.tsv`
  - `sl_from_ml_summary.tsv`
- Plus translated loci outputs under `translated_loci/*` (exposed as workflow outputs).

### 4) Debugging

- Use the **Job History** page to inspect failed calls.
- For task-level debugging, check:
  - `stderr`, `stdout`, and `commandScript` in the Cromwell metadata
- If a run fails due to missing scripts inside the container, confirm the Docker image tag and `PLASMODIUMDRUGRES_REF` used at build time.

