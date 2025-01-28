version 1.0

import "../Tasks/extract_allele_table/extract_allele_table.wdl" as extract_allele_table_t
import "../Tasks/translate_loci_of_interest/translate_loci_of_interest.wdl" as translate_loci_of_interest_t
import "../Tasks/estimate_coi_naive/estimate_coi_naive.wdl" as estimate_coi_naive_t
import "../Tasks/estimate_allele_prevalence_naive/estimate_allele_prevalence_naive.wdl" as estimate_allele_prevalence_naive_t
import "../Tasks/MultiLociBiallelicModel_wrapper/multilocibiallelicmodel_wrapper.wdl" as multilocibiallelicmodel_wrapper_t
import "../Tasks/IDM_wrapper/idm_wrapper.wdl" as idm_wrapper_t

workflow plasmodiumdrugres {
   input {
     File? pmo
     File? allele_table 
     File ref_bed
     File loci_of_interest
     File loci_group_table
   }

   if(defined(pmo)) {
     call extract_allele_table_t.extract_allele_table as t_001_allele_table {
       input:
         pmo = pmo
     }
   }

   call translate_loci_of_interest_t.translate_loci_of_interest as t_002_loci_of_interest {
     input:
       #Translate loci extra args pending
       allele_table = select_first([allele_table, t_001_allele_table.allele_table_o]),
       ref_bed = ref_bed,
       loci_of_interest = loci_of_interest
   }

   call estimate_coi_naive_t.estimate_coi_naive as t_003_estimate_coi_naive {
     input:
       allele_table = select_first([allele_table, t_001_allele_table.allele_table_o])
   }
   
   call estimate_allele_prevalence_naive_t.estimate_allele_prevalence_naive as t_004_estimate_allele_prevalence_naive {
     input:
       aa_calls = t_002_loci_of_interest.translate_loci_of_interest_output_amino_o
   }

   call multilocibiallelicmodel_wrapper_t.multilocibiallelicmodel_wrapper as t_005_multilocibiallelicmodel_wrapper {
     input:
       aa_calls = t_002_loci_of_interest.translate_loci_of_interest_output_amino_o,
       loci_group_table = loci_group_table
   }

   call idm_wrapper_t.idm_wrapper as t_006_idm_wrapper {
     input:
       aa_calls = t_002_loci_of_interest.translate_loci_of_interest_output_amino_o,
   }

   output {
     #File? allele_table = select_first([allele_table, t_001_allele_table.allele_table_o])
     File translate_loci_of_interest_output_amino = t_002_loci_of_interest.translate_loci_of_interest_output_amino_o
     File translate_loci_of_interest_output_collapsed = t_002_loci_of_interest.translate_loci_of_interest_output_collapsed_o
     File translate_loci_of_interest_output_sample_info = t_002_loci_of_interest.translate_loci_of_interest_output_sample_info_o
     File estimate_coi_naive_output = t_003_estimate_coi_naive.coi_naive_o
     File estimate_allele_prevalence_naive_output = t_004_estimate_allele_prevalence_naive.allele_prevalence_o
     File multilocibiallelicmodel_wrapper_output = t_005_multilocibiallelicmodel_wrapper.multilocibiallelicmodel_wrapper_o
     File idm_wrapper_output = t_006_idm_wrapper.idm_wrapper_o
   }
}
