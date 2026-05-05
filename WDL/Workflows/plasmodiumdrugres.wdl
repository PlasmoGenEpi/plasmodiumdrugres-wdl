version 1.0

import "../Tasks/extract_allele_table/extract_allele_table.wdl" as extract_allele_table_t
import "../Tasks/translate_loci_of_interest/translate_loci_of_interest.wdl" as translate_loci_of_interest_t
import "../Tasks/estimate_allele_prevalence_naive/estimate_allele_prevalence_naive.wdl" as estimate_allele_prevalence_naive_t
import "../Subworkflows/pipeline_initialisation.wdl" as pipeline_initialisation_wf
import "../Subworkflows/estimate_mlaf.wdl" as estimate_mlaf_wf
import "../Subworkflows/estimate_slaf.wdl" as estimate_slaf_wf
import "../Subworkflows/merge_and_concat.wdl" as merge_and_concat_wf
import "../Tasks/split_table_by_population_map/split_table_by_population_map.wdl" as split_table_by_population_map_t

workflow plasmodiumdrugres {
   input {
     # Exactly one of these must be provided
     File? pmo
     File? allele_table

     # Required for translation and for allele_table mode
     File? panel_info_bed

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
   }

   call pipeline_initialisation_wf.pipeline_initialisation as t_001_init {
     input:
       pmo = pmo,
       allele_table = allele_table,
       panel_info_bed = panel_info_bed,
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

   output {
     File translated_loci_amino_acid_calls = t_002_translate_loci.translate_loci_of_interest_output_amino_o
     File translated_loci_collapsed_amino_acid_calls = t_002_translate_loci.translate_loci_of_interest_output_collapsed_o
     File translated_loci_sample_info = t_002_translate_loci.translate_loci_of_interest_output_sample_info_o
     File translated_loci_microhap_map = t_002_translate_loci.translate_loci_of_interest_output_microhap_map_o

     Array[File] per_pop_sl_summary = t_merge_concat.per_pop_sl_summary
     Array[File] per_pop_ml_summary = t_merge_concat.per_pop_ml_summary
     Array[File] per_pop_sl_from_ml_summary = t_merge_concat.per_pop_sl_from_ml_summary

     File sl_summary = t_merge_concat.sl_summary
     File ml_summary = t_merge_concat.ml_summary
     File sl_from_ml_summary = t_merge_concat.sl_from_ml_summary
   }
}
