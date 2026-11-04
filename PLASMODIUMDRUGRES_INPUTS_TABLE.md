| Input name | Description | Type | Required | Default |
|---|---|---|---|---|
| **`filtered_allele_data`** | Allele table of microhaplotypes (the MAD4HatTeR filtered allele data), converted to the pipeline's specimen/target/reads/seq format | `File` | Yes | - |
| **`amplicon_info`** | Amplicon info table with `target_name`, `chrom`, `insert_start` and `insert_end` columns; used to build the panel BED | `File` | Yes | - |
| **`reference`** | Reference FASTA of insert sequences, one record per `target_name` | `File` | Yes | - |
| **`loci_of_interest_bed`** | BED of loci of interest; single-locus estimates are computed at these loci | `File` | Yes | - |
| **`loci_groups`** | TSV/CSV defining multi-locus groups; multi-locus estimates are computed for these groups | `File` | Yes | - |
| **`pmo`** | PMO JSON file | `File?` | No | - |
| **`population_assignment`** | TSV/CSV mapping `specimen_name` to `population`; enables per-population results | `File?` | No | - |
| **`pmo_population_fields`** | Comma-separated PMO specimen metadata fields used to build the population label; used only when `pmo` is given and `population_assignment` is not | `String?` | No | - |
| **`pmo_population_separator`** | Join string used when building the population label from `pmo_population_fields` | `String` | No | `_` |
| **`population_label`** | Population label used when no population assignment is available | `String` | No | `pop1` |
| **`targeted_reference`** | FASTA containing only the targets (PMO mode); preferred over `genome_reference` if both are given | `File?` | No | - |
| **`genome_reference`** | FASTA containing the full genome (PMO mode) | `File?` | No | - |
| **`mlaf_method`** | Multi-locus allele frequency method: `naive`, `MLBM` or `FEM` | `String` | No | `naive` |
| **`naive_mlaf_method`** | Method passed to the naive multi-locus estimator | `String` | No | `wsaf_prop` |
| **`slaf_method`** | Single-locus allele frequency method: `naive`, `IDM` or `mhaps_freq` | `String` | No | `naive` |
| **`naive_slaf_method`** | Method passed to the naive single-locus estimator | `String` | No | `read_count_prop` |
| **`translate_loci_extra_args`** | Extra arguments passed to `translate_loci_of_interest` | `String` | No | `""` |
| **`outdir`** | Output directory name; letters, numbers, `_` and `-` only | `String` | No | `output` |
| **`billing_project`** | Terra billing project of the workspace whose `sample` table is updated; detected from the workspace this run was launched from when omitted | `String?` | No | (detected) |
| **`workspace_name`** | Name of the Terra workspace whose `sample` table is updated; detected from the workspace this run was launched from when omitted | `String?` | No | (detected) |
| **`sample_table`** | Terra data table the resmarker columns are written to; detected from the type of data the run was launched on (the submission's root entity) when omitted. The row id column is always `<sample_table>_id` | `String?` | No | (detected) |
| **`workspace_bucket`** | Terra workspace bucket id (e.g. `fc-…`, no `gs://`); set it only if automatic `gs://fc-…` detection and workspace detection both fail | `String?` | No | (detected) |
| **`docker_image`** | Docker image used by the pipeline tasks | `String` | No | `plasmogenepi/plasmodiumdrugres:wdl` |
