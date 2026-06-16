version 1.0

task extract_population_map_from_pmo {
  input {
    File pmo
    String docker_image
    String population_fields_space_separated
    String separator = "_"
    String out = "population_map.tsv"
  }

  command <<<
    set -euxo pipefail

    pmotools-python export_specimen_meta_table \
      --file ~{pmo} \
      --output specimen_meta_table.tsv

    python3 /opt/plasmodiumdrugres/bin/specimen_info_to_population_map.py \
      --specimen-info specimen_meta_table.tsv \
      --output ~{out} \
      --fields ~{population_fields_space_separated} \
      --separator ~{separator}
  >>>

  output {
    File population_map = "~{out}"
  }

  runtime {
    cpu: 1
    memory: "2 GiB"
    disks: "local-disk 10 HDD"
    preemptible: 3
    maxRetries: 1
    docker: docker_image
  }
}

