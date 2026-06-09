#!/usr/bin/env nextflow

process sayHello {
    input:
    val x

    output:
    stdout

    script:
    def sleepSeconds = x * 30 * 60
    """
    echo 'Sleeping for ${sleepSeconds} seconds (${x * 30} minutes)...'
    sleep ${sleepSeconds}
    echo 'Done after ${x * 30} minutes!'
    """
}

workflow {
    Channel.of(0, 1, 2, 3) | sayHello | view
}
