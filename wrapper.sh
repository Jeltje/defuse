#!/bin/bash

set -e

print_usage(){
>&2 cat <<EOF

Usage: {defuse|reference}

	reference       runs create_reference_dataset.pl for generating defuse input files. Run this program first.
	defuse          runs the defuse tool and the get_reads.pl script followed by the get_reads script on all cluster IDs in the results file. Only results files and get_reads output are kept

Add -h to any command to get a usage statement

EOF
}

finish() {
    # Fix ownership of output files
    uid=$(stat -c '%u:%g' /data)
    chown -R $uid /data
}
trap finish EXIT

prog=$1
if [ -z "$prog" ]; then
    print_usage
    exit
fi

join() { local IFS="$1"; shift; echo "$*"; }

# remove first element from $@
shift
case "$prog" in
    defuse)
        # for post processing, get the name of the output dir and config file from the arguments
        procs=$(grep -c ^processor /proc/cpuinfo)
        for i in $(seq $#); do
            if [ "${!i}" == "-o" ] || [ "${!i}" == "--output" ]; then
                k=$i+1
                defuseOut=${@:$k:1}
            elif [ "${!i}" == "-p" ] || [ "${!i}" == "--parallel" ]; then
                k=$i+1
                procs=${@:$k:1}
            elif [ "${!i}" == "-c" ] || [ "${!i}" == "--config" ]; then
                k=$i+1
                configfile=${@:$k:1}
	    fi
        done
        # defuse allows an existing output directory but we don't
        if [ -d "$defuseOut" ]; then
            >&2 echo "$defuseOut already exists, please delete or rename"
            exit
        fi

        echo "starting deFuse..."
        defuse.pl "$@"

        # retrieve reads for results.tsv. Use a makefile to allow parallel processing
        tmpmk="/tmp/foo.$$.mk"
        mkdir $defuseOut/supporting_reads
        echo "Getting cluster reads..."
        names=$(cut -f1 $defuseOut/results.tsv | grep -v cluster_id)
        join ' ' reads = $names > $tmpmk
        echo 'all: ${reads}' >> $tmpmk
        echo >> $tmpmk
        for i in $names; do
            echo "$i:" >> $tmpmk
            echo "	get_reads.pl -c $configfile -o $defuseOut -i $i > $defuseOut/supporting_reads/cluster$i.reads" >>$tmpmk
            echo >> $tmpmk
        done
        make -f $tmpmk -j $procs
        echo "Cleaning up..."
        rm -rf $defuseOut/jobs $defuseOut/log $defuseOut/tmp
        
        for i in $(ls $defuseOut | grep -v ^supporting_reads | grep -v ^results); do
            rm $defuseOut/$i
        done
        # apply filter (in order of command:) 
        # $3>5 At least 5 split reads
        # $61>10 at least 10 spanning reads
        # $57~'Y' fusion preserves an ORF, 
        # $7~'N' fusion is not an alternative splice, 
        # $8~'N' fusion does not affect adjacent genes, 
	# $54=1 at least one read supporting fusion is uniquely mapping
        # exclude mitochondrial and HLA 
        awk '($3>=5)&&($61>=10)&&($57~"Y")&&($7~"N")&&($8~"N")&&($54=1){ print $0} ' $defuseOut/results.tsv | \
        grep -v MT | grep -v HLA > $defuseOut/results.filtered.tsv
        ;;
     
    reference)
        mkdir -p /data/defuseData
        create_reference_dataset.pl "$@"
        # don't continue if only help was printed
        if [ $# -eq 0 ] || [ $1 == '-h' ] || [ $1 == '--help' ]; then 
            exit
        fi
        # remove the many superfluous files
        echo "Deleting unnecessary files..."
        for i in $(cat /opt/defuse/remove.these); do
            rm /data/defuseData/$i
        done
        # this file is needed but can be empty
        touch /data/defuseData/defuse.cdna.fa
        ;;
     
    *)
        print_usage
esac
