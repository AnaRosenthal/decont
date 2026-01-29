
#Carpeta raíz de cada tipo de dato
DATA_DIR="data"
RESOURCES_DIR="res"
OUTPUT_DIR="out"
LOGS_DIR="log"

#Función para eliminar con confirmación
remove_dir() {
    dir="$1"
    if [ -d "$dir" ]
    then
        echo "Removing $dir..."
        rm -rf "$dir"
    else
        echo "$dir does not exist, skipping."
    fi
}

#Si no hay argumentos, eliminar todo
if [ $# -eq 0 ]; then
    remove_dir "$DATA_DIR"
    remove_dir "$RESOURCES_DIR"
    remove_dir "$OUTPUT_DIR"
    remove_dir "$LOGS_DIR"
else
    #Recorrer argumentos
    for arg in "$@"
    do
        case "$arg" in
            data) remove_dir "$DATA_DIR" ;;
            resources) remove_dir "$RESOURCES_DIR" ;;
            output) remove_dir "$OUTPUT_DIR" ;;
            logs) remove_dir "$LOGS_DIR" ;;
            *) echo "Unknown argument: $arg" ;;
        esac
    done
fi

echo "Cleanup finished."