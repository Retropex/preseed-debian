in-target sed -i "/^deb[[:space:]]\+cdrom:/d" /etc/apt/sources.list 2>/dev/null
in-target apt-get update
in-target apt-get install -y bitcoin-knots/trixie-backports datum-gateway/trixie-backports curl/trixie-backports

cat happen_bashrc >> /target/home/box/.bashrc
touch /target/home/box/need_config
cp post_config.sh /target/usr/local/bin/
cp menu.sh /target/usr/local/bin/