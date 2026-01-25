
# This script should index the genome file specified in the first argument ($1),
# creating the index in a directory specified by the second argument ($2)

#Comprobar argumentos
if [ "$#" -ne 2 ]
then
    echo "Usage: $0 <genome_fasta> <output_dir>"
    exit 1
fi

genome_fasta=$1
outdir=$2

# The STAR command is provided for you. You should replace the parts surrounded
# by "<>" and uncomment it.

#Indexar genoma con STAR
echo "Running STAR index..."
mkdir -p "$outdir"
STAR \
    --runThreadN 4 \
    --runMode genomeGenerate \
    --genomeDir "$outdir" \
    --genomeFastaFiles "$genome_fasta" \
    --genomeSAindexNbases 9
echo
