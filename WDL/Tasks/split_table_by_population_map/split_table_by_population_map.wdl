version 1.0

task split_table_by_population_map {
  input {
    File input_table
    File population_map
    String docker_image
    String population_col = "population"
    String identifier_col = "specimen_name"
    String output_stub
  }

  command <<<
    set -euxo pipefail

    /opt/plasmodiumdrugres/bin/split_table_by_population_map.R \
      --input_table_fnp ~{input_table} \
      --population_map ~{population_map} \
      --population_col ~{population_col} \
      --identifier_col ~{identifier_col} \
      --output_stub ~{output_stub}

    # Emit deterministic list of produced files + population names
    ls -1 *~{output_stub} | sort > split_files.txt
    sed "s/~{output_stub}$//" split_files.txt > population_names.txt
  >>>

  output {
    Array[File] per_pop_tables = read_lines("split_files.txt")
    Array[String] population_names = read_lines("population_names.txt")
    File? unmapped_report = "unmapped_specimens.txt"
  }

  runtime {
    cpu: 1
    memory: "4 GiB"
    disks: "local-disk 20 HDD"
    preemptible: 3
    maxRetries: 1
    docker: docker_image
  }
}

