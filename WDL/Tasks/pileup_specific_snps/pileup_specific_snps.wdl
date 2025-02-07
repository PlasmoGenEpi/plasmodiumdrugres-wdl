version 1.0

task pileup_specific_snps {
    input {
        File allele_table
        File ref_bed
        String output_directory = "testing"
        File snps_of_interest
        Boolean overwrite_dir = true
    }

    command <<<
        export TMPDIR=tmp
        set -euxo pipefail

        Rscript /opt/pmotools-python/PGEcore/scripts/pileup_specific_snps/pileup_specific_snps.R \
            --allele_table ~{allele_table} \
            --ref_bed ~{ref_bed} \
            --output_directory ~{output_directory} \
            --snps_of_interest ~{snps_of_interest} \
            ~{if overwrite_dir then "--overwrite_dir" else ""}
    >>>

    output {
        File pileup_specific_snps_output = "~{output_directory}"
    }

    runtime {
        cpu: 1
        memory: "10 GiB"
        disks: "local-disk 20 HDD"
        bootDiskSizeGb: 10
        preemptible: 3
        maxRetries: 1
        docker: 'jorgeamaya/pgecore:v_0_0_1'
    }
}
