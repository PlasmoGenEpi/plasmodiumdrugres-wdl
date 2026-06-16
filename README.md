# plasmodiumdrugres (WDL)

This pipeline is a WDL replicate of the Nextflow [plasmodiumdrugres](https://github.com/PlasmoGenEpi/plasmodiumdrugres) pipeline. Inputs, outputs, and methods match the Nextflow version; see [PLASMODIUMDRUGRES_INTERFACE.md](PLASMODIUMDRUGRES_INTERFACE.md) for the WDL input contract (also shown on the Dockstore workflow page).

It estimates single- and multi-locus allele frequencies at drug-resistance loci from PMO or allele-table input, and is intended for running on **Terra** via **Dockstore**.

## Inputs at a glance

- Provide **exactly one** of `pmo` or `allele_table`.
- Always provide `loci_of_interest_bed` and `loci_groups`.
- If using `allele_table`, also provide `panel_info_bed`.
- For per-population results, provide `population_assignment` or (PMO mode only) `pmo_population_fields`.
- Optional: `mlaf_method` (`naive`, `MLBM`, `FEM`) and `slaf_method` (`naive`, `IDM`, `mhaps_freq`); defaults match the Nextflow pipeline.

## Outputs

The workflow returns seven **`gs://` URIs** (summaries, translated loci tables, and related files), staged under `<outdir>/<timestamp>/` in your workspace bucket. See [PLASMODIUMDRUGRES_INTERFACE.md](PLASMODIUMDRUGRES_INTERFACE.md#outputs) for the full list.

## Repository layout

| Path | Purpose |
|------|---------|
| `WDL/Workflows/plasmodiumdrugres.wdl` | Main workflow |
| `PLASMODIUMDRUGRES_INTERFACE.md` | User-facing inputs and outputs |
| `Dockerfile` | Runtime image (`plasmogenepi/plasmodiumdrugres`) |
| `TERRA_NEXT_STEPS.md` | Maintainer notes (GitHub, DockerHub, Dockstore setup) |
