## Readme ##

1) Create new VM

- Type: Linux
- Version: Debian (64-bit)
- Memory size: 512 MB (or more)
- Hard disk: VDI, Dynamic, 8 GB

- Before starting the VM, change its Network Settings:
-> Adapter 1: Bridged Adapter (Promiscuous Mode: Deny)
-> Adapter 2: Internal Network (Promiscuous Mode: Allow VMs)

2) Install Debian with the following options

- Download Debian ISO (debian-10.1.0-amd64-xfce-CD-1.iso)
- Choose Install (second option)

- Primary network interface
-> Chose the first one

- Hostname: vpn
- Domain: Leave blank

- User name and passwords: (your choice)

- Software to install:
-> uncheck everything and check:
SSH server
Standard System utilities

2) Get updates

- Get root (type su and enter)
apt-get update
apt-get install psmisc unzip openvpn

3) Configure /etc/network/interfaces

nano /etc/network/interfaces

** Edit with the name of your ethernet cards and IP range **
(type 'ip link show' to reveal the name of our ethernet cards)


# The loopback network interface
auto lo
iface lo inet loopback

# The bridged network interface
allow-hotplug enp0s3
iface enp0s3 inet static
        address 192.168.1.168
        netmask 255.255.255.0
        gateway 192.168.1.1
        network 192.168.1.0
        broadcast 192.168.1.255
        dns-nameservers 1.1.1.1 1.0.0.1

# the internal-only network interface
allow-hotplug enp0s8
iface enp0s8 inet static
        address 192.168.3.1
        netmask 255.255.255.0
        network 192.168.3.0
        broadcast 192.168.3.255
        dns-nameservers 1.1.1.1 1.0.0.1


4) Edit /etc/sysctl.conf

nano /etc/sysctl.conf

Uncomment net.ipv4.ip_forward=1
Uncomment (if you want to enable IPv6) net.ipv6.conf.all.forwarding=1

Add the following at the end of the file if you want to disable IPV6

# These edits EXPLICITLY disable IPV6
net.ipv6.conf.all.disable_ipv6 = 0
net.ipv6.conf.default.disable_ipv6 = 0
net.ipv6.conf.lo.disable_ipv6 = 0
net.ipv6.conf.eth0.disable_ipv6 = 0


5) Copy necessary files

(individually or simply ZIP them and then SCP)

scp countries.txt vpn@192.168.1.168:/home/vpn/
scp dn.sh vpn@192.168.1.168:/home/vpn/
scp up.sh vpn@192.168.1.168:/home/vpn/
scp VPN.sh vpn@192.168.1.168:/home/vpn/
scp vpnservice.sh vpn@192.168.1.168:/home/vpn/

chmod +x *.sh

6) Reboot VM

/sbin/reboot

7) Launch VPN rotator

Login as root then, run ./VPN.sh

