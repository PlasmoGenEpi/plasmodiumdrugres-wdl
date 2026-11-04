version 1.0

task resmarkers_to_terra {
	input {
		File collapsed_amino_acid_calls
		String billing_project
		String workspace_name
		String sample_table
		String output_tsv_path = "sample_resmarkers.tsv"
		String docker_image = "us.gcr.io/broad-dsp-lrma/mad4hatter-drugres-python:latest"
	}

	command <<<
		python3 /opt/python-scripts/resmarkers_to_terra.py \
			--input "~{collapsed_amino_acid_calls}" \
			--output "~{output_tsv_path}" \
			--billing_project "~{billing_project}" \
			--workspace_name "~{workspace_name}" \
			--sample_table "~{sample_table}"
	>>>

	output {
		File sample_resmarkers_tsv = "~{output_tsv_path}"
	}

	runtime {
		docker: docker_image
	}
}
