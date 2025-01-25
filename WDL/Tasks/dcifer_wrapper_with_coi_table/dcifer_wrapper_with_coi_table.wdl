version 1.0

task dcifer_wrapper_with_coi_table {
    input {
        File allele_table_dcifer
        File coi_table
        Int threads = 2
        String btwn_host_rel_output = "btwn_host_rel.tsv"
    }

    command <<<
        export TMPDIR=tmp
        set -euxo pipefail

        Rscript /opt/pmotools-python/PGEcore/scripts/dcifer_wrapper/dcifer_wrapper.R \
            --allele_table ~{allele_table_dcifer} \
            --coi_table ~{coi_table} \
            --threads ~{threads} \
            --btwn_host_rel_output ~{btwn_host_rel_output}
    >>>

    output {
        File btwn_host_rel_output_1 = "~{btwn_host_rel_output}"
    }

    runtime {
        cpu: 2
        memory: "20 GiB"
        disks: "local-disk 10 HDD"
        bootDiskSizeGb: 10
        preemptible: 3
        maxRetries: 1
        docker: 'jorgeamaya/pgecore:v_0_0_1'
    }
}

task dcifer_wrapper_with_allele_freq_table {
    input {
        File allele_table
        File allele_freq_table
        String btwn_host_rel_output = "btwn_host_rel.tsv"
    }

    command <<<
        export TMPDIR=tmp
        set -euxo pipefail

        Rscript /opt/pmotools-python/PGEcore/scripts/dcifer_wrapper/dcifer_wrapper.R \
            --allele_table ~{allele_table} \
            --allele_freq_table ~{allele_freq_table} \
            --btwn_host_rel_output ~{btwn_host_rel_output}
    >>>

    output {
        File btwn_host_rel_output_2 = "~{btwn_host_rel_output}"
    }

    runtime {
        cpu: 1
        memory: "20 GiB"
        disks: "local-disk 10 HDD"
        bootDiskSizeGb: 10
        preemptible: 3
        maxRetries: 1
        docker: 'jorgeamaya/pgecore:v_0_0_1'
    }
}
