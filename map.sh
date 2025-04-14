#!/bin/bash

set +m

files=0
items=0
folders=0
noHidden=0
noSubdir=0
folderSize="unknown file size"
randname="$HOME/Documents/map-""$RANDOM"".txt"

get_folder_size() {
    local folder="$1"
    local size
    # Use du to calculate the folder size and extract the size in a human-readable format
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
    local baseName
    local type
    local folder_size
    local ext

    if [ -d "$dir" ]; then
        while IFS= read -r -d $'\0' item; do
            # Get the raw filename first
            baseName=$(basename "$item")

            # Remove any carriage returns and handle special characters
            clean_name=$(echo "$baseName" | tr -d '\r' | sed 's/\\\([[:space:]()\\[\]]\)/\1/g')

            if [ "$noHidden" = "1" ]; then
                if [[ "$clean_name" == .* ]] || [[ "$(stat -f "%SHp" "$item" 2>/dev/null)" == *hidden* ]]; then
                    continue
                fi
            fi

            if [ -d "$item" ]; then
                # Increment folder count
                ((folders++))

                # Increment item count for any folder
                ((items++))

                baseName=$(basename "$item")

                case "$baseName" in
                *.app)
                    type="application"
                    ;;
                *.bundle)
                    type="bundle"
                    ;;
                *.framework)
                    type="framework"
                    ;;
                *.xcodeproj)
                    type="xcode project"
                    ;;
                *.xcworkspace)
                    type="xcode workspace"
                    ;;
                *)
                    type="folder"
                    ;;
                esac

                [[ "$only" == "files" ]] && continue

                if [ "$dirSize" = "1" ]; then
                    echo -ne "\r\033[0K${prefix}| - $baseName [$type, Calculating size...]\r"
                    # Calculate the folder size
                    folder_size=$(get_folder_size "$item")

                    # Clear the "Calculating size..." message and print the final result
                    echo -ne "\r\033[0K${prefix}| - $baseName [$type, ${folder_size}]\n"
                else
                    echo -ne "\r\033[0K${prefix}| - $baseName [$type]\n"
                fi
                # Save to file if required
                [[ "$save" == "save" ]] && [[ "$only" == "folders" || "$only" == "all" ]] && echo "${prefix}| - $baseName [folder, ${folder_size}]" >>"$randname"

                if [ "$ignorepkg" = "1" ] && [ "$type" != "folder" ]; then
                    continue
                fi
                [ "$noSubdir" = "0" ] && map_all_contents "$item" "${prefix}|   " "$save"

            elif [ -f "$item" ]; then
                # Increment file count
                ((files++))

                # Increment item count for any file
                ((items++))

                [[ "$only" == "folders" ]] && continue

                ext=$(get_extension "$item")
                # Print the cleaned filename
                printf "%s| - %s [%sfile]\n" "$prefix" "$clean_name" "${ext}"
                [[ "$save" == "save" ]] && [[ "$only" == "files" || "$only" == "all" ]] && printf "%s| - %s [%sfile]\n" "$prefix" "$clean_name" "${ext}" >>"$randname"
            fi
        done < <(find "$dir" -mindepth 1 -maxdepth 1 -print0 2>/dev/null | sort -z)
    fi
}

if [[ ! -e $1 ]]; then
    echo "ERROR: The provided path does not exist."
    exit 1
fi

if [[ ! -d $1 ]]; then
    echo "ERROR: The provided path is not a directory."
    exit 1
fi

# Ensure flags are only set when explicitly passed
if [[ "$*" == *"--ignore-hidden"* ]]; then
    noHidden="1"
else
    noHidden="0"
fi

if [[ "$*" == *"--save"* ]]; then
    save="save"
else
    save=""
fi

if [[ "$*" == *"--no-subdir"* ]]; then
    noSubdir="1"
else
    noSubdir="0"
fi

if [[ "$*" == *"--only-folders"* ]]; then
    only="folders"
else
    only="all"
fi

if [[ "$*" == *"--ignore-pkg-contents"* ]]; then
    ignorepkg="1"
else
    ignorepkg="0"
fi

if [[ "$*" == *"--no-size"* ]]; then
    dirSize="0"
else
    dirSize="1"
fi

# Optional clear screen
clear

# Initialize background monitoring variables
tempFile="/tmp/folderSize_$$.txt"
folderSizePid=""
folderSize="unknown file size"

# Start background folder size calculation
if [[ -d "$1" ]] && [ "$dirSize" = "1" ]; then
    (
        get_folder_size "$1" >"$tempFile"
        kill -USR1 $$
    ) &
    folderSizePid=$!
fi

# Set up signal handler for when size calculation completes
trap 'read_size() { 
    if [ -f "$tempFile" ]; then
        folderSize=$(<"$tempFile")
        [ -z "$folderSize" ] && folderSize="unknown file size"
        rm -f "$tempFile" 2>/dev/null
    else
        folderSize="unknown file size"
    fi
}; read_size' USR1

# Print directory name and map contents
realpath "$1"
[[ "$save" == "save" ]] && echo "$1" >"$randname"

if [[ "$1" != *"/" ]]; then
    # If the path does not end with a slash, add it
    dir="$1/"
else
    dir="$1"
fi
map_all_contents "$dir" "" "$save"

# If size calculation is still running, give it a moment to finish
if [ -n "$folderSizePid" ]; then
    wait_count=0
    while [ $wait_count -lt 3 ] && kill -0 $folderSizePid 2>/dev/null; do
        sleep 0.1
        ((wait_count++))
    done

    if kill -0 $folderSizePid 2>/dev/null; then
        # If still running after short wait, keep original "unknown file size" message
        true
    else
        # Read the final size if process completed
        [ -f "$tempFile" ] && folderSize=$(<"$tempFile")
        [ -z "$folderSize" ] && folderSize="unknown file size"
    fi
    rm -f "$tempFile" 2>/dev/null
fi

echo ''
if [[ "$save" == "save" ]]; then
    echo -e "\n[DONE - $files FILE$(if [[ $files -eq 1 ]]; then echo ""; else echo "S"; fi), $folders FOLDER$(if [[ $folders -eq 1 ]]; then echo ""; else echo "S"; fi), $items ITEM$(if [[ $items -eq 1 ]]; then echo ""; else echo "S"; fi), $folderSize TOTAL$(if [[ $noHidden -eq 1 ]]; then echo " (including hidden files), IGNORED HIDDEN FILES"; fi)$(if [[ $noSubdir -eq 1 ]]; then echo ", SUBDIRECTORIES IGNORED"; fi)$(if [[ $only == "folders" ]]; then echo ", FILES IGNORED"; fi)]" >>$randname
    echo "[DONE - $files FILE$(if [[ $files -eq 1 ]]; then echo ""; else echo "S"; fi), $folders FOLDER$(if [[ $folders -eq 1 ]]; then echo ""; else echo "S"; fi), $items ITEM$(if [[ $items -eq 1 ]]; then echo ""; else echo "S"; fi), $folderSize TOTAL$(if [[ $noHidden -eq 1 ]]; then echo " (including hidden files), IGNORED HIDDEN FILES"; fi)$(if [[ $noSubdir -eq 1 ]]; then echo ", SUBDIRECTORIES IGNORED"; fi)$(if [[ $only == "folders" ]]; then echo ", FILES IGNORED"; fi). MAP SAVED TO $randname]"
else
    echo "[DONE - $files FILE$(if [[ $files -eq 1 ]]; then echo ""; else echo "S"; fi), $folders FOLDER$(if [[ $folders -eq 1 ]]; then echo ""; else echo "S"; fi), $items ITEM$(if [[ $items -eq 1 ]]; then echo ""; else echo "S"; fi), $folderSize$(if [ ! "$folderSize" = "unknown file size" ]; then echo " TOTAL"; fi)$(if [[ $noHidden -eq 1 ]]; then echo " (including hidden files), IGNORED HIDDEN FILES"; fi)$(if [[ $noSubdir -eq 1 ]]; then echo ", SUBDIRECTORIES IGNORED"; fi)$(if [[ $only == "folders" ]]; then echo ", FILES IGNORED"; fi)]"
fi
