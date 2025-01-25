version 1.0

task estimate_coi_naive_integer {
    input {
        File allele_table
        String output_path = "coi_table.tsv"
        String method = "integer_method" # Default method, can be changed if needed
        Int integer_threshold = 5
    }

    command <<<
        export TMPDIR=tmp
        set -euxo pipefail

        Rscript /opt/pmotools-python/PGEcore/scripts/estimate_coi_naive/estimate_coi_naive.R \
            --input_path ~{allele_table} \
            --output_path ~{output_path} \
            --method ~{method} \
            --integer_threshold ~{integer_threshold}
    >>>

    output {
        File coi_prevalence_output = "~{output_path}"
    }

    runtime {
        cpu: 1
        memory: "10 GiB"
        disks: "local-disk 10 HDD"
        bootDiskSizeGb: 10
        preemptible: 3
        maxRetries: 1
        docker: 'jorgeamaya/pgecore:v_0_0_1'
    }
}

task estimate_coi_naive_quantile {
    input {
        File allele_table
        String output_path = "coi_table.tsv"
        String method = "quantile_method" # Default method, can be changed if needed
        Float quantile_threshold = 0.05
    }

    command <<<
        export TMPDIR=tmp
        set -euxo pipefail

        Rscript /opt/pmotools-python/PGEcore/scripts/estimate_coi_naive/estimate_coi_naive.R \
            --input_path ~{allele_table} \
            --output_path ~{output_path} \
            --method ~{method} \
            --quantile_threshold ~{quantile_threshold}
    >>>

    output {
        File coi_prevalence_output = "~{output_path}"
    }

    runtime {
        cpu: 1
        memory: "10 GiB"
        disks: "local-disk 10 HDD"
        bootDiskSizeGb: 10
        preemptible: 3
        maxRetries: 1
        docker: 'jorgeamaya/pgecore:v_0_0_1'
    }
}
