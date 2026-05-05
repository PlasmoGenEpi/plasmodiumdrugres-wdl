# PlasmodiumDrugRes WDL interface (parity with Nextflow)

This document defines the **user-facing inputs and outputs** for the WDL implementation of the `plasmodiumdrugres` pipeline, and how these map to the current Nextflow pipeline in `~/Documents/git_projects/plasmodiumdrugres/`.

**Source of truth (Nextflow)**:

- Parameter schema: `~/Documents/git_projects/plasmodiumdrugres/nextflow_schema.json`
- Defaults: `~/Documents/git_projects/plasmodiumdrugres/nextflow.config`
- Workflow wiring / branching: `~/Documents/git_projects/plasmodiumdrugres/workflows/plasmodiumdrugres.nf`
- Input validation and PMO/population-field normalization: `~/Documents/git_projects/plasmodiumdrugres/subworkflows/local/utils_nfcore_plasmodiumdrugres_pipeline/main.nf`

## Inputs

### Required: choose exactly one input mode

Provide **exactly one** of:

- **`pmo`** (`File`): PMO JSON file.
- **`allele_table`** (`File`): TSV/CSV containing microhaplotypes. When using this mode, `panel_info_bed` is also required.

### Required files

- **`loci_of_interest_bed`** (`File`): BED of loci of interest (single-locus estimates are computed at these loci).
- **`loci_groups`** (`File`): TSV/CSV defining multi-locus groups (multi-locus estimates are computed for these groups).

### Required iff using `allele_table`

- **`panel_info_bed`** (`File`): BED defining panel target coordinates.

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

### Final deliverables (top-level)

These match the Nextflow `CONCAT_TABLES` outputs:

- **`sl_summary.tsv`**
- **`ml_summary.tsv`**
- **`sl_from_ml_summary.tsv`**

### Translated loci outputs

These match the Nextflow `TRANSLATE_LOCI_OF_INTEREST` outputs (under `translated_loci/`):

- **`translated_loci/collapsed_amino_acid_calls.tsv.gz`**
- **`translated_loci/amino_acid_calls.tsv.gz`**
- **`translated_loci/loci_covered_by_target_samples_info.tsv`**
- **`translated_loci/loci_of_interest_for_target_for_microhap.tsv.gz`**

### Per-population intermediate deliverables (optional)

When population splitting is enabled, the pipeline produces per-population summaries and split tables. The WDL may optionally expose these as workflow outputs for debugging/inspection:

- `<pop>.sl_summary.tsv`, `<pop>.ml_summary.tsv`, `<pop>.sl_from_ml_summary.tsv`
- Per-pop split tables (`*.collapsed_amino_acid_calls.tsv.gz`, `*.allele_table.tsv.gz`) and `unmapped_*` text files.

