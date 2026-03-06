#!/bin/sh
echo -ne '\033c\033]0;Sandals of Blood\a'
base_path="$(dirname "$(realpath "$0")")"
"$base_path/SandalsOfBlood-PA0.1.6Linux.x86_64" "$@"
