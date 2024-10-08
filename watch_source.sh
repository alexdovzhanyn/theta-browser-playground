#!/bin/bash

# Check if fswatch is installed
if ! command -v fswatch &> /dev/null
then
    echo "fswatch could not be found. Please install it first."
    exit 1
fi

# Check if browser-sync is installed
if ! command -v browser-sync &> /dev/null
then
    echo "browser-sync could not be found. Please install it first."
    exit 1
fi

# Check if a file to watch is provided
if [ -z "$1" ]
then
    echo "Usage: $0 path_to_file"
    exit 1
fi

FILE_TO_WATCH=$1
WASM_FILE="${FILE_TO_WATCH%.*}.wasm"
WASM_SOURCE_JSON="wasmSource.json"

# Function to run when file changes
run_command() {
    echo "File changed: $FILE_TO_WATCH"
    theta $FILE_TO_WATCH
    echo "{ \"wasm\": \"$WASM_FILE\" }" > $WASM_SOURCE_JSON
}

# Function to kill both processes
cleanup() {
    echo "Terminating processes..."
    kill $FSWATCH_PID $BROWSER_SYNC_PID
    exit 0
}

# Trap SIGINT and call cleanup
trap cleanup SIGINT

# Start browser-sync to watch the corresponding .wasm file
run_command
browser-sync start --server --files "$WASM_FILE" index.html &
BROWSER_SYNC_PID=$!

# Watch the original file for changes
fswatch -o $FILE_TO_WATCH | while read -r
do
    run_command
done &
FSWATCH_PID=$!

# Wait for processes to finish
wait $FSWATCH_PID $BROWSER_SYNC_PID
