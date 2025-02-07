version 1.0

task filter_biallelic_calls {
    input {
        File aa_calls
        String out = "biallelic_amino_acid_calls.tsv.gz"
        Boolean overwrite = true
    }

    command <<<
        export TMPDIR=tmp
        set -euxo pipefail

        Rscript /opt/pmotools-python/PGEcore/scripts/filter_bialleleic_calls/filter_biallelic_calls.R \
            --amino_acid_calls ~{aa_calls} \
            --out ~{out} \
            ~{if overwrite then "--overwrite" else ""}
    >>>

    output {
        File filter_biallelic_calls_output = "~{out}"
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

task filter_biallelic_calls_extended {
    input {
        File amino_acid_calls
        String out = "biallelic_amino_acid_calls.tsv.gz"
        String out_nonbiallelic = "nonbiallelic_amino_acid_calls.tsv.gz"
        Boolean overwrite = true
    }

    command <<<
        export TMPDIR=tmp
        set -euxo pipefail

        Rscript /opt/pmotools-python/PGEcore/scripts/filter_biallelic_calls.R \
            --amino_acid_calls ~{amino_acid_calls} \
            --out ~{out} \
            --out_nonbiallelic ~{out_nonbiallelic} \
            ~{if overwrite then "--overwrite" else ""}
    >>>

    output {
        File out = "~{out}"
        File out_nonbiallelic = "~{out_nonbiallelic}"
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
