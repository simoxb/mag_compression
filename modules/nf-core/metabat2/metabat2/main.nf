process METABAT2_METABAT2 {
    tag "$meta.id"
    label 'process_medium'

    conda "bioconda::metabat2=2.15"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/metabat2:2.15--h986a166_1' :
        'biocontainers/metabat2:2.15--h986a166_1' }"

    input:
    tuple val(meta), path(fasta), path(depth)

    output:
    tuple val(meta), path("*.tooShort.fa")                    , optional:true, emit: tooshort
    tuple val(meta), path("*.lowDepth.fa")                    , optional:true, emit: lowdepth
    tuple val(meta), path("*.unbinned.fa")                    , optional:true, emit: unbinned
    tuple val(meta), path("*.tsv.gz")                            , optional:true, emit: membership
    tuple val(meta), path("*[!lowDepth|tooShort|unbinned].fa"), optional:true, emit: fasta
    path "versions.yml"                                                         , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args             = task.ext.args   ?: ''
    def prefix           = task.ext.prefix ?: "${meta.id}"
    def decompress_depth = depth           ? "gzip -d -f $depth"    : ""
    def depth_file       = depth           ? "-a ${depth.baseName}" : ""
    """
    $decompress_depth

    metabat2 \\
        $args \\
        -i $fasta \\
        $depth_file \\
        -t $task.cpus \\
        --saveCls \\
        -o ${prefix}

    gzip -cn ${prefix} > ${prefix}.tsv.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        metabat2: \$( metabat2 --help 2>&1 | head -n 2 | tail -n 1| sed 's/.*\\:\\([0-9]*\\.[0-9]*\\).*/\\1/' )
    END_VERSIONS
    """
}
