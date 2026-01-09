FROM ubuntu:latest

# Update base system and install sudo + minimal tools
RUN apt update && apt install -y sudo bash-completion less vim curl git nano

# Create a non-root user (like a VPS user)
RUN useradd -m -s /bin/bash vpsuser \
    && usermod -aG sudo vpsuser \
    && echo "vpsuser ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Switch to the new user
USER vpsuser
WORKDIR /home/vpsuser
