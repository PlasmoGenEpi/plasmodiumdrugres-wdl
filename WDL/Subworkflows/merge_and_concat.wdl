version 1.0

import "../Tasks/merge_tables/merge_tables.wdl" as merge_tables_t
import "../Tasks/concat_tables/concat_tables.wdl" as concat_tables_t

workflow merge_and_concat {
  input {
    Array[String] populations
    Array[File] allele_prev_files
    Array[File?] slaf_files
    Array[File] mlaf_files
    Array[File] sl_from_ml_files
    String docker_image
  }

  scatter (i in range(length(populations))) {
    call merge_tables_t.merge_tables as merge_one {
      input:
        population = populations[i],
        allele_prev = allele_prev_files[i],
        slaf = select_first([slaf_files[i]]),
        mlaf = mlaf_files[i],
        sl_from_ml = sl_from_ml_files[i],
        docker_image = docker_image
    }
  }

  call concat_tables_t.concat_tables as concat_all {
    input:
      sl_files = merge_one.sl_summary,
      ml_files = merge_one.ml_summary,
      sl_from_ml_files = merge_one.sl_from_ml_summary,
      docker_image = docker_image
  }

  output {
    Array[File] per_pop_sl_summary = merge_one.sl_summary
    Array[File] per_pop_ml_summary = merge_one.ml_summary
    Array[File] per_pop_sl_from_ml_summary = merge_one.sl_from_ml_summary

    File sl_summary = concat_all.sl_summary
    File ml_summary = concat_all.ml_summary
    File sl_from_ml_summary = concat_all.sl_from_ml_summary
  }
}

