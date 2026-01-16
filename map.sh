#!/bin/bash

set +m

files=0
items=0
folders=0
noHidden=0
noSubdir=0
version="1.1.1"
folderSize="unknown file size"
randname="$HOME/Documents/map-""$RANDOM"".txt"

get_folder_size() {
    local folder="$1"
    local size
    size=$(du -sh "$folder" 2>/dev/null | awk '{print $1}')
    if [[ "$size" == *"B" ]]; then
        echo "$size"
    else
        echo "$size"B
    fi
}

get_extension() {
    local file="$1"
    local ext="${file##*.}"
    if [ "$file" != "$ext" ] && [[ ! "$ext" == *"/"* ]]; then
        echo "$(echo "$ext" | tr '[:lower:]' '[:upper:]') "
    else
        echo ""
    fi
}

map_all_contents() {
    local dir="$1"
    local prefix="$2"
    local save="$3"
    
    local entries=()
    while IFS= read -r -d $'\0' entry; do
        # Filter hidden early if needed
        local bName=$(basename "$entry")
        if [ "$noHidden" = "1" ]; then
            if [[ "$bName" == .* ]] || [[ "$(stat -f "%SHp" "$entry" 2>/dev/null)" == *hidden* ]]; then
                continue
            fi
        fi
        entries+=("$entry")
    done < <(find "$dir" -mindepth 1 -maxdepth 1 -print0 2>/dev/null | sort -z)

    local total_entries=${#entries[@]}
    local current_idx=0

    # Separate into files and dirs to maintain "Files First" logic
    local file_list=()
    local dir_list=()
    for e in "${entries[@]}"; do
        if [ -d "$e" ]; then dir_list+=("$e"); else file_list+=("$e"); fi
    done

    # Combine them: files first, then directories
    local sorted_items=("${file_list[@]}" "${dir_list[@]}")
    local total_sorted=${#sorted_items[@]}

    for item in "${sorted_items[@]}"; do
        ((current_idx++))
        
        # Determine if this is the last item in the current folder
        local connector="├── "
        local new_prefix="${prefix}│   "
        if [ "$current_idx" -eq "$total_sorted" ]; then
            connector="└── "
            new_prefix="${prefix}    "
        fi

        local baseName=$(basename "$item")
        local clean_name=$(echo "$baseName" | tr -d '\r' | sed 's/\\\([[:space:]()\\[\]]\)/\1/g')

        if [ -f "$item" ]; then
            [[ "$only" == "folders" ]] && continue
            ((files++))
            ((items++))
            local ext=$(get_extension "$item")
            
            local line="${prefix}${connector}${clean_name} [${ext}file]"
            printf "%s\n" "$line"
            [[ "$save" == "save" ]] && echo "$line" >>"$randname"

        elif [ -d "$item" ]; then
            ((folders++))
            ((items++))
            
            local type
            case "$baseName" in
                *.app) type="application" ;;
                *.bundle) type="bundle" ;;
                *.framework) type="framework" ;;
                *.xcodeproj) type="xcode project" ;;
                *.xcworkspace) type="xcode workspace" ;;
                *) type="folder" ;;
            esac

            if [[ "$only" != "files" ]]; then
                local folder_display_size=""
                if [ "$dirSize" = "1" ]; then
                    echo -ne "\r\033[0K${prefix}${connector}${baseName} [$type, Calculating...]\r"
                    folder_display_size=$(get_folder_size "$item")
                    local line="${prefix}${connector}${baseName} [$type, ${folder_display_size}]"
                    echo -ne "\r\033[0K$line\n"
                else
                    local line="${prefix}${connector}${baseName} [$type]"
                    echo -ne "\r\033[0K$line\n"
                fi
                [[ "$save" == "save" ]] && echo "$line" >>"$randname"
            fi

            # Recursion
            if [ "$noSubdir" = "0" ]; then
                if [ "$ignorepkg" = "1" ] && [ "$type" != "folder" ]; then
                    continue
                fi
                map_all_contents "$item" "$new_prefix" "$save"
            fi
        fi
    done
}

# --- Initialization and Argument Parsing ---

if [[ -z "$1" ]] || [[ "$*" == *"--help"* ]]; then
    echo "Usage: $0 <directory> [options]"
    echo "Options:"
    echo "  --ignore-hidden       Ignore hidden files and folders"
    echo "  --save                Save the output to a file"
    echo "  --no-subdir           Ignore subdirectories"
    echo "  --only-folders        Only show folders"
    echo "  --ignore-pkg-contents Ignore package contents"
    echo "  --no-size             Do not calculate folder size"
    exit 0
fi

if [[ ! -d "$1" ]]; then
    echo "ERROR: The provided path is not a directory."
    exit 1
fi

# Flag detection
[[ "$*" == *"--ignore-hidden"* ]] && noHidden="1" || noHidden="0"
[[ "$*" == *"--save"* ]] && save="save" || save=""
[[ "$*" == *"--no-subdir"* ]] && noSubdir="1" || noSubdir="0"
[[ "$*" == *"--only-folders"* ]] && only="folders" || only="all"
[[ "$*" == *"--ignore-pkg-contents"* ]] && ignorepkg="1" || ignorepkg="0"
[[ "$*" == *"--no-size"* ]] && dirSize="0" || dirSize="1"

clear

# Handle Folder Size for root
tempFile="/tmp/folderSize_$$.txt"
if [[ -d "$1" ]] && [ "$dirSize" = "1" ]; then
    ( get_folder_size "$1" >"$tempFile"; kill -USR1 $$ ) &
    folderSizePid=$!
fi

trap 'if [ -f "$tempFile" ]; then folderSize=$(<"$tempFile"); rm -f "$tempFile"; fi' USR1

realpath "$1"
[[ "$save" == "save" ]] && realpath "$1" >"$randname"

# Run the map
map_all_contents "${1%/}" "" "$save"

# Final Stats Display
echo ''
stats="[DONE - $files FILES, $folders FOLDERS, $items ITEMS, $folderSize TOTAL]"
echo -e "$stats"
[[ "$save" == "save" ]] && echo -e "\n$stats" >>"$randname" && echo "MAP SAVED TO $randname"