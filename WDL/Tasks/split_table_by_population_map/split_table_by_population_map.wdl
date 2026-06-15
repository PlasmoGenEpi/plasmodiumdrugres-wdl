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
      --output_directory . \
      --output_stub ~{output_stub}

    # Cromwell/Terra reliably delocalizes glob()-discovered outputs; read_lines() manifests
    # can register File paths in metadata without uploading the underlying files to GCS.
    shopt -s nullglob
    split_files=( *~{output_stub} )
    if [ "${#split_files[@]}" -eq 0 ]; then
      echo "ERROR: split_table_by_population_map produced no *~{output_stub} files in $(pwd)" >&2
      ls -la >&2
      exit 1
    fi
    printf '%s\n' "${split_files[@]}" | sort > split_files.txt
    sed "s/~{output_stub}$//" split_files.txt > population_names.txt
  >>>

  output {
    # glob() must match the same sorted basename set as population_names (Cromwell sorts glob results).
    Array[File] per_pop_tables = glob("*~{output_stub}")
    Array[String] population_names = read_lines("population_names.txt")
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

