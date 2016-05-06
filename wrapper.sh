#!/usr/bin/env bash
set -e

print_usage(){
>&2 cat <<EOF

Usage: {defuse|reference|get_reads}

	reference       runs create_reference_dataset.pl for generating defuse input files. Run this program first.
	defuse          runs the defuse tool
	get_reads       can be used on defuse output to retrieve reads supporting a breakpoint

Add -h to any command to get a usage statement

EOF
}



prog=$1
if [ -z "$prog" ]; then
	print_usage
        exit
fi
# remove first element from $@
shift
case "$prog" in
        defuse)
            defuse.pl "$@"
            ;;
         
        reference)
            create_reference_dataset.pl "$@"
            # remove the many superfluous files
            echo "deleting unnecessary files..."
            for i in $(cat /opt/defuse/remove.these); do
                rm /data/$i
            done
            # this file is needed but can be empty
            touch /data/defuse.cdna.fa
            ;;
         
        get_reads)
            get_reads.pl "$@"
            ;;
        *)
            print_usage
esac
