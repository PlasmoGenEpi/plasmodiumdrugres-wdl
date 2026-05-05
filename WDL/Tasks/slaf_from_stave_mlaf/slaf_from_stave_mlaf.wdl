version 1.0

task slaf_from_stave_mlaf {
    input {
        String group_name
        File mlaf_input
        String docker_image
        String out = "~{group_name}.aa_sl_from_ml.tsv"
    }

    command <<<
        export TMPDIR=tmp
        set -euxo pipefail

        Rscript /opt/plasmodiumdrugres/bin/PGEcore/scripts/slaf_from_stave_mlaf/slaf_from_stave_mlaf.R \
            --mlaf_input ~{mlaf_input} \
            --output ~{out}
    >>>

    output {
        File sl_from_ml = "~{out}"
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
