version 1.0

import "../Tasks/extract_allele_table/extract_allele_table.wdl" as extract_allele_table_t
import "../Tasks/translate_loci_of_interest/translate_loci_of_interest.wdl" as translate_loci_of_interest_t
import "../Tasks/estimate_allele_prevalence_naive/estimate_allele_prevalence_naive.wdl" as estimate_allele_prevalence_naive_t
import "../Subworkflows/pipeline_initialisation.wdl" as pipeline_initialisation_wf
import "../Subworkflows/estimate_mlaf.wdl" as estimate_mlaf_wf
import "../Subworkflows/estimate_slaf.wdl" as estimate_slaf_wf
import "../Subworkflows/merge_and_concat.wdl" as merge_and_concat_wf
import "../Tasks/split_table_by_population_map/split_table_by_population_map.wdl" as split_table_by_population_map_t
import "../Tasks/move_outputs/move_outputs.wdl" as move_outputs_t
import "../Tasks/utils/fail.wdl" as fail_t
import "../Tasks/make_panel_bed/make_panel_bed.wdl" as make_panel_bed
import "../Tasks/convert_allele_table/convert_allele_table.wdl" as convert_allele_table
import "../Tasks/resmarkers_to_terra/resmarkers_to_terra.wdl" as resmarkers_to_terra
import "../Tasks/get_terra_env_info/get_terra_env_info.wdl" as get_terra_env_info_t

workflow plasmodiumdrugres {
   input {
     # Exactly one of these must be provided
     File? pmo
     File filtered_allele_data

     File loci_of_interest_bed
     File loci_groups

     File? population_assignment
     String? pmo_population_fields
     String pmo_population_separator = "_"
     String population_label = "pop1"

     File? targeted_reference
     File? genome_reference

     String mlaf_method = "naive"
     String naive_mlaf_method = "wsaf_prop"
     String slaf_method = "naive"
     String naive_slaf_method = "read_count_prop"
     String translate_loci_extra_args = ""

     String outdir = "output"
     String docker_image = "plasmogenepi/plasmodiumdrugres:wdl"

     # Optional: Terra workspace bucket id (e.g. fc-… from gs://fc-…/…). Use when Cromwell
     # localizes File paths and auto-detection from gs:// no longer applies; otherwise it
     # is detected from the Terra workspace this run is launched from.
     String? workspace_bucket

     File amplicon_info
     File reference

     # Terra workspace whose data table is updated. Detected from the workspace this
     # run is launched from when omitted.
     String? billing_project
     String? workspace_name

     # Terra data table the resmarker columns are written to. Detected from the type of
     # data this run was launched on (the submission's root entity) when omitted.
     String? sample_table
   }

   String outdir_sanitized = sub(outdir, "^[A-Za-z0-9_-]+$", "MATCH")
   Boolean outdir_valid = outdir_sanitized == "MATCH"

   if (!outdir_valid) {
     call fail_t.fail as outdir_check_fail {
       input:
         message = "ERROR: outdir may only contain letters, numbers, dashes, and underscores."
     }
   }

   # Terra workspace identifiers default to the workspace this run was launched from.
   if (!defined(billing_project) || !defined(workspace_name) || !defined(sample_table) || !defined(workspace_bucket)) {
     call get_terra_env_info_t.get_terra_env_info as t_000_terra_env {}

     if ((!defined(billing_project) || !defined(workspace_name) || !defined(sample_table)) && !t_000_terra_env.is_running_on_terra) {
       call fail_t.fail as terra_env_check_fail {
         input:
           message = "ERROR: 'billing_project', 'workspace_name' and/or 'sample_table' was not provided, and this run is not on Terra so they cannot be detected. Provide them explicitly."
       }
     }

     # The data table is the submission's root entity, so a run launched from file paths
     # rather than from a data table has nothing to detect.
     if (!defined(sample_table) && t_000_terra_env.is_running_on_terra && t_000_terra_env.sample_table == "") {
       call fail_t.fail as sample_table_check_fail {
         input:
           message = "ERROR: 'sample_table' was not provided and this submission has no root entity to infer it from (it was most likely launched with inputs defined by file paths rather than from a data table). Provide 'sample_table'."
       }
     }
   }

   call make_panel_bed.make_panel_bed {
        input:
        amplicon_info_tsv = amplicon_info,
        reference_fasta = reference
   }

    call convert_allele_table.convert_allele_table {
        input:
            allele_table_tsv = filtered_allele_data
    }

   call pipeline_initialisation_wf.pipeline_initialisation as t_001_init {
     input:
       pmo = pmo,
       allele_table = convert_allele_table.converted_allele_table,
       panel_info_bed = make_panel_bed.panel_bed,
       population_assignment = population_assignment,
       pmo_population_fields = pmo_population_fields,
       pmo_population_separator = pmo_population_separator,
       targeted_reference = targeted_reference,
       genome_reference = genome_reference,
       docker_image = docker_image
   }

   call translate_loci_of_interest_t.translate_loci_of_interest as t_002_translate_loci {
     input:
       output_directory = "~{outdir}/translated_loci",
       allele_table = t_001_init.allele_table_final,
       ref_bed = t_001_init.panel_info_bed_final,
       loci_of_interest = loci_of_interest_bed,
       docker_image = docker_image,
       extra_args = translate_loci_extra_args,
       overwrite_dir = true
   }

   # -------------------------------------------------------------------------
   # Population splitting (matches Nextflow gating)
   # -------------------------------------------------------------------------
   if (t_001_init.has_population_assignment) {
     call split_table_by_population_map_t.split_table_by_population_map as t_003_split_aa {
       input:
         input_table = t_002_translate_loci.translate_loci_of_interest_output_collapsed_o,
        population_map = select_first([t_001_init.population_assignment_final]),
         docker_image = docker_image,
         population_col = "population",
         identifier_col = "specimen_name",
         output_stub = ".collapsed_amino_acid_calls.tsv.gz"
     }

     if (slaf_method == "mhaps_freq") {
       call split_table_by_population_map_t.split_table_by_population_map as t_004_split_allele {
         input:
           input_table = t_001_init.allele_table_final,
          population_map = select_first([t_001_init.population_assignment_final]),
           docker_image = docker_image,
           population_col = "population",
           identifier_col = "specimen_name",
           output_stub = ".allele_table.tsv.gz"
       }
     }
   }

  Array[String] populations = if (t_001_init.has_population_assignment) then select_first([t_003_split_aa.population_names]) else [population_label]
  Array[File] aa_tables = if (t_001_init.has_population_assignment) then select_first([t_003_split_aa.per_pop_tables]) else [t_002_translate_loci.translate_loci_of_interest_output_collapsed_o]
  Array[File] allele_tables_for_mhaps = if ((slaf_method == "mhaps_freq") && t_001_init.has_population_assignment) then select_first([t_004_split_allele.per_pop_tables]) else [t_001_init.allele_table_final]

   # -------------------------------------------------------------------------
   # Per-population estimation (scatter)
   # -------------------------------------------------------------------------
   scatter (i in range(length(populations))) {
     call estimate_allele_prevalence_naive_t.estimate_allele_prevalence_naive as t_prev {
       input:
         group_name = populations[i],
         aa_calls = aa_tables[i],
         docker_image = docker_image
     }

     call estimate_mlaf_wf.estimate_mlaf as t_mlaf {
       input:
         mlaf_method = mlaf_method,
         group_name = populations[i],
         aa_calls = aa_tables[i],
         loci_groups = loci_groups,
         naive_mlaf_method = naive_mlaf_method,
         docker_image = docker_image
     }

    if (slaf_method == "mhaps_freq") {
      call estimate_slaf_wf.estimate_slaf as t_slaf_mhaps {
        input:
          slaf_method = slaf_method,
          group_name = populations[i],
          aa_calls = aa_tables[i],
          allele_table = allele_tables_for_mhaps[i],
          loci_of_interest_for_target_for_microhap = t_002_translate_loci.translate_loci_of_interest_output_microhap_map_o,
          naive_slaf_method = naive_slaf_method,
          docker_image = docker_image
      }
    }

    if (slaf_method != "mhaps_freq") {
      call estimate_slaf_wf.estimate_slaf as t_slaf_other {
        input:
          slaf_method = slaf_method,
          group_name = populations[i],
          aa_calls = aa_tables[i],
          naive_slaf_method = naive_slaf_method,
          docker_image = docker_image
      }
    }
   }

   call merge_and_concat_wf.merge_and_concat as t_merge_concat {
     input:
       populations = populations,
       allele_prev_files = t_prev.allele_prevalence,
       slaf_files = select_first([t_slaf_other.slaf_output, t_slaf_mhaps.slaf_output]),
       mlaf_files = t_mlaf.mlaf_output,
       sl_from_ml_files = t_mlaf.sl_from_ml_output,
       docker_image = docker_image
   }

   String ml_summary_path_str = t_merge_concat.ml_summary
   String inferred_fc_bucket = sub(ml_summary_path_str, "^gs://(fc-[^/]+)/.*$", "$1")
   Boolean fc_inferred_from_gs_uri = inferred_fc_bucket != ml_summary_path_str
   String detected_fc_bucket = select_first([t_000_terra_env.bucket_name, ""])
   Boolean move_use_gcs = defined(workspace_bucket) || fc_inferred_from_gs_uri || detected_fc_bucket != ""
   String move_fc_bucket = if defined(workspace_bucket) then select_first([workspace_bucket])
                           else if fc_inferred_from_gs_uri then inferred_fc_bucket
                           else detected_fc_bucket

   call move_outputs_t.move_outputs as t_move_outputs {
     input:
       ml_summary = t_merge_concat.ml_summary,
       sl_summary = t_merge_concat.sl_summary,
       sl_from_ml_summary = t_merge_concat.sl_from_ml_summary,
       amino_acid_calls = t_002_translate_loci.translate_loci_of_interest_output_amino_o,
       collapsed_amino_acid_calls = t_002_translate_loci.translate_loci_of_interest_output_collapsed_o,
       loci_covered_by_target_samples_info = t_002_translate_loci.translate_loci_of_interest_output_sample_info_o,
       loci_of_interest_for_target_for_microhap = t_002_translate_loci.translate_loci_of_interest_output_microhap_map_o,
       output_directory = outdir,
       use_gcs_staging = move_use_gcs,
       fc_workspace_bucket = move_fc_bucket
   }

   call resmarkers_to_terra.resmarkers_to_terra as resmarkers_to_terra {
   input:
      collapsed_amino_acid_calls = t_002_translate_loci.translate_loci_of_interest_output_collapsed_o,
      billing_project = select_first([billing_project, t_000_terra_env.workspace_namespace]),
      workspace_name = select_first([workspace_name, t_000_terra_env.workspace_name]),
      sample_table = select_first([sample_table, t_000_terra_env.sample_table])
     }

   output {
     String ml_summary = t_move_outputs.ml_summary_uri
     String sl_summary = t_move_outputs.sl_summary_uri
     String sl_from_ml_summary = t_move_outputs.sl_from_ml_summary_uri
     String amino_acid_calls = t_move_outputs.amino_acid_calls_uri
     String collapsed_amino_acid_calls = t_move_outputs.collapsed_amino_acid_calls_uri
     String loci_covered_by_target_samples_info = t_move_outputs.loci_covered_by_target_samples_info_uri
     String loci_of_interest_for_target_for_microhap = t_move_outputs.loci_of_interest_for_target_for_microhap_uri
   }
}