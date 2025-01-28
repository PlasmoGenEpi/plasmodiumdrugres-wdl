version 1.0

task translate_loci_of_interest {
    input {
        String output_directory = "example_output"
        File allele_table
        File ref_bed
        File loci_of_interest
        Boolean overwrite_dir = true
    }

    command <<<
        export TMPDIR=tmp
        set -euxo pipefail

        Rscript /opt/pmotools-python/PGEcore/scripts/translate_loci_of_interest/translate_loci_of_interest.R \
            --output_directory ~{output_directory} \
            --allele_table ~{allele_table} \
            --ref_bed ~{ref_bed} \
            --loci_of_interest ~{loci_of_interest} \
            ~{if overwrite_dir then "--overwrite_dir" else ""}
    >>>

    output {
        File translate_loci_of_interest_output_amino_o = "~{output_directory}/amino_acid_calls.tsv.gz"
	File translate_loci_of_interest_output_collapsed_o = "~{output_directory}/collapsed_amino_acid_calls.tsv.gz"
        File translate_loci_of_interest_output_sample_info_o = "~{output_directory}/loci_covered_by_target_samples_info.tsv"
    }

    runtime {
        cpu: 1
        memory: "10 GiB"
        disks: "local-disk 20 HDD"
        bootDiskSizeGb: 10
        preemptible: 3
        maxRetries: 1
        docker: 'jorgeamaya/pgecore:v_0_0_1'
    }
}
