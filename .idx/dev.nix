{ pkgs, ... }: {
  channel = "stable-24.11";
  packages = [
    pkgs.docker
    pkgs.netcat
  ];
  services.docker.enable = true;
  idx.workspace.onStart = {
    vps = ''
      set -e
      cd ~
      if ! docker ps -a --format '{{.Names}}' | grep -qx ubuntu-ssh; then
        docker pull ubuntu:22.04
        docker run --name ubuntu-ssh -d \
          --shm-size 1g \
          -p 2222:22 \
          ubuntu:22.04 \
          sleep infinity
      else
        docker start ubuntu-ssh || true
      fi
      docker exec ubuntu-ssh bash -lc "
        apt update &&
        apt install -y openssh-server wget htop &&
        mkdir -p /run/sshd &&
        sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config &&
        sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config &&
        echo root:root | chpasswd &&
        /usr/sbin/sshd
      "
      wget -O kami https://github.com/kami2k1/tunnel/releases/latest/download/kami-tunnel-linux-amd64
      chmod +x kami
      ./kami tcp 2222
      while true; do sleep 3600; done
    '';
  };
}