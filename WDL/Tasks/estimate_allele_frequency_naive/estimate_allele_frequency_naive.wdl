version 1.0

task estimate_allele_frequency_naive {
    input {
        File aa_calls
        String estimate_allele_frequency_naive_method = "read_count_prop" # Options: "read_count_prop" or "presence_absence"
        String out = "allele_freqs.tsv"
    }

    command <<<
        export TMPDIR=tmp
        set -euxo pipefail

        Rscript /opt/pmotools-python/PGEcore/scripts/estimate_allele_frequency_naive/estimate_allele_frequency_naive.R \
            --aa_calls ~{aa_calls} \
            --method ~{estimate_allele_frequency_naive_method} \
            --output ~{out}
    >>>

    output {
        File estimate_allele_frequency_naive_output = "~{out}"
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
