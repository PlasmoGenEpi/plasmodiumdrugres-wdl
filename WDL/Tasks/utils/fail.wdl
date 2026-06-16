version 1.0

task fail {
  input {
    String message
  }

  command <<<
    set -euo pipefail
    echo "~{message}" 1>&2
    exit 1
  >>>

  output {
    String failed = "~{message}"
  }

  runtime {
    cpu: 1
    memory: "1 GiB"
    disks: "local-disk 1 HDD"
    docker: "ubuntu:24.04"
  }
}

