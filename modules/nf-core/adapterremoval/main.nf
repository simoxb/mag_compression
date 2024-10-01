process ADAPTERREMOVAL {
    tag "$meta.id"
    label 'process_medium'

    conda "bioconda::adapterremoval=2.3.2"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/adapterremoval:2.3.2--hb7ba0dd_0' :
        'biocontainers/adapterremoval:2.3.2--hb7ba0dd_0' }"

    input:
    tuple val(meta), path(reads)
    path(adapterlist)

    output:
    tuple val(meta), path("${prefix}.truncated.fastq")            , optional: true, emit: singles_truncated
    tuple val(meta), path("${prefix}.discarded.fastq")            , optional: true, emit: discarded
    tuple val(meta), path("${prefix}.pair{1,2}.truncated.fastq")  , optional: true, emit: paired_truncated
    tuple val(meta), path("${prefix}.collapsed.fastq")            , optional: true, emit: collapsed
    tuple val(meta), path("${prefix}.collapsed.truncated.fastq")  , optional: true, emit: collapsed_truncated
    tuple val(meta), path("${prefix}.paired.fastq")               , optional: true, emit: paired_interleaved
    tuple val(meta), path('*.settings')                              , emit: settings
    path "versions.yml"                                              , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def list = adapterlist ? "--adapter-list ${adapterlist}" : ""
    prefix = task.ext.prefix ?: "${meta.id}"

    if (meta.single_end) {
        """
        AdapterRemoval  \\
            --file1 $reads \\
            $args \\
            $list \\
            --basename ${prefix} \\
            --threads ${task.cpus} \\
            --seed 42 \\

        ensure_fastq() {
            if [ -f "\${1}" ]; then
                mv "\${1}" "\${1::-3}.fastq"
            fi

        }

        ensure_fastq '${prefix}.truncated'
        ensure_fastq '${prefix}.discarde'

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            adapterremoval: \$(AdapterRemoval --version 2>&1 | sed -e "s/AdapterRemoval ver. //g")
        END_VERSIONS
        """
    } else {
        """
        AdapterRemoval  \\
            --file1 ${reads[0]} \\
            --file2 ${reads[1]} \\
            $args \\
            $list \\
            --basename ${prefix} \\
            --threads $task.cpus \\
            --seed 42 \\

        ensure_fastq() {
            if [ -f "\${1}" ]; then
                mv "\${1}" "\${1::-3}.fastq"
            fi

        }

        ensure_fastq '${prefix}.truncated'
        ensure_fastq '${prefix}.discarded'
        ensure_fastq '${prefix}.pair1.truncated'
        ensure_fastq '${prefix}.pair2.truncated'
        ensure_fastq '${prefix}.collapsed'
        ensure_fastq '${prefix}.collapsed.truncated'
        ensure_fastq '${prefix}.paired'

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            adapterremoval: \$(AdapterRemoval --version 2>&1 | sed -e "s/AdapterRemoval ver. //g")
        END_VERSIONS
        """
    }

}
