
echo "############ Starting pipeline at $(date +'%H:%M:%S')... ##############"

#Download all the files specified in data/filenames
for url in $(<data/urls)
do
    bash scripts/download.sh "$url" data
done


# Download the contaminants fasta file, uncompress it, and
# filter to remove all small nuclear RNAs
bash scripts/download.sh \
    https://bioinformatics.cnio.es/data/courses/decont/contaminants.fasta.gz \
    ./res yes "snRNA|small nuclear RNA"


# Index the contaminants file
bash scripts/index.sh res/contaminants.fasta res/contaminants_idx


# Merge the samples into a single file
for sid in $(basename -a data/*.fastq.gz | cut -d "-" -f1 | sort | uniq)
do
    bash scripts/merge_fastqs.sh data out/merged "$sid"
done


# TODO: run cutadapt for all merged files
#Quitar los adaptadores de los FASTQ con cutadapt
echo "Running cutadapt..."
mkdir -p log/cutadapt 
mkdir -p out/trimmed
#Bucle que recorre todos los archivos merged
for merged_file in out/merged/*.fastq.gz
do
    sampleid=$(basename "$merged_file" .fastq.gz)
    # Definir el nombre del archivo de salida y del log
    trimmed_file="out/trimmed/${sampleid}.trimmed.fastq.gz"
    log_file="log/cutadapt/${sampleid}.log"
    # Ejecutar cutadapt
    cutadapt \
        -m 18 \
        -a TGGAATTCTCGGGTGCCAAGG \
        --discard-untrimmed \
        -o "$trimmed_file" "$merged_file" > "$log_file"
    echo
done


# TODO: run STAR for all trimmed files
#Alineamiento con STAR
echo "Running STAR alignment..."
for fname in out/trimmed/*.fastq.gz
do
    # you will need to obtain the sample ID from the filename
    sid=$(basename "$fname" .trimmed.fastq.gz)
    outdir="out/star/$sid"
    mkdir -p "$outdir"
    #Ejecutar STAR
    STAR \
        --runThreadN 4 \
        --genomeDir res/contaminants_idx \
        --outReadsUnmapped Fastx \
        --readFilesIn "$fname" \
        --readFilesCommand gunzip -c \
        --outFileNamePrefix "$outdir/"
    echo
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
echo "Cutadapt summary:" >> "$pipeline_log"
for clog in log/cutadapt/*.log
do
    sid=$(basename "$clog" .log)
    echo "Sample: $sid" >> "$pipeline_log"
    grep -E "Reads with adapters" "$clog" >> "$pipeline_log"
    grep -E "Total basepairs" "$clog" >> "$pipeline_log"
    echo "" >> "$pipeline_log"
done

#Información de STAR
echo "STAR alignment summary:" >> "$pipeline_log"
for slog in out/star/*/Log.final.out
do
    sid=$(basename "$(dirname "$slog")")
    echo "Sample: $sid" >> "$pipeline_log"
    grep -E "Uniquely mapped reads %" "$slog" | sed 's/^[[:space:]]*//' >> "$pipeline_log"
    grep -E "% of reads mapped to multiple loci" "$slog" | sed 's/^[[:space:]]*//' >> "$pipeline_log"
    grep -E "% of reads mapped to too many loci" "$slog" | sed 's/^[[:space:]]*//' >> "$pipeline_log"
    echo "" >> "$pipeline_log"
done


echo "############ Pipeline finished at $(date +'%H:%M:%S') ##############"
