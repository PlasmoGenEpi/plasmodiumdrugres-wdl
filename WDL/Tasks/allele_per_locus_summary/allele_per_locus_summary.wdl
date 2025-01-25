version 1.0

task allele_per_locus_summary {
    input {
        File allele_table
    }

    command <<<
        export TMPDIR=tmp
        set -euxo pipefail

        Rscript /opt/pmotools-python/PGEcore/scripts/allele_per_locus_summary/allele_per_locus_summary.R \
            --allele_table ~{allele_table}
    >>>

    output {
        File allele_per_locus_summary_output = "allele_summary_by_target.tsv"
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
