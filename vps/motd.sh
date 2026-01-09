#!/usr/bin/bash

__filename=$(realpath "${BASH_SOURCE[0]}")
__dirname=$(dirname $__filename)

. "${__dirname}/ansi.sh"

lines=$(printf "%0.s─" {1..70})

printf "${BLACK}${BOLD}${lines}${NORMAL}\n"
printf "${BLACK}${BOLD}from: ${__filename}${NORMAL}\n\n"

printf "${BG_BLUE} GREETING ${NORMAL} ${GREEN}Hello :)${NORMAL}\n"
