version 1.0

task count_samples_by_coi {
    input {
        File coi_calls
    }

    command <<<
        export TMPDIR=tmp
        set -euxo pipefail

        Rscript /opt/pmotools-python/PGEcore/scripts/count_samples_by_coi/count_samples_by_coi.R \
            --coi_calls ~{coi_calls} \
            --output "sample_count_per_coi.tsv"
    >>>

    output {
        File count_samples_by_coi_output = "sample_count_per_coi.tsv"
    } 

    runtime {
        cpu: 1
        memory: "40 GiB"
        disks: "local-disk 10 HDD"
        bootDiskSizeGb: 10
        preemptible: 3 
        maxRetries: 1
        docker: 'jorgeamaya/pgecore:v_0_0_1'
    }
}
