# Galactica k8s

### HW Setup

[This guide](https://forum.proxmox.com/threads/simple-working-gpu-passthrough-on-uptodate-pve-and-amd-hardware.145462/).

Driver: `https://us.download.nvidia.com/XFree86/Linux-x86_64/550.76/NVIDIA-Linux-x86_64-550.76.run`

NOTE: I disabled secureboot in the uefi settings on first boot, maybe this fixed it?

```shell
wget https://us.download.nvidia.com/XFree86/Linux-x86_64/550.76/NVIDIA-Linux-x86_64-550.76.run
chmod +x NVIDIA-Linux-x86_64-550.76.run
sudo apt install linux-headers-$(uname -r) build-essential
sudo ./NVIDIA-Linux-x86_64-550.76.run

lshw -C display
lspci -v
dmesg | grep -i vfio

cd /usr/share/kvm
wget https://www.techpowerup.com/vgabios/244469/244469.rom
mv 244469.rom p2000.rom
```

### 