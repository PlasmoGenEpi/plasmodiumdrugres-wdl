version 1.0

task estimate_allele_prevalence_naive {
    input {
        File aa_calls
        String out = "prevalence.tsv"
    }

    command <<<
        export TMPDIR=tmp
        set -euxo pipefail

        Rscript /opt/pmotools-python/PGEcore/scripts/estimate_allele_prevalence_naive/estimate_allele_prevalence_naive.R \
            --aa_calls ~{aa_calls} \
            --output ~{out}
    >>>

    output {
        File allele_prevalence_o = "~{out}"
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
