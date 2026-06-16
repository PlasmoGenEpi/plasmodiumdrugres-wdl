version 1.0

import "../Tasks/extract_allele_table/extract_allele_table.wdl" as extract_allele_table_t
import "../Tasks/extract_panel_info_to_bed/extract_panel_info_to_bed.wdl" as extract_panel_info_to_bed_t
import "../Tasks/add_ref_seq_to_ref_bed_table/add_ref_seq_to_ref_bed_table.wdl" as add_ref_seqs_t
import "../Tasks/extract_population_map_from_pmo/extract_population_map_from_pmo.wdl" as extract_population_map_from_pmo_t
import "../Tasks/utils/fail.wdl" as fail_t

workflow pipeline_initialisation {
  input {
    File? pmo
    File? allele_table

    File? panel_info_bed
    File? population_assignment
    String? pmo_population_fields
    String pmo_population_separator = "_"

    File? targeted_reference
    File? genome_reference

    String docker_image
  }

  Boolean has_pmo = defined(pmo)
  Boolean has_allele_table = defined(allele_table)

  if (has_pmo && has_allele_table) {
    call fail_t.fail as fail_both_pmo_and_allele_table {
      input:
        message = "Invalid inputs: provide exactly one of `pmo` or `allele_table`, not both."
    }
  }

  if (!has_pmo && !has_allele_table) {
    call fail_t.fail as fail_missing_pmo_and_allele_table {
      input:
        message = "Invalid inputs: missing required input. Provide one of `pmo` or `allele_table`."
    }
  }

  if (has_allele_table && !defined(panel_info_bed)) {
    call fail_t.fail as fail_missing_panel_info_bed {
      input:
        message = "Invalid inputs: `panel_info_bed` is required when providing `allele_table`."
    }
  }

  if (has_pmo) {
    call extract_allele_table_t.extract_allele_table as extract_allele_table {
      input:
        pmo = select_first([pmo]),
        docker_image = docker_image
    }
  }

  # Panel BED: if user provided it, use it; otherwise if PMO provided, derive it.
  if (!defined(panel_info_bed) && has_pmo) {
    call extract_panel_info_to_bed_t.extract_panel_info_to_bed as extract_panel_info_to_bed {
      input:
        pmo = select_first([pmo]),
        docker_image = docker_image,
        add_ref_seqs = false,
        out = "panel_info.bed"
    }

    # Add ref seqs if requested (prefer targeted reference if both provided).
    if (defined(targeted_reference)) {
      call add_ref_seqs_t.add_ref_seqs_with_fasta as add_ref_seqs_targeted {
        input:
          ref_bed = extract_panel_info_to_bed.panel_info_bed,
          fasta = select_first([targeted_reference]),
          docker_image = docker_image,
          out_bed = "panel_info_with_ref_seqs.bed"
      }
    }
    if (!defined(targeted_reference) && defined(genome_reference)) {
      call add_ref_seqs_t.add_ref_seqs_with_genome as add_ref_seqs_genome {
        input:
          ref_bed = extract_panel_info_to_bed.panel_info_bed,
          genome = select_first([genome_reference]),
          docker_image = docker_image,
          out_bed = "panel_info_with_ref_seqs.bed"
      }
    }
  }

  # Population map from PMO fields if requested and no explicit population_assignment provided.
  if (!defined(population_assignment) && has_pmo && defined(pmo_population_fields)) {
    # Normalize comma-separated to space-separated, mirroring Nextflow behavior.
    String pmo_population_fields_norm = sub(select_first([pmo_population_fields]), "\\s*,\\s*", " ")
    call extract_population_map_from_pmo_t.extract_population_map_from_pmo as extract_population_map_from_pmo {
      input:
        pmo = select_first([pmo]),
        docker_image = docker_image,
        population_fields_space_separated = pmo_population_fields_norm,
        separator = pmo_population_separator
    }
  }

  # Outputs: make downstream wiring independent of which input mode was chosen.
  output {
    File allele_table_final = select_first([allele_table, extract_allele_table.allele_table_o])

    File panel_info_bed_final = select_first([
      panel_info_bed,
      add_ref_seqs_targeted.add_ref_seq_to_ref_bed_table_output,
      add_ref_seqs_genome.add_ref_seq_to_ref_bed_table_output,
      extract_panel_info_to_bed.panel_info_bed
    ])

    # Avoid select_first on two possibly-empty optionals (allele_table mode with no PMO
    # population extraction and no explicit map would crash at runtime).
    File? population_assignment_final = if defined(population_assignment) then population_assignment else if (!defined(population_assignment) && has_pmo && defined(pmo_population_fields)) then extract_population_map_from_pmo.population_map else population_assignment

    # Expose for use by downstream gating.
    Boolean has_population_assignment =
      defined(population_assignment_final)
  }
}

