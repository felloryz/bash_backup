#!/bin/bash

# Display help message
function display_help() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -c      Path to config file"
    echo "  -h      Display help"
}

# Check if arguments are not empty
if [ $# -eq 0 ]; then
    echo "Missing arguments"
    display_help
    exit 0
fi

# Parse options using getopts
while getopts ":c:h" OPTION; do
    case $OPTION in
        c)
            config_path=$OPTARG
            ;;
        h)
            display_help
            exit 0
            ;;
        \?)
            echo "Invalid option: -$OPTARG"
            display_help
            exit 0
            ;;
        :)
            echo "Option -$OPTARG requires an argument"
            display_help
            exit 0
            ;;
    esac
done

shift $((OPTIND-1)) # Shift script arguments

# Read source_paths
function read_source_paths() {
    # Path to config file
    local config_file=$1 

    # Initialize global array to store the source paths
    source_paths=()

    # Initialize a flag to indicate if we are reading the source paths section
    local reading_source_paths=false

    # Loop through each line of the input file
    while read -r line; do
        # If the line starts with source_paths:, set the flag to true and continue
        if [ $line == "source_paths:" ]; then
            reading_source_paths=true
            continue
        fi

        # If the line starts with backup_path:, set the flag to false and break
        if [ $line == "backup_path:" ]; then
            reading_source_paths=false
            break
        fi

        # If the flag is true, append the line to the source paths array
        if [[ $reading_source_paths == true ]]; then
            source_paths+=("$line")
        fi
    done < "$config_file"

    # Join the source paths array elements with a space and assign it to the variable
    source_paths="${source_paths[*]}"

}

read_source_paths "$config_path"
# echo "$source_paths"

# Read backup_paths
function read_backup_path() {
    # Path to config file
    local config_file=$1

    # A variable to store the found backup path
    backup_path_var=""

    # A flag to indicate if the keyword is found
    local is_found=0

    # Loop through each line of the input file
    while read -r line; do
        # If the line starts with backup_path:, set the flag
        if [ $line == "backup_path:" ]; then
            is_found=1
        # If the flag is 1, assign the next line to result and exit the loop
        elif [[ $is_found -eq 1 ]]; then
            backup_path_var="$line"
            break
        fi
    done < "$config_file"
}

read_backup_path "$config_path"
# echo "$backup_path_var"

# Read read_max_backups
function read_max_backups() {
    # Path to config file
    local config_file=$1

    # A variable to store the found backup path
    max_backup_value=0

    # A flag to indicate if the keyword is found
    local is_found=0

    # Loop through each line of the input file    
    while read -r line; do
        # If the line starts with max_backups:, set the flag
        if [ $line == "max_backups:" ]; then
            is_found=1
         # If the flag is 1, assign the next line to result and exit the loop
        elif [[ $is_found -eq 1 ]]; then
            max_backup_value="$line"
            break
        fi
    done < "$config_file"
}

read_max_backups "$config_path"
# echo $((max_backup_value))

# Get the current date and time in YYYY-MM-DD-HH-MM-SS format
DATE=$(date +"%Y-%m-%d-%H-%M-%S")

# Check if backup_path_var directory exists
if [ ! -d "$backup_path_var" ]; then
  # If it does not exist, create it
  mkdir "$backup_path_var"
fi

# Count the number of files with .tar.gz extension in the folder
count_backups=$(find $backup_path_var -maxdepth 1 -type f -name "*.tar.gz" | wc -l)

# echo "$max_backup_value"
# echo "$count_backups"

# If the number of files is more than 10, delete the first file
if [[ $count_backups -gt $((max_backup_value-1)) ]]; then
  # Find the first file by sorting by modification time in ascending order
  first_file=$(find $backup_path_var -maxdepth 1 -type f -name "*.tar.gz" | head -n 1)
  # Delete the first file and print a message
  rm $first_file
fi

tar -czf $backup_path_var/$DATE.tar.gz $source_paths