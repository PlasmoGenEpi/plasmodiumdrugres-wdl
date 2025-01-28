version 1.0

task multilocibiallelicmodel_wrapper {
    input {
        File aa_calls
        File loci_group_table
    }

    command <<<
        export TMPDIR=tmp
        set -euxo pipefail

        Rscript /opt/pmotools-python/PGEcore/scripts/MultiLociBiallelicModel_wrapper/MultiLociBiallelicModel_wrapper.R \
            --aa_calls ~{aa_calls} \
            --loci_group_table ~{loci_group_table} \

    >>>

    output {
        File multilocibiallelicmodel_wrapper_o = "MLBM_summary.tsv"
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

