#!/usr/bin/env nextflow

process sayHello {
    input:
    val x

    output:
    stdout

    script:
    """
    echo '${x} world!'
    """
}

workflow {
//     Channel.of('Bonjour', 'Ciao', 'Hello', 'Hola') | sayHello | view
    Channel.of(
        // params.file.dot.string as dot format json keys are not supported
        params.config.deep.dive, params.cmdline.deep.dive, params.file.deep.dive) | sayHello | view
}
