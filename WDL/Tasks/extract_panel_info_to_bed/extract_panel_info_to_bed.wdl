version 1.0

task extract_panel_info_to_bed {
  input {
    File pmo
    String docker_image
    Boolean add_ref_seqs = false
    String out = "panel_info.bed"
  }

  command <<<
    set -euxo pipefail

    pmotools-python extract_insert_of_panels \
      --file ~{pmo} \
      --output ~{out} \
      ~{if add_ref_seqs then "--add_ref_seqs" else ""}

    # Rename header column from target_id to target_name
    awk 'BEGIN{FS=OFS="\t"} NR==1 {for(i=1;i<=NF;i++) if($i=="target_id") $i="target_name"} {print}' \
      ~{out} > ~{out}.tmp
    mv ~{out}.tmp ~{out}
  >>>

  output {
    File panel_info_bed = "~{out}"
  }

  runtime {
    cpu: 1
    memory: "4 GiB"
    disks: "local-disk 10 HDD"
    preemptible: 3
    maxRetries: 1
    docker: docker_image
  }
}

