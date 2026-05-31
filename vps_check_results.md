# VPS Health Check Report

- **Generated:** 2026-05-26 19:18:03
- **Hostname:** vmi3278181
- **User:** root

---

## 1. System Info

```
--- OS ---
PRETTY_NAME="Ubuntu 26.04 LTS"
NAME="Ubuntu"
VERSION_ID="26.04"
VERSION="26.04 (Resolute Raccoon)"
VERSION_CODENAME=resolute

--- Kernel ---
7.0.0-14-generic

--- Uptime ---
 19:18:03 up 20 days, 57 min,  2 users,  load average: 1.05, 1.01, 0.91
```

---

## 2. Docker Status

```
--- Docker version ---
Docker version 29.1.3, build 29.1.3-0ubuntu4.1

--- Docker Compose ---
Docker Compose version 2.40.3+ds1-0ubuntu1

--- Docker service ---
active
```

---

## 3. Port Usage (80 / 443 / 8082)

```
LISTEN 0      4096       127.0.0.1:8010       0.0.0.0:*    users:(("docker-proxy",pid=84843,fd=7))                                                                                                  
LISTEN 0      511          0.0.0.0:80         0.0.0.0:*    users:(("nginx",pid=516172,fd=7),("nginx",pid=516171,fd=7),("nginx",pid=516170,fd=7),("nginx",pid=516169,fd=7),("nginx",pid=516167,fd=7))
LISTEN 0      511          0.0.0.0:443        0.0.0.0:*    users:(("nginx",pid=516172,fd=5),("nginx",pid=516171,fd=5),("nginx",pid=516170,fd=5),("nginx",pid=516169,fd=5),("nginx",pid=516167,fd=5))
LISTEN 0      4096         0.0.0.0:4433       0.0.0.0:*    users:(("docker-proxy",pid=3163156,fd=7))                                                                                                
LISTEN 0      4096         0.0.0.0:4434       0.0.0.0:*    users:(("docker-proxy",pid=3163178,fd=7))                                                                                                
LISTEN 0      4096         0.0.0.0:8081       0.0.0.0:*    users:(("docker-proxy",pid=3515040,fd=7))                                                                                                
LISTEN 0      4096         0.0.0.0:8080       0.0.0.0:*    users:(("docker-proxy",pid=642885,fd=7))                                                                                                 
LISTEN 0      4096         0.0.0.0:8001       0.0.0.0:*    users:(("docker-proxy",pid=646226,fd=7))                                                                                                 
LISTEN 0      511             [::]:80            [::]:*    users:(("nginx",pid=516172,fd=8),("nginx",pid=516171,fd=8),("nginx",pid=516170,fd=8),("nginx",pid=516169,fd=8),("nginx",pid=516167,fd=8))
LISTEN 0      511             [::]:443           [::]:*    users:(("nginx",pid=516172,fd=6),("nginx",pid=516171,fd=6),("nginx",pid=516170,fd=6),("nginx",pid=516169,fd=6),("nginx",pid=516167,fd=6))
LISTEN 0      4096            [::]:4433          [::]:*    users:(("docker-proxy",pid=3163164,fd=7))                                                                                                
LISTEN 0      4096            [::]:4434          [::]:*    users:(("docker-proxy",pid=3163185,fd=7))                                                                                                
LISTEN 0      4096            [::]:8081          [::]:*    users:(("docker-proxy",pid=3515048,fd=7))                                                                                                
LISTEN 0      4096            [::]:8080          [::]:*    users:(("docker-proxy",pid=642891,fd=7))                                                                                                 
LISTEN 0      4096            [::]:8001          [::]:*    users:(("docker-proxy",pid=646232,fd=7))                                                                                                 

--- All listening ports of interest ---
LISTEN 0      4096       127.0.0.1:8010       0.0.0.0:*    users:(("docker-proxy",pid=84843,fd=7))                                                                                                  
LISTEN 0      511          0.0.0.0:80         0.0.0.0:*    users:(("nginx",pid=516172,fd=7),("nginx",pid=516171,fd=7),("nginx",pid=516170,fd=7),("nginx",pid=516169,fd=7),("nginx",pid=516167,fd=7))
LISTEN 0      511          0.0.0.0:443        0.0.0.0:*    users:(("nginx",pid=516172,fd=5),("nginx",pid=516171,fd=5),("nginx",pid=516170,fd=5),("nginx",pid=516169,fd=5),("nginx",pid=516167,fd=5))
LISTEN 0      4096         0.0.0.0:4433       0.0.0.0:*    users:(("docker-proxy",pid=3163156,fd=7))                                                                                                
LISTEN 0      4096         0.0.0.0:4434       0.0.0.0:*    users:(("docker-proxy",pid=3163178,fd=7))                                                                                                
LISTEN 0      4096         0.0.0.0:9001       0.0.0.0:*    users:(("docker-proxy",pid=641310,fd=7))                                                                                                 
LISTEN 0      4096         0.0.0.0:9000       0.0.0.0:*    users:(("docker-proxy",pid=641278,fd=7))                                                                                                 
LISTEN 0      4096         0.0.0.0:8081       0.0.0.0:*    users:(("docker-proxy",pid=3515040,fd=7))                                                                                                
LISTEN 0      4096         0.0.0.0:8080       0.0.0.0:*    users:(("docker-proxy",pid=642885,fd=7))                                                                                                 
LISTEN 0      4096         0.0.0.0:8001       0.0.0.0:*    users:(("docker-proxy",pid=646226,fd=7))                                                                                                 
LISTEN 0      4096         0.0.0.0:3000       0.0.0.0:*    users:(("docker-proxy",pid=3691150,fd=7))                                                                                                
LISTEN 0      511             [::]:80            [::]:*    users:(("nginx",pid=516172,fd=8),("nginx",pid=516171,fd=8),("nginx",pid=516170,fd=8),("nginx",pid=516169,fd=8),("nginx",pid=516167,fd=8))
LISTEN 0      511             [::]:443           [::]:*    users:(("nginx",pid=516172,fd=6),("nginx",pid=516171,fd=6),("nginx",pid=516170,fd=6),("nginx",pid=516169,fd=6),("nginx",pid=516167,fd=6))
LISTEN 0      4096            [::]:4433          [::]:*    users:(("docker-proxy",pid=3163164,fd=7))                                                                                                
LISTEN 0      4096            [::]:4434          [::]:*    users:(("docker-proxy",pid=3163185,fd=7))                                                                                                
LISTEN 0      4096            [::]:9001          [::]:*    users:(("docker-proxy",pid=641318,fd=7))                                                                                                 
LISTEN 0      4096            [::]:9000          [::]:*    users:(("docker-proxy",pid=641284,fd=7))                                                                                                 
LISTEN 0      4096            [::]:8081          [::]:*    users:(("docker-proxy",pid=3515048,fd=7))                                                                                                
LISTEN 0      4096            [::]:8080          [::]:*    users:(("docker-proxy",pid=642891,fd=7))                                                                                                 
LISTEN 0      4096            [::]:8001          [::]:*    users:(("docker-proxy",pid=646232,fd=7))                                                                                                 
LISTEN 0      4096            [::]:3000          [::]:*    users:(("docker-proxy",pid=3691157,fd=7))                                                                                                
```

---

## 4. Existing Reverse Proxies / Web Servers

```sh
--- Nginx ---
nginx version: nginx/1.28.3 (Ubuntu)
Status: active
Config file: /etc/nginx/nginx.conf

--- Apache ---
apache2: NOT INSTALLED or NOT RUNNING

--- Caddy ---
caddy: NOT INSTALLED or NOT RUNNING

--- Traefik (standalone) ---
traefik: NOT RUNNING
```

**Result: Existing reverse proxy detected → Use Option A deployment**

---

## 5. System Resources

```
--- CPU ---
4

--- RAM ---
               total        used        free      shared  buff/cache   available
Mem:           7.8Gi       3.1Gi       3.8Gi        30Mi       1.2Gi       4.7Gi
Swap:             0B          0B          0B

--- Disk Space ---
Filesystem      Size  Used Avail Use% Mounted on
tmpfs           1.6G  2.1M  1.6G   1% /run
/dev/sda1       145G   39G  107G  27% /
tmpfs           3.9G     0  3.9G   0% /dev/shm
tmpfs           3.9G  872K  3.9G   1% /tmp
/dev/sda13      989M  150M  772M  17% /boot
/dev/sda15      105M  6.3M   99M   7% /boot/efi
none            1.0M     0  1.0M   0% /run/credentials/systemd-networkd.service
none            1.0M     0  1.0M   0% /run/credentials/getty@tty1.service
none            1.0M     0  1.0M   0% /run/credentials/serial-getty@ttyS0.service
overlay         145G   39G  107G  27% /var/lib/docker/rootfs/overlayfs/8b4f174ec21249cfecf4aa6bdaf596b35a4536222cbdad1af7e743880d2b790a
overlay         145G   39G  107G  27% /var/lib/docker/rootfs/overlayfs/e3db6c359384c6311b8dfb7ee70478efedf0c2f715159e9edf98a01b333cf83c
overlay         145G   39G  107G  27% /var/lib/docker/rootfs/overlayfs/6fe7e7e5f35f5a0eaa128640ca51f7ad7f4747c19961481396f698f05de21f1b
overlay         145G   39G  107G  27% /var/lib/docker/rootfs/overlayfs/9cfe5b6475161a1963f3ae39e68262bc8cb56670cc1f916bc4fc897c61518dde
overlay         145G   39G  107G  27% /var/lib/docker/rootfs/overlayfs/e0ed1b5523a4fcef4817dc3a2a3c952ba57050516bfee450ded7cb1bd29c81f7
overlay         145G   39G  107G  27% /var/lib/docker/rootfs/overlayfs/4e60e584e24eb483a2488e0932b307218b6e44e07512f165d3ccaa29acf355c0
overlay         145G   39G  107G  27% /var/lib/docker/rootfs/overlayfs/4cc4cbc3b5d80091258212b0d2296ef5dbf82dc939dfa0c6ebf200a738144e59
overlay         145G   39G  107G  27% /var/lib/docker/rootfs/overlayfs/07b577d7c733c8a9364606aa46fcf7706ba49ec962ca59dc09b6233dbbbe3e63
overlay         145G   39G  107G  27% /var/lib/docker/rootfs/overlayfs/8f665015a9814ddd74cb5fd8cf1b17cdad48978555f33d5097c898372970f6d1
overlay         145G   39G  107G  27% /var/lib/docker/rootfs/overlayfs/3fabffc5be0ad76989b058f41ece9f4e212a30b07bcb2bd51d640664c568b794
overlay         145G   39G  107G  27% /var/lib/docker/rootfs/overlayfs/3f2d8c766cda485bd7193853d7c1929a88c72e06aefb23f8ea3f9bfbd5c94504
none            1.0M     0  1.0M   0% /run/credentials/systemd-journald.service
none            1.0M     0  1.0M   0% /run/credentials/systemd-resolved.service
overlay         145G   39G  107G  27% /var/lib/docker/rootfs/overlayfs/52a9544d3f6f5db3e957f8f5af4feb5a81c2dc391f0a611764107f5f4433f0f3
tmpfs           794M  8.0K  794M   1% /run/user/0

--- Docker disk usage ---
TYPE            TOTAL     ACTIVE    SIZE      RECLAIMABLE
Images          13        12        29.84GB   29.59GB (99%)
Containers      13        12        6.226MB   16.38kB (0%)
Local Volumes   22        15        2.352GB   0B (0%)
Build Cache     343       0         32.18GB   30.9GB
```

---

## 6. Firewall Status

```
Status: inactive

--- iptables (brief) ---
Chain INPUT (policy ACCEPT)
target     prot opt source               destination         

Chain FORWARD (policy DROP)
target     prot opt source               destination         
DOCKER-USER  all  --  0.0.0.0/0            0.0.0.0/0           
DOCKER-FORWARD  all  --  0.0.0.0/0            0.0.0.0/0           

Chain OUTPUT (policy ACCEPT)
target     prot opt source               destination         

Chain DOCKER (2 references)
target     prot opt source               destination         
ACCEPT     tcp  --  0.0.0.0/0            172.18.0.12          tcp dpt:3000
ACCEPT     tcp  --  0.0.0.0/0            172.18.0.5           tcp dpt:8000
ACCEPT     tcp  --  0.0.0.0/0            172.18.0.13          tcp dpt:8080
ACCEPT     tcp  --  0.0.0.0/0            172.18.0.3           tcp dpt:9001
ACCEPT     tcp  --  0.0.0.0/0            172.18.0.3           tcp dpt:9000
ACCEPT     tcp  --  0.0.0.0/0            172.18.0.7           tcp dpt:80
ACCEPT     tcp  --  0.0.0.0/0            172.18.0.11          tcp dpt:4434
```

---

## 7. Security Checks

```
--- fail2ban ---
active

--- SSH password auth (likely disabled = good) ---
PermitRootLogin yes
```

---

## 8. Running Docker Containers

```
NAMES                STATUS                 PORTS
cv-ai-api-gateway    Up 2 days              0.0.0.0:3000->3000/tcp, [::]:3000->3000/tcp
cv-ai-ai-service     Up 3 days              0.0.0.0:8001->8000/tcp, [::]:8001->8000/tcp
cv-ai-kafka-worker   Up 3 days              8000/tcp
cv-ai-kafka-ui       Up 3 days              0.0.0.0:8080->8080/tcp, [::]:8080->8080/tcp
cv-ai-kafka          Up 3 days (healthy)    9092/tcp
cv-ai-surrealdb-ai   Up 3 days              
cv-ai-minio          Up 3 days              0.0.0.0:9000-9001->9000-9001/tcp, [::]:9000-9001->9000-9001/tcp
cv-ai-flutter-web    Up 3 days              0.0.0.0:8081->80/tcp, [::]:8081->80/tcp
cv-ai-kratos         Up 2 weeks             0.0.0.0:4433-4434->4433-4434/tcp, [::]:4433-4434->4433-4434/tcp
cv-ai-redis          Up 2 weeks             6379/tcp
cv-ai-kratos-db      Up 2 weeks (healthy)   5432/tcp
cv-ai-surrealdb      Up 2 weeks             127.0.0.1:8010->8000/tcp
```

---

## Summary

| Check | Status |
|-------|--------|
| Docker installed | See Section 2 |
| Port 80 occupied | See Section 3 |
| Port 443 occupied | See Section 3 |
| RAM ≥ 4GB | See Section 5 |
| Disk ≥ 40GB free | See Section 5 |
| Reverse proxy running | See Section 4 |
| Firewall active | See Section 6 |
| fail2ban active | See Section 7 |

