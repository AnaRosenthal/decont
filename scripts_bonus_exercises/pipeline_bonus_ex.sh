
echo "############ Starting pipeline at $(date +'%H:%M:%S')... ##############"

# Download all the files specified in data/urls
while read -r url
do
    file="data/$(basename "$url")"
    #Descargar las muestras
    wget -nc -P data "$url"
    #MD5 check
    remote_md5=$(wget -qO- "${url}.md5" | awk '{print $1}')
    local_md5=$(md5sum "$file" | awk '{print $1}')

    if [ "$remote_md5" = "$local_md5" ]
    then
        echo "MD5 OK for $file"
        echo
    else
        echo "MD5 MISMATCH for $file"
        echo
    fi
done < data/urls


# Download the contaminants fasta file, uncompress it, and
# filter to remove all small nuclear RNAs
if [ -f res/contaminants.fasta ]
then
    echo "Contaminants fasta file already exists, skipping download."
    echo
else
    bash scripts/download.sh \
        https://bioinformatics.cnio.es/data/courses/decont/contaminants.fasta.gz \
        ./res yes "snRNA|small nuclear RNA"
fi


# Index the contaminants file
if [ -f res/contaminants_idx/Genome ]
then
    echo "Contaminants index already exists, skipping indexing."
    echo
else
    bash scripts/index.sh res/contaminants.fasta res/contaminants_idx
fi


# Merge the samples into a single file
for sid in $(basename -a data/*.fastq.gz | cut -d "-" -f1 | sort | uniq)
do
    merged_file="out/merged/${sid}.fastq.gz"
    if [ -f "$merged_file" ]
    then
        echo "Merged file for sample $sid already exists, skipping merging."
        echo
    else
        bash scripts/merge_fastqs.sh data out/merged "$sid"
    fi
done


# TODO: run cutadapt for all merged files
#Quitar los adaptadores de los FASTQ con cutadapt
echo "Running cutadapt..."
mkdir -p log/cutadapt 
mkdir -p out/trimmed
processed_cutadapt=()
#Bucle que recorre todos los archivos merged
for merged_file in out/merged/*.fastq.gz
do
    sampleid=$(basename "$merged_file" .fastq.gz)
    # Definir el nombre del archivo de salida y del log
    trimmed_file="out/trimmed/${sampleid}.trimmed.fastq.gz"
    log_file="log/cutadapt/${sampleid}.log"
    # Ejecutar cutadapt
    if [ -f "$trimmed_file" ]
    then
        echo "Trimmed file for sample $sampleid already exists, skipping cutadapt."
        echo
        continue
    else
        cutadapt \
            -m 18 \
            -a TGGAATTCTCGGGTGCCAAGG \
            --discard-untrimmed \
            -o "$trimmed_file" "$merged_file" > "$log_file"
        echo
        processed_cutadapt+=("$log_file")
    fi
done


# TODO: run STAR for all trimmed files
#Alineamiento con STAR
echo "Running STAR alignment..."
processed_star=()
for fname in out/trimmed/*.fastq.gz
do
    # you will need to obtain the sample ID from the filename
    sid=$(basename "$fname" .trimmed.fastq.gz)
    outdir="out/star/$sid"
    mkdir -p "$outdir"
    log_final="$outdir/Log.final.out"
    if [ -f "$log_final" ]
    then
        echo "STAR alignment for sample $sid already exists, skipping STAR."
        echo
        continue
    else
        #Ejecutar STAR
        STAR \
            --runThreadN 4 \
            --genomeDir res/contaminants_idx \
            --outReadsUnmapped Fastx \
            --readFilesIn "$fname" \
            --readFilesCommand gunzip -c \
            --outFileNamePrefix "$outdir/"
        echo
        processed_star+=("$log_final")
    fi
done


# TODO: create a log file containing information from cutadapt and star logs
# (this should be a single log file, and information should be *appended* to it on each run)
# - cutadapt: Reads with adapters and total basepairs
# - star: Percentages of uniquely mapped reads, reads mapped to multiple loci, and to too many loci
# tip: use grep to filter the lines you're interested in

echo "Creating pipeline log..."
mkdir -p log
pipeline_log="log/pipeline.log"

echo "" >> "$pipeline_log"
echo "######## Pipeline run on $(date) ########" >> "$pipeline_log"

#Información de cutadapt
if [ ${#processed_cutadapt[@]} -gt 0 ]
then
    echo "" >> "$pipeline_log"
    echo "Cutadapt summary:" >> "$pipeline_log"
    for clog in "${processed_cutadapt[@]}"
    do
        sid=$(basename "$clog" .log)
        echo "Sample: $sid" >> "$pipeline_log"
        grep -E "Reads with adapters" "$clog" >> "$pipeline_log"
        grep -E "Total basepairs" "$clog" >> "$pipeline_log"
        echo "" >> "$pipeline_log"
    done
else
    echo "" >> "$pipeline_log"
    echo "No cutadapt steps run, cutadapt summary skipped." >> "$pipeline_log"
    echo
fi


#Información de STAR
if [ ${#processed_star[@]} -gt 0 ]
then
    echo "STAR alignment summary:" >> "$pipeline_log"
    for slog in "${processed_star[@]}"
    do
        sid=$(basename "$(dirname "$slog")")
        echo "Sample: $sid" >> "$pipeline_log"
        grep -E "Uniquely mapped reads %" "$slog" | sed 's/^[[:space:]]*//' >> "$pipeline_log"
        grep -E "% of reads mapped to multiple loci" "$slog" | sed 's/^[[:space:]]*//' >> "$pipeline_log"
        grep -E "% of reads mapped to too many loci" "$slog" | sed 's/^[[:space:]]*//' >> "$pipeline_log"
        echo "" >> "$pipeline_log"
    done
else
    echo "No STAR log files found, STAR summary skipped." >> "$pipeline_log"
    echo
fi

echo "############ Pipeline finished at $(date +'%H:%M:%S') ##############"
