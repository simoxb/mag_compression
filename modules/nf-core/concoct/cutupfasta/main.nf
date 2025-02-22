
process CONCOCT_CUTUPFASTA {
    tag "$meta.id"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/concoct:1.1.0--py312h245ed52_6':
        'biocontainers/concoct:1.1.0--py312h245ed52_6' }"

    input:
    tuple val(meta), path(fasta)
    val(bed)

    output:
    tuple val(meta), path("${meta.id}.fasta"), emit: fasta
    tuple val(meta), path("*.bed")  , optional: true, emit: bed
    path "versions.yml"             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args       = task.ext.args ?: ''
    def prefix     = "${meta.id}"
    def bedfile    = bed ? "-b ${prefix}.bed" : ""
    if ("$fasta" == "${prefix}.fasta") error "Input and output names are the same, set prefix in module configuration to disambiguate!"
    """
    cut_up_fasta.py \\
        $fasta \\
        $args \\
        $bedfile \\
        > ${prefix}.fasta
    du -shk *

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        concoct: \$(echo \$(concoct --version 2>&1) | sed 's/concoct //g' )
    END_VERSIONS
    """

    stub:
    def args       = task.ext.args ?: ''
    def prefix     = task.ext.prefix ?: "${meta.id}"
    def bedfile    = bed ? "-b ${prefix}.bed" : ""
    if ("$fasta" == "${prefix}.fasta") error "Input and output names are the same, set prefix in module configuration to disambiguate!"
    """
    touch ${prefix}.fasta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        concoct: \$(echo \$(concoct --version 2>&1) | sed 's/concoct //g' )
    END_VERSIONS
    """
}
