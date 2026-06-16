version 1.0

task idm_wrapper {
    input {
        String group_name
        File aa_calls
        String docker_image
        String model = "IDM"
        String slaf_output = "~{group_name}.aa_slaf.tsv"
        Float eps_initial = 0.1
        Float lambda_initial = 0.1
    }

    command <<<
        export TMPDIR=tmp
        set -euxo pipefail

        Rscript /opt/plasmodiumdrugres/bin/PGEcore/scripts/IDM_wrapper/IDM_wrapper.R \
            --aa_calls_input ~{aa_calls} \
            --model ~{model} \
            --slaf_output ~{slaf_output} \
            --eps_initial ~{eps_initial} \
            --lambda_initial ~{lambda_initial}
    >>>

    output {
        File slaf = "~{slaf_output}"
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
