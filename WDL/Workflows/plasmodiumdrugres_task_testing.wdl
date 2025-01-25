version 1.0

import "../Tasks/Count_Samples_By_COI/count_samples_by_coi.wdl" as count_samples_by_coi_t
import "../Tasks/IDM_wrapper/idm_wrapper.wdl" as idm_wrapper_t
import "../Tasks/MultiLociBiallelicModel_wrapper/multilocibiallelicmodel_wrapper.wdl" as multilocibiallelicmodel_wrapper_t
import "../Tasks/add_ref_seq_to_ref_bed_table/add_ref_seq_to_ref_bed_table.wdl" as add_ref_seq_to_ref_bed_table_t
import "../Tasks/allele_per_locus_summary/allele_per_locus_summary.wdl" as allele_per_locus_summary_t
import "../Tasks/dcifer_wrapper_with_coi_table/dcifer_wrapper_with_coi_table.wdl" as dcifer_wrapper_with_coi_table_t
import "../Tasks/estimate_allele_frequency_naive/estimate_allele_frequency_naive.wdl" as estimate_allele_frequency_naive_t
import "../Tasks/estimate_allele_prevalence_naive/estimate_allele_prevalence_naive.wdl" as estimate_allele_prevalence_naive_t
import "../Tasks/estimate_coi_naive/estimate_coi_naive.wdl" as estimate_coi_prevalence_naive_t
import "../Tasks/filter_bialleleic_calls/filter_bialleleic_calls.wdl" as filter_bialleleic_calls_t
import "../Tasks/multilocus_prevfreq_naive/multilocus_prevfreq_naive.wdl" as multilocus_prevfreq_naive_t
import "../Tasks/per_locus_popgen_summary_wrapper/per_locus_tajima_d_summary_wrapper.R" as per_locus_tajima_d_summary_wrapper_t
import "../Tasks/pileup_specific_snps/pileup_specific_snps.wdl" as pileup_specific_snps_t
import "../Tasks/slaf_from_stave_mlaf/slaf_from_stave_mlaf.wdl" as slaf_from_stave_mlaf_t
import "../Tasks/translate_loci_of_interest/translate_loci_of_interest.wdl" as translate_loci_of_interest_t

workflow plasmodiumdrugres {
    input {
        File coi_calls = coi_calls
        File aa_calls = aa_calls
        File loci_group_table = loci_group_table
        File allele_table = allele_table
	File ref_bed = ref_bed
        File snps_of_interest = snps_of_interest
        File mlaf_input = mlaf_input
        File loci_of_interest = loci_of_interest
	File fasta = fasta
        File genome = genome
        File coi_table = coi_table
        File allele_freq_table = allele_freq_table
        File allele_table_dcifer = allele_table_dcifer
    }

    call count_samples_by_coi_t.count_samples_by_coi as t_001_count_samples_by_coi {
        input:
            coi_calls = coi_calls
    }

    call idm_wrapper_t.idm_wrapper as t_002_idm_wrapper {
	input:
	    aa_calls = aa_calls 
    }

    call multilocibiallelicmodel_wrapper_t.multilocibiallelicmodel_wrapper as t_003_multilocibiallelicmodel_wrapper {
        input:
	    aa_calls = aa_calls,
	    loci_group_table = loci_group_table
    }

    call add_ref_seq_to_ref_bed_table_t.add_ref_seqs_with_genome as t_004_add_ref_seq_to_ref_bed_table_genome {
        input:
            ref_bed = ref_bed,
            genome = genome
    }

    call add_ref_seq_to_ref_bed_table_t.add_ref_seqs_with_fasta as t_004_add_ref_seq_to_ref_bed_table_fasta {
        input:
            ref_bed = ref_bed,
            fasta = fasta
    }

    call allele_per_locus_summary_t.allele_per_locus_summary as t_005_allele_per_locus_summary {
        input:
            allele_table = allele_table
    }

    call dcifer_wrapper_with_coi_table_t.dcifer_wrapper_with_coi_table as t_006_dcifer_wrapper_with_coi_table {
        input:
            allele_table_dcifer = allele_table_dcifer,
            coi_table = coi_table
    }

    call dcifer_wrapper_with_coi_table_t.dcifer_wrapper_with_allele_freq_table as t_006_dcifer_wrapper_with_freq_table {
        input:
            allele_table = allele_table,
            allele_freq_table = allele_freq_table
    }

    call estimate_allele_frequency_naive_t.estimate_allele_frequency_naive as t_007_estimate_allele_frequency_naive {
	input:
	    aa_calls = aa_calls
    }

    call estimate_allele_prevalence_naive_t.estimate_allele_prevalence_naive as t_008_estimate_allele_prevalence_naive {
        input:
	    aa_calls = aa_calls
    }

    call estimate_coi_prevalence_naive_t.estimate_coi_naive_integer as t_009_estimate_coi_naive_integer {
        input:
            allele_table = allele_table
    }
    call estimate_coi_prevalence_naive_t.estimate_coi_naive_quantile as t_009_estimate_coi_naive_quantile {
        input:
            allele_table = allele_table
    }

    call filter_bialleleic_calls_t.filter_biallelic_calls as t_010_filter_bialleleic_calls {
	input:
	    aa_calls = aa_calls
    }

    call multilocus_prevfreq_naive_t.multilocus_prevfreq_naive as t_011_multilocus_prevfreq_naive {
        input:
            aa_calls = aa_calls
    }

    call per_locus_tajima_d_summary_wrapper_t.per_locus_tajima_d_summary_wrapper as t_012_per_locus_tajima_d_summary_wrapper {
	input:
	    allele_table = allele_table
    }

    call pileup_specific_snps_t.pileup_specific_snps as t_013_pileup_specific_snps {
	input:
	    allele_table = allele_table,
            ref_bed = ref_bed,
            snps_of_interest = snps_of_interest
    }

    call slaf_from_stave_mlaf_t.slaf_from_stave_mlaf as t_014_slaf_from_stave_mlaf {
         input:
            mlaf_input = mlaf_input
    }

    call translate_loci_of_interest_t.translate_loci_of_interest as t_015_translate_loci_of_interest {
	input:
            allele_table = allele_table,
            ref_bed = ref_bed,
            loci_of_interest = loci_of_interest
    }

    output {
        File count_samples_by_coi_output = t_001_count_samples_by_coi.count_samples_by_coi_output
        File idm_wrapper_output = t_002_idm_wrapper.idm_wrapper_output
        File multilocibiallelicmodel_wrapper_output = t_003_multilocibiallelicmodel_wrapper.multilocibiallelicmodel_wrapper_output
        File output_bed_1 = t_004_add_ref_seq_to_ref_bed_table_genome.add_ref_seq_to_ref_bed_table_output
        File output_bed_2 = t_004_add_ref_seq_to_ref_bed_table_fasta.add_ref_seq_to_ref_bed_table_output
        File allele_per_locus_summary_output = t_005_allele_per_locus_summary.allele_per_locus_summary_output
        File dcifer_output_1 = t_006_dcifer_wrapper_with_coi_table.btwn_host_rel_output_1
        File dcifer_output_2 = t_006_dcifer_wrapper_with_freq_table.btwn_host_rel_output_2
        File estimate_allele_frequency_naive_output = t_007_estimate_allele_frequency_naive.estimate_allele_frequency_naive_output
        File estimate_allele_prevalence_naive_output = t_008_estimate_allele_prevalence_naive.estimate_allele_prevalence_output
        File coi_prevalence_output_integer = t_009_estimate_coi_naive_integer.coi_prevalence_output
        File coi_prevalence_output_quantile = t_009_estimate_coi_naive_quantile.coi_prevalence_output
        File filter_bialleleic_calls_output = t_010_filter_bialleleic_calls.filter_biallelic_calls_output
        File multilocus_prevfreq_naive_output = t_011_multilocus_prevfreq_naive.multilocus_prevfreq_naive_output
        File per_locus_popgen_summary_wrapper_output = t_012_per_locus_tajima_d_summary_wrapper.per_locus_popgen_summary_wrapper_output
        File pileup_specific_snps_output = t_013_pileup_specific_snps.pileup_specific_snps_output
        File slaf_from_stave_mlaf_output = t_014_slaf_from_stave_mlaf.slaf_from_stave_mlaf_output
        File translate_loci_of_interest_output_amino = t_015_translate_loci_of_interest.translate_loci_of_interest_output_amino
        File translate_loci_of_interest_output_collapsed = t_015_translate_loci_of_interest.translate_loci_of_interest_output_collapsed
        File translate_loci_of_interest_output_sample_info = t_015_translate_loci_of_interest.translate_loci_of_interest_output_sample_info
    }
}
