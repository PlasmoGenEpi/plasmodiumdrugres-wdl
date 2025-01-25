version 1.0

task slaf_from_stave_mlaf {
    input {
        File mlaf_input
        String out = "single_locus_allele_frequencies.tsv"
    }

    command <<<
        export TMPDIR=tmp
        set -euxo pipefail

        Rscript /opt/pmotools-python/PGEcore/scripts/slaf_from_stave_mlaf/slaf_from_stave_mlaf.R \
            --mlaf_input ~{mlaf_input} \
            --output ~{out}
    >>>

    output {
        File slaf_from_stave_mlaf_output = "~{out}"
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
