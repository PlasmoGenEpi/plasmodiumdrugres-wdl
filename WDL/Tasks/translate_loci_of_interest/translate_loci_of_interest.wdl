version 1.0

task translate_loci_of_interest {
    input {
        String output_directory = "translated_loci"
        File allele_table
        File ref_bed
        File loci_of_interest
        String docker_image
        String extra_args = ""
        Boolean overwrite_dir = true
    }

    command <<<
        export TMPDIR=tmp
        set -euxo pipefail

        # R dir.create() is non-recursive; nested paths like output/translated_loci need parents first
        # (same pattern as mad4hatter-wdl tasks: ensure output dirs exist in the task cwd before tools run).
        mkdir -p "~{output_directory}"

        Rscript /opt/plasmodiumdrugres/bin/PGEcore/scripts/translate_loci_of_interest/translate_loci_of_interest.R \
            --output_directory ~{output_directory} \
            --allele_table ~{allele_table} \
            --ref_bed ~{ref_bed} \
            --loci_of_interest ~{loci_of_interest} \
            ~{if overwrite_dir then "--overwrite_dir" else ""} \
            ~{extra_args}
    >>>

    output {
        File translate_loci_of_interest_output_amino_o = "~{output_directory}/amino_acid_calls.tsv.gz"
	File translate_loci_of_interest_output_collapsed_o = "~{output_directory}/collapsed_amino_acid_calls.tsv.gz"
        File translate_loci_of_interest_output_sample_info_o = "~{output_directory}/loci_covered_by_target_samples_info.tsv"
        File translate_loci_of_interest_output_microhap_map_o = "~{output_directory}/loci_of_interest_for_target_for_microhap.tsv.gz"
    }

    runtime {
        cpu: 1
        memory: "10 GiB"
        disks: "local-disk 20 HDD"
        bootDiskSizeGb: 10
        preemptible: 3
        maxRetries: 1
        docker: docker_image
    }
}
