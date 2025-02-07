version 1.0

task multilocus_prevfreq_naive {
    input {
        File aa_calls
        String output_path = "mlafp.tsv"
    }

    command <<<
        export TMPDIR=tmp
        set -euxo pipefail

        Rscript /opt/pmotools-python/PGEcore/scripts/multilocus_prevfreq_naive/multilocus_prevfreq_naive.R \
            --input_path ~{aa_calls} \
            --output_path ~{output_path}
    >>>

    output {
        File multilocus_prevfreq_naive_output = "~{output_path}"
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
