
#This script should download the file specified in the first argument ($1)
#And place it in the directory specified in the second argument ($2)

if [ "$#" -lt 2 ] || [ "$#" -gt 4 ]
#Si no recibe los argumentos correctos sale del programa
then
    echo "Usage: $0 <url> <output_directory> [uncompress] [filter_word]"
    exit 1
fi

url=$1
outdir=$2

#Descargar el archivo ($1) y guardarlo en la carpeta especificada ($2)
echo "Downloading file..."
mkdir -p $outdir
wget -P $outdir $url
echo

# And *optionally*:
# - Uncompress the downloaded file with gunzip if the third argument ($3) contains the word "yes"

#Si recibe el tercer argumento y es "yes", descomprime el archivo
if [ "$#" -ge 3 ] && [ "$3" == "yes" ]
then
    echo "Uncompressing file..."
    filename=$(basename $url)
    gunzip $outdir/$filename
    echo
fi

# - Filter the sequences based on a word contained in their header lines:
#   sequences containing the specified word in their header should be **excluded**
#   Example of the desired filtering:
#       > this is my sequence
#       CACTATGGGAGGACATTATAC
#       > this is my second sequence
#       CACTATGGGAGGGAGAGGAGA
#       > this is another sequence
#       CCAGGATTTACAGACTTTAAA
#       If $4 == "another" only the **first two sequence** should be output

#Comprobar si hay cuarto argumento para filtrar
if [ "$#" -eq 4 ]
then
    filter_word=$4
    filename=$(basename "$url")

    #Comprobar que el archivo está descomprimido
    if [[ "$filename" == *.gz ]]
    then
        echo "File is compressed. Can not filter sequences."
        exit 1
    fi
    
    #Excluir las secuencias que contienen la palabra en el encabezado
    echo "Filtering sequence..."
    grep -A 1 -v ">$filter_word" "$outdir/$filename" > "$outdir/tmp.fasta"
    mv "$outdir/tmp.fasta" "$outdir/$filename"
    echo
fi
