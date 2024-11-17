I'm using oracle cloud right now, just to host vpn, authentik, and uptime kuma.

Open ports:
```bash
sudo su # login as root
iptables -I INPUT -j ACCEPT # will allow traffic
iptables-save > /etc/iptables/rules.v4 # persist configuration
exit
```

# Headscale
This should really be terraform, but I'll do it later.

Follow this: https://headscale.net/setup/install/official/

```bash
HEADSCALE_VERSION="0.23.0"
HEADSCALE_ARCH="arm64"
wget --output-document=headscale.deb  "https://github.com/juanfont/headscale/releases/download/v${HEADSCALE_VERSION}/headscale_${HEADSCALE_VERSION}_linux_${HEADSCALE_ARCH}.deb"
```

Manually add the record to cloudflare.

Open ports on oracle cloud: https://dev.to/armiedema/opening-up-port-80-and-443-for-oracle-cloud-servers-j35

Install client on opnsense, follow default guide, then enable following [this](https://forum.opnsense.org/index.php?topic=40079.0):

```
Thanks for the suggestion, will look into tunnels as a redundancy

Managed to configure routes correctly and now can access my LAN resources  from outside
For noobs like myself the reference:
I used this video as a main guide: https://www.youtube.com/watch?v=u_6Zd7Bo6J4

1. Install Headscale on a VPS (I used Oracle Free tier VPS, as suggested in video, AWS free also can be used)
2. Install Tailscale client on OPNsense: https://tailscale.com/kb/1097/install-opnsense
3. Add client to Headscale server (refer the video and KB article above)
4. Advertise exit node on OPNSene (refer to video and  https://tailscale.com/kb/1103/exit-nodes)
5. Advertise routes on OPNSense https://tailscale.com/kb/1019/subnets (there is no direct link for OPNsense, or FreeBSD, but you can use linux command, you need to use combined command including login server, exit node and route, but if you only advertise route, CLI will suggest full command including all above)
6. Make sure to enable subnet route as well for the internal LAN
Code: [Select]

sudo headscale routes enable -r ROUTE ID


Route ID can be found using
Code: [Select]

sudo headscale routes list

command on your VPS

Optional: install Headscale Web UI on VPS if you prefer it to CLI (there are several options on Github, or use following video tutorial: https://youtu.be/OKwrfmMoAk0?t=1750 for this one: https://github.com/iFargle/headscale-webui)
```

Actual command (run on opnsense shell): ` tailscale up --login-server=https://vpn.galactica.host --advertise-exit-node --advertise-routes=192.168.0.0/24 --accept-dns=false --accept-routes`

# Gitea

Install on the arm64, 1cpu 6g ram. Follow [this](https://docs.gitea.com/installation/install-from-binary)

`wget -O gitea https://dl.gitea.com/gitea/1.22.3/gitea-1.22.3-linux-arm64`
`sudo apt install git`

```bash
sudo adduser \
   --system \
   --shell /bin/bash \
   --gecos 'Git Version Control' \
   --group \
   --disabled-password \
   --home /home/git \
   git
```

```bash
sudo mkdir -p /var/lib/gitea/{custom,data,log}
sudo chown -R git:git /var/lib/gitea/
sudo chmod -R 750 /var/lib/gitea/
sudo mkdir /etc/gitea
sudo chown root:git /etc/gitea
sudo chmod 770 /etc/gitea

sudo cp gitea /usr/local/bin/gitea
```

Grab the gitea service example and configure it:

```bash
wget https://raw.githubusercontent.com/go-gitea/gitea/refs/heads/release/v1.22/contrib/systemd/gitea.service
sudo cp gitea.service /etc/systemd/system/gitea.service
sudo systemctl enable gitea
sudo systemctl start gitea
sudo service gitea status
```

Connect to the correct port to setup:

```bash
ssh -L 3000:localhost:3000 ubuntu@192.18.151.172
ssh -L 3000:localhost:3000 ubuntu@192.18.151.172
```

after installing, run:

```bash
sudo chmod 750 /etc/gitea
sudo chmod 640 /etc/gitea/app.ini
```

Set up https with:

```bash
sudo nano /etc/gitea/app.ini
```