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
  - `create_reference_dataset.pl`
  - `defuse.pl`, followed by `get_reads.pl`
It also provides a filtered results file as described below

All three tools need the same config file, which is provided in the repository (`hg38config.txt` and `hg19config.txt`).

## Creating reference input

First, the reference dataset must be created by using the `reference` option in the container. This will create 109G of data, so
use a working directory with enough space! The 109G is reduced to 38G before the program finishes.

First, copy `hg38config.txt` to your working directory, then run

``docker run -v /path/to/workdir:/data jeltje/defuse reference -c hg38config.txt``

**This may take up to 24 hours to complete**. The program creates a directory named `defuseData/` in your workdir. If you want to rename this, you must also change it in the config file.

## Running deFuse

The deFuse run *must be*  started from the same working directory as the reference run.

The fastq input files should be separated into forward and reverse reads, and copied to the working directory. Do not create symlinks to the files, docker does not accept those.

``docker run -v /path/to/workdir:/data jeltje/defuse defuse -c hg38config.txt -1 R1.fastq -2 R2.fastq -p 8 -o outdir``

where

`R1.fastq` and `R2.fastq` are the forward and reverse read files

`p 8` is the number of processors allocated to the job

`outdir` is where all deFuse output will go


**outdir and tmpout will be created by defuse**

## deFuse output

`defuse.pl` itself creates a large number of output files, many of which are needed to extract reads supporting the various breakpoints. Instead of retaining 20G of data, this docker container runs the `get_reads.pl` script for all contigs and stores the output in a directory named `supporting_reads`. 

The wrapper script inside the docker container also filters the `results.tsv` output using the following criteria:

 - `splitr_count > 1` At least 5 split reads
 - `span_count >10` at least 10 spanning reads
 - `orf = Y` fusion preserves an ORF,
 - `adjacent = N` fusion is not an alternative splice,
 - `altsplice = N` fusion does not affect adjacent genes,
 - `min_map_count = 1` at least one read supporting fusion is uniquely mapping
 - exclude fusions that include mitochondrion and HLA

See https://bitbucket.org/dranew/defuse for more details on these features.

The output of this filter is named `results.filtered.tsv`


## References

deFuse: An Algorithm for Gene Fusion Discovery in Tumor RNA-Seq Data Andrew McPherson *et al*,
[PLOS computational Biology 2011] (http://journals.plos.org/ploscompbiol/article?id=10.1371/journal.pcbi.1001138)


