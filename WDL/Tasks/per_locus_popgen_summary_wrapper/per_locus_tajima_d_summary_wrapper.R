version 1.0

task per_locus_tajima_d_summary_wrapper {
    input {
        File allele_table
        String out = "tajima_d_summary.tsv"
    }

    command <<<
        export TMPDIR=tmp
        set -euxo pipefail

        Rscript /opt/pmotools-python/PGEcore/scripts/per_locus_popgen_summary_wrapper/per_locus_tajima_d_summary_wrapper.R \
            --allele_table ~{allele_table} \
            > ~{out}
    >>>

    output {
        File per_locus_popgen_summary_wrapper_output = "~{out}"
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
