## Export the path to the download data

# This gobblegook comes from stack overflow as a means to find the directory containing the current function: https://stackoverflow.com/a/246128
CODE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export CODE_DIR

echo BIDS codeFolder is $CODE_DIR

# exit 0
