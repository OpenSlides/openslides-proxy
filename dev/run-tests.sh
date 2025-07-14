#!/bin/bash

set -e

echo "########################################################################"
echo "###################### Proxy has no tests ##############################"
echo "########################################################################"

# Setup
LOCAL_PWD=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Linters
bash "$LOCAL_PWD"/run-lint.sh
