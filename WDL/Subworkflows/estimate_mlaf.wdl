version 1.0

import "../Tasks/multilocus_prevfreq_naive/multilocus_prevfreq_naive.wdl" as multilocus_prevfreq_naive_t
import "../Tasks/MultiLociBiallelicModel_wrapper/multilocibiallelicmodel_wrapper.wdl" as multilocibiallelicmodel_wrapper_t
import "../Tasks/slaf_from_stave_mlaf/slaf_from_stave_mlaf.wdl" as slaf_from_stave_mlaf_t
import "../Tasks/fem_wrapper/fem_wrapper.wdl" as fem_wrapper_t
import "../Tasks/utils/fail.wdl" as fail_t

workflow estimate_mlaf {
  input {
    String mlaf_method
    String group_name
    File aa_calls
    File loci_groups

    String naive_mlaf_method = "wsaf_prop"
    String docker_image
  }

  if (mlaf_method == "naive") {
    call multilocus_prevfreq_naive_t.multilocus_prevfreq_naive as naive_mlaf {
      input:
        group_name = group_name,
        aa_calls = aa_calls,
        loci_groups = loci_groups,
        method = naive_mlaf_method,
        docker_image = docker_image
    }
  }

  if (mlaf_method == "MLBM") {
    call multilocibiallelicmodel_wrapper_t.multilocibiallelicmodel_wrapper as mlbm_mlaf {
      input:
        group_name = group_name,
        aa_calls = aa_calls,
        loci_group_table = loci_groups,
        docker_image = docker_image
    }
    call slaf_from_stave_mlaf_t.slaf_from_stave_mlaf as sl_from_ml_mlbm {
      input:
        group_name = group_name,
        mlaf_input = mlbm_mlaf.mlaf,
        docker_image = docker_image
    }
  }

  if (mlaf_method == "FEM") {
    call fem_wrapper_t.fem_wrapper as fem_mlaf {
      input:
        group_name = group_name,
        aa_calls = aa_calls,
        loci_group_table = loci_groups,
        docker_image = docker_image
    }
    call slaf_from_stave_mlaf_t.slaf_from_stave_mlaf as sl_from_ml_fem {
      input:
        group_name = group_name,
        mlaf_input = fem_mlaf.mlaf,
        docker_image = docker_image
    }
  }

  output {
    File mlaf_output = select_first([naive_mlaf.mlaf, mlbm_mlaf.mlaf, fem_mlaf.mlaf])
    File sl_from_ml_output = select_first([naive_mlaf.sl_from_ml, sl_from_ml_mlbm.sl_from_ml, sl_from_ml_fem.sl_from_ml])
  }
}

