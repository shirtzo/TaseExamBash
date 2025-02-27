#!/bin/bash

recursive=false
verbose=false

file_types_and_commands=("gzip:gunzip:-f" "bzip2:bunzip2:-f" "Zip:unzip:-o" "compress:uncompress:-f" "tar:tar:-xvf")
IFS=":"
decompressed_files_counter=0
un_decompressed_files_counter=0

show_help_menu() {
    echo "Usage: extract [-h] [-r] [-v] file [file...]"
    echo "  -h    Use this flag if you want to show this help message"
    echo "  -r    Recursive mode - use this flag to unpack files in directories recursively"
    echo "  -v    Verbose mode - use this flag echo each file decompressed and warn for files that were not decompressed"
}

while getopts ":hvr" opt; do
        case ${opt} in
            h)
                show_help_menu
                ;;
            r)
                recursive=true
                ;;
            v)
                verbose=true
                ;;
            *)
                echo "Invalid option"
                exit 1
                ;;
        esac
    done

shift $((OPTIND -1))

check_file_type() {
    echo "$(file -b "$1")"
}

execute_unpack_command() {
  local file="$1"
  local cmd="$2"
  local flag="$3"

  $cmd $flag "$file"
}

unpack_file() {
local file="$1"
local file_type=$(check_file_type "$file")

   for entry in "${file_types_and_commands[@]}"; do
       read -r type command flag <<< "$entry"

       if echo "$file_type" | grep -q "$type" ; then
          execute_unpack_command "$file" "$command" "$flag"
          decompressed_files_counter=$((decompressed_files_counter+1))

          if [ "$verbose" == true ]; then
             echo "File: $file with type: $type was decompressed."
          fi

          return 0
       fi
   done

   if [ "$verbose" == true ]; then
      echo "Warning! file: $file was not decompressed. please check if file's type is unsupported or if it's not compressed."
   fi

   un_decompressed_files_counter=$((un_decompressed_files_counter+1))
}

extract() {
    local user_input="$1"

    if [ -d "$user_input" ]; then
       for file in "$user_input"/*; do
           if [ -f "$file" ]; then
              unpack_file "$file"
           elif [ -d "$file" ] && [ "$recursive" == true ]; then
              extract "$file"
           fi
       done
    elif [ -f "$user_input" ]; then
         unpack_file "$user_input"
    fi
}

return_un_decompressed_files() {
   return $un_decompressed_files_counter
}

if [ "$#" -eq 0 ]; then
   echo "Empty input! try again."

else
   for user_input in "$@"; do
       if [ ! -e "$user_input" ]; then
          echo "File or folder with the name $user_input doesn't exist! try again."
       else
          extract "$user_input"
       fi
   done
fi

echo "Number of files decompressed: $decompressed_files_counter"