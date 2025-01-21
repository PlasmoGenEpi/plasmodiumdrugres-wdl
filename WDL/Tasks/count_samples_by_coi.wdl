version 1.0

task count_samples_by_coi {
    input {
        File coi_calls
    }

    command <<<
        Rscript bin/PGEcore/scripts/count_samples_by_coi/count_samples_by_coi.R \
            --coi_calls ~{coi_calls} \
            --output "sample_count_per_coi.tsv"
    >>>

    output {
        File sample_count_per_coi = "sample_count_per_coi.tsv"
    

    runtime {
        cpu: 1
        memory: "40 GiB"
        disks: "local-disk 10 HDD"
        bootDiskSizeGb: 10
        preemptible: 3 
        maxRetries: 1
        docker: 'jorgeamaya/asvfilters:v_1_0_0'
    }
}
