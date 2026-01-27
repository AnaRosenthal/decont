
# This script should merge all files from a given sample (the sample id is
# provided in the third argument ($3)) into a single file, which should be
# stored in the output directory specified by the second argument ($2).
# The directory containing the samples is indicated by the first argument ($1).

#Comprobar argumentos
if [ "$#" -ne 3 ]
#Si no recibe los argumentos correctos sale del programa
then
    echo "Usage: $0 <input_dir> <output_dir> <sampleid>"
    exit 1
fi

input_dir=$1
output_dir=$2
sampleid=$3

#Crear el directorio de salida si no existe
mkdir -p "$output_dir"

#Nombre del archivo final
merged_file="$output_dir/${sampleid}.fastq.gz"

#Buscar los archivos que coincidan con el sampleid y si no hay ninguno salir
files=("$input_dir"/${sampleid}*.fastq.gz)
if [ ${#files[@]} -eq 0 ]; 
then
    echo "No FASTQ files found for sample $sampleid in $input_dir"
    exit 1
fi

#Combinar todos los FASTQ que contengan el sampleid
echo "Merging all FASTQs for sample $sampleid..."
zcat "$input_dir"/${sampleid}*.fastq.gz | gzip > "$merged_file"
echo "Merged file created at $merged_file"
echo
