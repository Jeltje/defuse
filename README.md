# defuse

deFuse was developed and published by Andrew Mc Pherson *et al* (see References below). It is a software package for gene fusion discovery using RNA-Seq data (fastq files). 

The deFuse toolkit contains code to download and index a large amount of genome and EST data needed to run deFuse, as well as tools to manipulate the output. Details on download, installation and running deFuse can be found at https://bitbucket.org/dranew/defuse

**This repository contains code to create a docker implementation of the deFuse toolset.**

A docker image can be downloaded directly from dockerhub using
`docker pull jeltje/defuse`

## Installation

After getting the code via `git clone https://github.com/Jeltje/defuse.git`, 
change to the defuse directory and run 

``docker run -t jeltje/defuse .``

This will create a docker container with all necessary tools installed.

## Running the docker container

For details on running docker containers in general, see the excellent tutorial at https://docs.docker.com/linux/

To see a usage statement, run

``
docker run jeltje/defuse
``

The docker installation is set up to run three deFuse tools:
  - create_reference_dataset
  - defuse
  - get_reads (post processing)

All three tools need the same config file, which is provided in the repository (`config.txt`).

## Creating reference input

First, the reference dataset must be created by using the `reference` option in the container. This will create 109G of data, so
use a working directory with enough space!

First, copy `config.txt` to your working directory, then run

``docker run -v /path/to/workdir:/data jeltje/defuse reference -c hg38.config.txt``

**This may take up to 24 hours to complete**

## Running deFuse

The deFuse run *must be*  started from the same working directory as the reference run.

The fastq input files should be separated into forward and reverse reads, and copied to the working directory.

``docker run -v /path/to/workdir:/data jeltje/defuse defuse -c hg38.config.txt -o outdir -1 R1.fastq -2 R2.fastq -p 8 -l tmpout``

where

`outdir` is where all deFuse output will go

`R1.fastq` and `R2.fastq` are the forward and reverse read files

`p 8` is the number of processors allocated to the job

`tmpout` is used for temporary output and can be removed after the run. DeFuse does **not** remove this directory

## deFuse output

deFuse creates an ungodly amount of output. We'll get back to you on this.

## Running get_reads

Supporting reads for a given fusion prediction can be obtained using the get_reads.pl script. For a prediction with cluster_id=123 run the following command to obtain the spanning and split reads supporting the fusion.

``docker run -v /path/to/workdir:/data jeltje/defuse get_reads -c hg38.config.txt -o outdir -i 123``

This generates output. And we'll describe this output soon, we promise.

## References

deFuse: An Algorithm for Gene Fusion Discovery in Tumor RNA-Seq Data Andrew McPherson *et al*,
[PLOS computational Biology 2011] (http://journals.plos.org/ploscompbiol/article?id=10.1371/journal.pcbi.1001138)


