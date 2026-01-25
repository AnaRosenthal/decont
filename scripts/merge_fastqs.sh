# This script should merge all files from a given sample (the sample id is
# provided in the third argument ($3)) into a single file, which should be
# stored in the output directory specified by the second argument ($2).
# The directory containing the samples is indicated by the first argument ($1).

# Comprobar argumentos
if [ "$#" -ne 3 ]
#Si no recibe los argumentos correctos sale del programa
then
    echo "Usage: $0 <input_dir> <output_dir> <sampleid>"
    exit 1
fi

input_dir=$1
output_dir=$2
sampleid=$3

# Crear el directorio de salida si no existe
mkdir -p "$output_dir"