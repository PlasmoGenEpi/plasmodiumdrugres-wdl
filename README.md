
# Nextflow-to-WDL Conversion Guide

This repository provides guidance and examples for converting **Nextflow** workflows to **WDL** (Workflow Description Language) workflows. Below are detailed notes, examples, and best practices for performing the conversion.

---

## WDL Specifications

Refer to the official WDL specification for detailed syntax and structure:
- [WDL Specification v1.2.0](https://github.com/openwdl/wdl/blob/release-1.2.0/SPEC.md)

---

## Documenting Tasks

When translating Nextflow help messages into WDL metadata:
- See the [Metadata Sections](https://github.com/openwdl/wdl/blob/release-1.2.0/SPEC.md#metadata-sections).

### Examples:
- Workflow metadata: [Broad Institute Workflow Metadata Example](https://github.com/broadinstitute/viral-pipelines/blob/master/pipes/WDL/workflows/align_and_count.wdl)
- Task parameters metadata: [Task Metadata Example](https://github.com/broadinstitute/viral-pipelines/blob/master/pipes/WDL/tasks/tasks_16S_amplicon.wdl)

---

## Creating the Workflow and Tasks

- **Nextflow's `main.nf`** corresponds to a **WDL Workflow**.
- **Nextflow Functions, Workflows, and Modules** are converted into WDL **Tasks** and **Subworkflows**.

### Defining Workflows:
- [Workflow Definition](https://github.com/openwdl/wdl/blob/release-1.2.0/SPEC.md#workflow-definition)
- [Subworkflow Definition](https://github.com/openwdl/wdl/blob/release-1.2.0/SPEC.md#workflow-hints)

### Defining Tasks:
- [Task Definition](https://github.com/openwdl/wdl/blob/release-1.2.0/SPEC.md#task-definition)

---

## Organizing Workflows and Tasks

### Recommended Directory Structure:
- Place workflows and tasks in separate directories to avoid bloating.
- Example:
  ```
  ├── Workflows/
  │   └── main_workflow.wdl
  ├── Tasks/
  │   ├── Task1/
  │   │   ├── task1.wdl
  │   │   ├── Dockerfile
  │   │   └── task1-support-files/
  │   └── Task2/
  │       ├── task2.wdl
  │       └── Dockerfile
  ```
- For tasks sharing a Docker container, create a shared `DOCKER/` folder.

### Importing Tasks into Workflows:
- Import tasks using `import`:
  ```wdl
  import "../Tasks/Prepare_Reference_Files/prepare_reference_files.wdl" as prepare_reference_files_t
  ```
- Use identifiers in task calls for debugging:
  ```wdl
  call prepare_reference_files_t.prepare_reference_files as t_001_prepare_reference_files { ... }
  ```

### Examples:
- Workflow example: [Broad Institute WDL Workflow](https://github.com/broadinstitute/malaria/blob/main/WDL/Workflows/wdl_ampseq.wdl)
- Task example: [Broad Institute WDL Task](https://github.com/broadinstitute/malaria/blob/main/WDL/Tasks/Amplicon_Denoising/amplicon_denoising.wdl)

---

## Chaining Tasks

To use the output of one task as the input of another:
- [Chaining Tasks in WDL](https://docs.openwdl.org/en/latest/WDL/chain_tasks_together/)

Example:
```wdl
call cutadapters_t.cutadapters as t_002_cutadapters {
    input:
        fastq1 = fastq1s[indx1],
        fastq2 = fastq2s[indx1]
}
call trimprimers_t.trimprimers as t_003_trimprimers {
    input:
        trimmed_fastq1 = t_002_cutadapters.fastq1_noadapters_o,
        trimmed_fastq2 = t_002_cutadapters.fastq2_noadapters_o
}
```

---

## Dockerizing Conda Environments and Bash Scripts

WDL requires all code and software to be accessible inside a Docker container.

### Example Dockerfile:
```dockerfile
FROM continuumio/miniconda3:4.12.0
WORKDIR /app
COPY qc-env.yml /app/qc-env.yml
RUN conda update -n base -c defaults conda -y && \
    conda env create -f /app/qc-env.yml && \
    conda clean --all --yes
SHELL ["conda", "run", "-n", "qc", "/bin/bash", "-c"]
CMD ["bash"]
```

### Adding Bash Scripts:
```dockerfile
COPY create_primer_files.sh /app/create_primer_files.sh
RUN chmod +x /app/create_primer_files.sh
```

---

## Testing WDL Locally

1. **Install Cromwell**:
   - [Cromwell Installation Guide](https://cromwell.readthedocs.io/en/stable/)

2. **Facilitate Testing**:
   Add these lines to WDL tasks to support chaining:
   ```wdl
   command <<<
       export TMPDIR=tmp
       set -euxo pipefail
       ...
   >>>
   ```

3. **Validate WDL Files**:
   Use `womtool`:
   ```bash
   womtool validate main_workflow.wdl
   ```

4. **Run Cromwell**:
   Run workflows locally:
   ```bash
   rm -rf cromwell-* | cromwell run path/to/main_workflow.wdl -i test.json
   ```

5. **Inspect Results**:
   Logs and results will be in the `cromwell-execution` directory.

---

For more details, refer to the WDL specification and linked resources. Contributions and issues are welcome!
