#!/usr/bin/env bash

# source and run strocs theme

current_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

$current_dir/scripts/strocs.sh
