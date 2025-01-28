version 1.0

task extract_allele_table {
    input {
        File? pmo
        String bioinfoid = "ReducedMAD4HATTERSim-SeekDeep"
    }

    command <<<
        export TMPDIR=tmp
        set -euxo pipefail

        pmotools-runner.py extract_allele_table \
            --file ~{pmo} \
            --bioid ~{bioinfoid} \
            --representative_haps_fields "seq" \
            --microhap_fields "read_count" \
            --default_base_col_names specimen_id,target_id,allele \
            --output allele_table
    >>>

    output {
        File allele_table_o = "allele_table.tsv"
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
