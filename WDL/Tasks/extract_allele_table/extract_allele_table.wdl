version 1.0

task extract_allele_table {
    input {
        File pmo
        String docker_image
    }

    command <<<
        export TMPDIR=tmp
        set -euxo pipefail

        pmotools-python extract_allele_table \
            --file ~{pmo} \
            --representative_haps_fields "seq" \
            --microhap_fields "reads" \
            --default_base_col_names specimen_name,target_name,allele \
            --output allele_table
    >>>

    output {
        File allele_table_o = "allele_table.tsv"
    }

    runtime {
        cpu: 1
        memory: "10 GiB"
        disks: "local-disk 10 HDD"
        bootDiskSizeGb: 10
        preemptible: 3
        maxRetries: 1
        docker: docker_image
    }
}
