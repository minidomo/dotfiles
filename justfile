[windows]
set shell := ['pwsh.exe', '-NoLogo', '-Command']
set unstable
set lists
set default-list

vps:
    docker compose run --build --remove-orphans vps bash

clean:
    docker compose down --rmi all -v --remove-orphans
