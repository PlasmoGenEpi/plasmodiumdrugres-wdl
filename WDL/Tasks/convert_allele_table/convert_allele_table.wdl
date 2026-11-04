version 1.0

task convert_allele_table {
	input {
		File allele_table_tsv
		String? output_tsv_path = "allele_data_filtered.tsv"
		String docker_image = "us.gcr.io/broad-dsp-lrma/mad4hatter-drugres-python:latest"
	}

	command <<<
		python3 /opt/python-scripts/convert_allele_table.py \
			--input ~{allele_table_tsv} \
			--output ~{output_tsv_path}
	>>>

	output {
		File converted_allele_table = "~{output_tsv_path}"
	}

	runtime {
		docker: docker_image
	}
}