version 1.0

task add_ref_seqs_with_fasta {
    input {
        File ref_bed
        File fasta
        String out_bed = "output_withRefSeqs.bed"
    }

    command <<<
        export TMPDIR=tmp
        set -euxo pipefail

        Rscript /opt/pmotools-python/PGEcore/scripts/add_ref_seq_to_ref_bed_table/add_ref_seqs_with_fasta.R \
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
        docker: 'jorgeamaya/pgecore:v_0_0_1'
    }
}

task add_ref_seqs_with_genome {
    input {
        File ref_bed
        File genome
        String out_bed = "output_withRefSeqs.bed"
    }

    command <<<
        export TMPDIR=tmp
        set -euxo pipefail

        Rscript /opt/pmotools-python/PGEcore/scripts/add_ref_seq_to_ref_bed_table/add_ref_seqs_with_genome.R \
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
        docker: 'jorgeamaya/pgecore:v_0_0_1'
    }
}
