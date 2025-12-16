#!/bin/sh
echo -ne '\033c\033]0;Sands of Blood\a'
base_path="$(dirname "$(realpath "$0")")"
"$base_path/SandsOfBlood-PA0.1.5Linux.x86_64" "$@"
