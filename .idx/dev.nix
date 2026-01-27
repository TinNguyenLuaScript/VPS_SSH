{ pkgs, ... }: {
  channel = "stable-24.11";
  packages = [
    pkgs.docker
    pkgs.coreutils
    pkgs.gnugrep
    pkgs.sudo
    pkgs.unzip
    pkgs.netcat
    pkgs.curl
  ];
  services.docker.enable = true;
  idx.workspace.onStart = {
    ssh = ''
      set -e
      mkdir -p ~/vps
      cd ~/vps
      if ! docker ps -a --format '{{.Names}}' | grep -qx 'ubuntu-ssh'; then
        docker pull ubuntu:22.04
        docker run --name ubuntu-ssh -d \
          --shm-size 1g \
          -p 2222:22 \
          ubuntu:22.04 sleep infinity
      else
        docker start ubuntu-ssh || true
      fi
      while ! docker exec ubuntu-ssh /bin/true >/dev/null 2>&1; do sleep 1; done
      docker exec ubuntu-ssh bash -lc "
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -y
        apt-get install -y openssh-server curl ca-certificates tar
        mkdir -p /run/sshd
        echo root:root | chpasswd
        sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
        sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
        /usr/sbin/sshd
        mkdir -p /tmp/kami
        curl -L https://github.com/kami2k1/tunnel/releases/latest/download/kami-tunnel-linux-amd64.tar.gz | tar -xz -C /tmp/kami
        mv /tmp/kami/kami-tunnel /usr/local/bin/kami-tunnel || cp -f /tmp/kami/* /usr/local/bin/
        chmod +x /usr/local/bin/kami-tunnel
        rm -rf /tmp/kami
      "
      docker exec -it ubuntu-ssh /usr/local/bin/kami-tunnel tcp 22
      elapsed=0; while true; do echo "Time elapsed: $elapsed min"; ((elapsed++)); sleep 60; done
    '';
  };
}