# PlasmodiumDrugRes WDL interface (parity with Nextflow)

This document defines the **user-facing inputs and outputs** for the WDL implementation of the `plasmodiumdrugres` pipeline, and how these map to the current Nextflow pipeline in `~/Documents/git_projects/plasmodiumdrugres/`.

**Source of truth (Nextflow)**:

- Parameter schema: `~/Documents/git_projects/plasmodiumdrugres/nextflow_schema.json`
- Defaults: `~/Documents/git_projects/plasmodiumdrugres/nextflow.config`
- Workflow wiring / branching: `~/Documents/git_projects/plasmodiumdrugres/workflows/plasmodiumdrugres.nf`
- Input validation and PMO/population-field normalization: `~/Documents/git_projects/plasmodiumdrugres/subworkflows/local/utils_nfcore_plasmodiumdrugres_pipeline/main.nf`

## Inputs

### Required

- **`pmo`** (`File`): PMO JSON file.
- **`filtered_allele_data`** (`File`): TSV/CSV containing microhaplotypes.
- **`amplicon_info`** (`File`): Amplicon info TSV. Requires the following headers (`target_name`, `chrom`, 
  `insert_start`, and `insert_end`.) 
- **`reference`** (`File`): Reference FASTA of insert sequences, one record per target_name
- **`billing_project`** (`String`): Terra billing project of the workspace to update (e.g. `my-billing-project`). Used by the final `resmarkers_to_terra` step.
- **`workspace_name`** (`String`): Name of the Terra workspace whose `sample` table is updated (the workspace name only, not the `billing_project/workspace_name` pair). Used by the final `resmarkers_to_terra` step.

### Required files

- **`loci_of_interest_bed`** (`File`): BED of loci of interest (single-locus estimates are computed at these loci).
- **`loci_groups`** (`File`): TSV/CSV defining multi-locus groups (multi-locus estimates are computed for these groups).

### Optional grouping / population splitting

You can run either:

- **Single population** (default): no splitting is performed; results are labeled using `population_label` (default `pop1`).
- **Per-population**: split input tables by population and compute outputs for each population.

Inputs controlling this:

- **`population_assignment`** (`File?`): TSV/CSV mapping `specimen_name` → `population`.
- **`pmo_population_fields`** (`String?`, default `null`): comma-separated list of PMO specimen metadata fields; used **only** when `pmo` is provided and `population_assignment` is not provided.
- **`pmo_population_separator`** (`String`, default `_`): join string used when building the population label from `pmo_population_fields`.
- **`population_label`** (`String`, default `pop1`): used only when no population assignment is available.

**Branching rule (parity target)**:

- `has_population_assignment = (population_assignment is provided) OR (pmo is provided AND pmo_population_fields is provided)`

### Optional references (PMO mode only)

These are used when generating a panel BED from PMO and adding reference sequences to it:

- **`targeted_reference`** (`File?`, default `null`): FASTA containing only the targets.
- **`genome_reference`** (`File?`, default `null`): FASTA containing the full genome.

Behavior (parity target):

- If both are provided, prefer `targeted_reference` (Nextflow warns and prefers targeted reference).

### Method selection (defaults from Nextflow)

- **`mlaf_method`** (`String`, default `naive`): one of `naive`, `MLBM`, `FEM`.
  - **`naive_mlaf_method`** (`String`, default `wsaf_prop`): passed to the naive multi-locus method.
- **`slaf_method`** (`String`, default `naive`): one of `naive`, `IDM`, `mhaps_freq`.
  - **`naive_slaf_method`** (`String`, default `read_count_prop`): passed to the naive single-locus method.
  - `mhaps_freq` uses DCIFER in the current Nextflow pipeline.

### Optional tuning parameters (passed through to scripts)

- **`translate_loci_extra_args`** (`String`, default `""`)
- **`mlbm_wrapper_aa_specimen_occurence_cut_off`** (`Int?`, default `null`)
- **`naive_multilocus_wsaf_cut_off`** (`Float?`, default `null`)
- **`dcifer_slaf_wrapper_coi_lrank`** (`Int?`, default `null`)
- **`dcifer_slaf_wrapper_qstart`** (`Float?`, default `null`)
- **`dcifer_slaf_wrapper_tol`** (`Float?`, default `null`)

### Output directory convention

To mimic Nextflow’s `outdir` organization (even though Terra does not require explicit staging), the WDL workflow will write deliverables under:

- **`outdir`** (`String`, default `output`)

## Outputs

On **Terra**, the workflow exposes exactly **seven** outputs as **`String` URIs** from the staging step (same idea as `mad4hatter-wdl` `move_outputs`). When Cromwell sees a `gs://fc-…/…` path for the merged `ml_summary`, files are copied with **`gcloud`** to **`gs://fc-…/<outdir>/<timestamp>/`** using their original basenames. On **local Cromwell** (paths like `/Users/…` or `tests/input/…`), the same task uses **`cp`** into **`<execution_dir>/<outdir>/<timestamp>/`** and outputs absolute local paths instead.

Optional input **`workspace_bucket`** (`String?`): set to the workspace bucket id (e.g. `fc-15e572f9-33a3-4a1e-8534-099df773bfbf`, no `gs://` prefix) if your backend localizes files before WDL evaluates paths and automatic `gs://fc-…` detection fails—then GCS staging is forced.

`outdir` must be alphanumeric plus `_` or `-` only (validated at workflow start).

Workflow output names (each value is a `gs://…` path to the file):

- **`ml_summary`** → `ml_summary.tsv`
- **`sl_summary`** → `sl_summary.tsv`
- **`sl_from_ml_summary`** → `sl_from_ml_summary.tsv`
- **`amino_acid_calls`** → `amino_acid_calls.tsv.gz`
- **`collapsed_amino_acid_calls`** → `collapsed_amino_acid_calls.tsv.gz`
- **`loci_covered_by_target_samples_info`** → `loci_covered_by_target_samples_info.tsv`
- **`loci_of_interest_for_target_for_microhap`** → `loci_of_interest_for_target_for_microhap.tsv.gz`

### Terra `sample` table update

As its last step, the workflow runs the `resmarkers_to_terra` task (`python/resmarkers_to_terra.py`). It takes the collapsed amino acid calls from `translate_loci_of_interest` and pivots them to one row per `specimen_name`, then upserts the rows into the **`sample`** data table of the workspace given by **`billing_project`** / **`workspace_name`**.

- **`sample_id`** is the unique `specimen_name` from the collapsed calls.
- One column per gene/position is added, named **`resmarker_<gene>_<aa_position>`** (e.g. `resmarker_dhfr-ts_164`), holding the `aa` value. If a specimen has several different `aa` values at the same gene/position (a mixed call), the distinct values are sorted and joined with `/` (e.g. `F/Y`). Specimens with no call at a position have that attribute unset.
- The existing `sample` table is **not** deleted: rows with a matching `sample_id` are updated and other rows and columns are left unchanged.
- This step produces no workflow output; the same table is also written to `sample_resmarkers.tsv` in the task's execution directory.

Per-population merge artifacts and intermediate `translated_loci/` paths are still computed inside the run but are **not** listed as workflow outputs; use the staged URIs above for downloads and downstream tooling.


