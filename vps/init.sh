#!/usr/bin/bash

__filename=$(realpath "${BASH_SOURCE[0]}")
__dirname=$(dirname $__filename)
. "${__dirname}/ansi.sh"

mkdir -p $HOME/bin
mkdir -p $HOME/.local/bin

PATH=$PATH:$HOME/bin:$HOME/.local/bin
prmt_prompt="PS1='\$(prmt --code \$? \"\\n{env:#666666:USER} {path:blue} {git:#666666}\\n{ok:purple}{fail:red} \")'"
__arch=$( [ "$(uname -m)" = "x86_64" ] && echo amd64 || echo arm64 )

_echo() {
    lines=$(printf "%0.s─" {1..10})
    printf "${BLUE}${lines}${NORMAL} $1"
}

exists() {
    local cli="$1"
    local var="$2"

    if command -v "$cli" >/dev/null 2>&1 || [[ -n "$var" ]]; then
        _echo "${GREEN}$cli exists${NORMAL}\n"
        return 0
    else
        _echo "${RED}$cli does not exist${NORMAL}\n"
        return 1
    fi
}

ins_eget() {
    if ! exists eget; then
        curl https://zyedidia.github.io/eget.sh | sh
        mv eget $HOME/.local/bin
    fi
}
ins_ncdu() {
    if ! exists ncdu; then
        sudo apt install -y ncdu
    fi
}
ins_java() {
    if ! exists java; then
        mkdir -p $HOME/.java

        eget adoptium/temurin25-binaries -a jre -a ^json -a ^sha -a ^sig -a ^alpine -d

        file=$(ls *.tar.gz)
        tar -xvzf "$file" -C $HOME/.java --strip-components=1
        rm -rf "$file"

        grep -q "export JAVA_HOME" $HOME/.bashrc || {
            echo 'export JAVA_HOME=$HOME/.java/bin' >> $HOME/.bashrc
            echo '[[ ":$PATH:" != *":$JAVA_HOME:"* ]] && PATH="$JAVA_HOME:$PATH"' >> $HOME/.bashrc
        }
    fi
}
ins_rust() {
    if ! exists cargo; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
        . $HOME/.cargo/env
        rustup component remove rust-docs
        rustup set profile minimal
        cargo install cargo-clean
        cargo cache -a
    fi
}
ins_docker() {
    if ! exists docker; then
        sudo apt install ca-certificates curl
        sudo install -m 0755 -d /etc/apt/keyrings
        sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
        sudo chmod a+r /etc/apt/keyrings/docker.asc
        sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF
        sudo apt update
        sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

        # https://docs.docker.com/engine/install/linux-postinstall#manage-docker-as-a-non-root-user
        (sudo groupadd docker)

        if [ -z "${USER}" ]; then
            USER=$(whoami)
        fi

        _echo "${USER}"
        sudo usermod -aG docker $USER
    fi
}
ins_bottom() {
    if ! exists bottom && ! exists btm; then
        eget ClementTsang/bottom --to=$HOME/.local/bin
    fi
}
ins_micro() {
    if ! exists micro; then
        eget zyedidia/micro --to=$HOME/.local/bin
        grep -q "EDITOR=micro" $HOME/.bashrc || echo 'export EDITOR=micro' >> $HOME/.bashrc
        mkdir -p $HOME/.config/micro
        tee $HOME/.config/micro/settings.json <<EOF
{
    "colorscheme": "gruvbox",
    "ftoptions": false,
    "tabstospaces": true
}
EOF
    fi
}
ins_lazydocker() {
    if ! exists lazydocker; then
        eget jesseduffield/lazydocker --to=$HOME/.local/bin
    fi
}
ins_nvm() {
    if grep -q "NVM_DIR" $HOME/.bashrc; then
        _echo "${GREEN}nvm exists${NORMAL}\n"
    else
        _echo "${RED}nvm does not exist${NORMAL}\n"
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
    fi
}
ins_just() {
    if ! exists just; then
        eget casey/just --to=$HOME/.local/bin
        grep -q "just --completions" $HOME/.bashrc || echo 'eval "$(just --completions bash)"' >> $HOME/.bashrc
    fi
}
ins_prmt() {
    if ! exists prmt; then
        eget 3axap4eHko/prmt --to=$HOME/.local/bin
        grep -q "prmt" $HOME/.bashrc || echo "PS1='\$(prmt --code \$? \"\\n{env:#666666:USER} {path:blue} {git:#666666}\\n{ok:purple}{fail:red} \")'" >> $HOME/.bashrc
    fi
}
ins_gitsnip() {
    if ! exists gitsnip; then
        eget dagimg-dot/gitsnip --to=$HOME/.local/bin
    fi
}
ins_minikube() {
    if ! exists minikube; then
        curl -LO https://github.com/kubernetes/minikube/releases/latest/download/minikube-linux-${__arch}
        sudo install minikube-linux-${__arch} /usr/local/bin/minikube && rm minikube-linux-${__arch}
    fi
}

_echo "Adjusting path if necessary\n"
grep -q ".local/bin" $HOME/.bashrc || {
    echo '[[ ":$PATH:" != *":$HOME/bin:"* ]] && PATH="$HOME/bin:$PATH"' >> $HOME/.bashrc
    echo '[[ ":$PATH:" != *":$HOME/.local/bin:"* ]] && PATH="$HOME/.local/bin:$PATH"' >> $HOME/.bashrc
}

_echo "Copy/inserting own files\n"
cp "${__dirname}/.inputrc" $HOME/
grep -q "${__dirname}/motd.sh" $HOME/.profile || echo "${__dirname}/motd.sh" >> $HOME/.profile

_echo "Installing packages\n"
# (sudo service packagekit restart)

# sudo apt update
# sudo apt upgrade -y
# sudo apt install -y build-essential
# sudo apt update
# (sudo snap refresh)

# ins_eget
# ins_ncdu
# ins_java
# ins_rust
# ins_docker
# ins_bottom
# ins_micro
# ins_lazydocker
# ins_nvm
# ins_just
# ins_gitsnip
ins_minikube
# ins_prmt

# ensure prmt line is last in .bashrc if it exists
grep -q "prmt" $HOME/.bashrc && sed -i '/prmt/d' $HOME/.bashrc && echo "${prmt_prompt}" >> $HOME/.bashrc

# sudo apt update
# sudo apt upgrade -y

_echo "Finished installing packages\n"

_echo "Edit ${YELLOW}.profile${NORMAL} and ${YELLOW}.bashrc${NORMAL} if necessary\n"
_echo "Reboot the system if necessary: ${YELLOW}sudo systemctl reboot${NORMAL}\n"