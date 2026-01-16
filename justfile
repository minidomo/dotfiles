set windows-shell := ['pwsh.exe', '-NoLogo', '-Command']
set shell := ['bash', '-uc']

_default:
    @just --list

vps:
    docker compose run --build --remove-orphans vps bash

clean:
    docker compose down --rmi all -v --remove-orphans
