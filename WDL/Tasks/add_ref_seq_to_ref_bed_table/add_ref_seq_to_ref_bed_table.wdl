version 1.0

task add_ref_seqs_with_fasta {
    input {
        File ref_bed
        File fasta
        String docker_image
        String out_bed = "output_withRefSeqs.bed"
    }

    command <<<
        export TMPDIR=tmp
        set -euxo pipefail

        Rscript /opt/plasmodiumdrugres/bin/PGEcore/scripts/add_ref_seq_to_ref_bed_table/add_ref_seqs_with_targeted_ref_fasta.R \
            --ref_bed ~{ref_bed} \
            --fasta ~{fasta} \
            --out ~{out_bed}
    >>>

    output {
        File add_ref_seq_to_ref_bed_table_output = "~{out_bed}"
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

task add_ref_seqs_with_genome {
    input {
        File ref_bed
        File genome
        String docker_image
        String out_bed = "output_withRefSeqs.bed"
    }

    command <<<
        export TMPDIR=tmp
        set -euxo pipefail

        Rscript /opt/plasmodiumdrugres/bin/PGEcore/scripts/add_ref_seq_to_ref_bed_table/add_ref_seqs_with_full_genome_ref_fasta.R \
            --ref_bed ~{ref_bed} \
            --genome ~{genome} \
            --out ~{out_bed}
    >>>

    output {
        File add_ref_seq_to_ref_bed_table_output = "~{out_bed}"
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
