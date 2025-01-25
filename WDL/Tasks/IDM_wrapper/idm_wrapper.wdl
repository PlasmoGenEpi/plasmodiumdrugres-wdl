version 1.0

task idm_wrapper {
    input {
        File aa_calls
        String model = "IDM"
        String slaf_output = "out_slaf.tsv"
        Float eps_initial = 0.1
        Float lambda_initial = 0.1
    }

    command <<<
        export TMPDIR=tmp
        set -euxo pipefail

        Rscript /opt/pmotools-python/PGEcore/scripts/IDM_wrapper/IDM_wrapper.R \
            --aa_calls_input ~{aa_calls} \
            --model ~{model} \
            --slaf_output ~{slaf_output} \
            --eps_initial ~{eps_initial} \
            --lambda_initial ~{lambda_initial}
    >>>

    output {
        File idm_wrapper_output = "~{slaf_output}"
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
