version 1.0

task multilocibiallelicmodel_wrapper {
    input {
        String group_name
        File aa_calls
        File loci_group_table
        String docker_image
        String out = "~{group_name}.aa_mlaf.tsv"
    }

    command <<<
        export TMPDIR=tmp
        set -euxo pipefail

        Rscript /opt/plasmodiumdrugres/bin/PGEcore/scripts/MultiLociBiallelicModel_wrapper/MultiLociBiallelicModel_wrapper.R \
            --aa_calls ~{aa_calls} \
            --loci_group_table ~{loci_group_table} \
            --mlaf_output ~{out} \

    >>>

    output {
        File mlaf = "~{out}"
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

