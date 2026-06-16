version 1.0

task multilocus_prevfreq_naive {
    input {
        String group_name
        File aa_calls
        File loci_groups
        String docker_image
        String method = "wsaf_prop"
        String mlaf_out = "~{group_name}.aa_mlaf.tsv"
        String sl_from_ml_out = "~{group_name}.aa_sl_from_ml.tsv"
    }

    command <<<
        export TMPDIR=tmp
        set -euxo pipefail

        Rscript /opt/plasmodiumdrugres/bin/PGEcore/scripts/multilocus_prevfreq_naive/multilocus_prevfreq_naive.R \
            --aa_table ~{aa_calls} \
            --loci_groups_input ~{loci_groups} \
            --output_path ~{mlaf_out} \
            --recalc_single_locus_output_path ~{sl_from_ml_out} \
            --method ~{method}
    >>>

    output {
        File mlaf = "~{mlaf_out}"
        File sl_from_ml = "~{sl_from_ml_out}"
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
