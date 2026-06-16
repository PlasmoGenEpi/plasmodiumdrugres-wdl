version 1.0

import "../Tasks/estimate_allele_frequency_naive/estimate_allele_frequency_naive.wdl" as estimate_allele_frequency_naive_t
import "../Tasks/IDM_wrapper/idm_wrapper.wdl" as idm_wrapper_t
import "../Tasks/dcifer_slaf_wrapper/dcifer_slaf_wrapper.wdl" as dcifer_slaf_wrapper_t
import "../Tasks/slaf_from_mhaps_freqs/slaf_from_mhaps_freqs.wdl" as slaf_from_mhaps_freqs_t
import "../Tasks/utils/fail.wdl" as fail_t

workflow estimate_slaf {
  input {
    String slaf_method
    String group_name

    # For naive/IDM we use AA calls; for mhaps_freq we will use allele table + loci mapping.
    File? aa_calls
    File? allele_table
    File? loci_of_interest_for_target_for_microhap

    String naive_slaf_method = "read_count_prop"

    Int? dcifer_slaf_wrapper_coi_lrank
    Float? dcifer_slaf_wrapper_qstart
    Float? dcifer_slaf_wrapper_tol

    String docker_image
  }

  if (slaf_method == "naive") {
    if (!defined(aa_calls)) {
      call fail_t.fail as fail_naive_missing_aa_calls {
        input:
          message = "slaf_method=naive requires `aa_calls`."
      }
    }
    call estimate_allele_frequency_naive_t.estimate_allele_frequency_naive as naive_slaf {
      input:
        group_name = group_name,
        aa_calls = select_first([aa_calls]),
        docker_image = docker_image,
        estimate_allele_frequency_naive_method = naive_slaf_method,
        out = "~{group_name}.aa_slaf.tsv"
    }
  }

  if (slaf_method == "IDM") {
    if (!defined(aa_calls)) {
      call fail_t.fail as fail_idm_missing_aa_calls {
        input:
          message = "slaf_method=IDM requires `aa_calls`."
      }
    }
    call idm_wrapper_t.idm_wrapper as idm_slaf {
      input:
        group_name = group_name,
        aa_calls = select_first([aa_calls]),
        docker_image = docker_image,
        slaf_output = "~{group_name}.aa_slaf.tsv"
    }
  }

  if (slaf_method == "mhaps_freq") {
    if (!defined(allele_table) || !defined(loci_of_interest_for_target_for_microhap)) {
      call fail_t.fail as fail_mhaps_freq_missing_inputs {
        input:
          message = "slaf_method=mhaps_freq requires `allele_table` and `loci_of_interest_for_target_for_microhap`."
      }
    }
    call dcifer_slaf_wrapper_t.dcifer_slaf_wrapper as dcifer_mhaps {
      input:
        group_name = group_name,
        allele_table = select_first([allele_table]),
        docker_image = docker_image,
        coi_lrank = dcifer_slaf_wrapper_coi_lrank,
        qstart = dcifer_slaf_wrapper_qstart,
        tol = dcifer_slaf_wrapper_tol
    }
    call slaf_from_mhaps_freqs_t.slaf_from_mhaps_freqs as slaf_from_mhaps {
      input:
        group_name = group_name,
        mhaps_slaf_fnp = dcifer_mhaps.mhaps_slaf,
        loci_of_interest_per_microhaps_fnp = select_first([loci_of_interest_for_target_for_microhap]),
        docker_image = docker_image
    }
  }

  output {
    File slaf_output = select_first([naive_slaf.slaf, idm_slaf.slaf, slaf_from_mhaps.slaf])
  }
}

