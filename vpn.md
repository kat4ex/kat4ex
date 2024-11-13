# Полезные ссылки

1. https://github.com/w0rng/amnezia-wg-easy  
1. https://github.com/xtrime-ru/antizapret-vpn-docker/blob/master/docs/guide_Keenetic_RU.md  
1. https://habr.com/ru/companies/amnezia/articles/807539/  
1. https://habr.com/ru/companies/xakep/articles/699000/  
1. https://qna.habr.com/q/1373210  
1. https://markodvin.gitbook.io/dfevlog/iptables/nastraivaem-iptables-dlya-dokera


# Конечный сервер (нл)
1. Склонировать репу
```bash
mkdir -p /app
cd /app
git clone https://github.com/w0rng/amnezia-wg-easy.git awg
cd /app/awg
```
2. Настроить env

> nano .env
```conf
WG_HOST=внешнее доменное имя сервера
# (Supports: en, ru, tr, no, pl, fr, de, ca, es)
LANGUAGE=ru
# порт веб морды
PORT=50080
# через что ходить наружу
WG_DEVICE=eth0
# порт, который слушает wg
WG_PORT=58211
# какие адреса выдавать клиентам
WG_DEFAULT_ADDRESS=10.6.0.x
# какой dns указывать в конфиге клиентов
WG_DEFAULT_DNS=1.1.1.1
# разрешенные ip адреса в конфиге клиентов
WG_ALLOWED_IPS=0.0.0.0/0, ::/0
# keep alive в конфиге клиентов
WG_PERSISTENT_KEEPALIVE=25
```

3. Подредачить `docker-compose.yml`
> nano docker-compose.yml
```yml
services:
  amnezia-wg-easy:
    env_file:
      - .env
    image: ghcr.io/w0rng/amnezia-wg-easy
    container_name: amnezia-wg-easy
    volumes:
      - ./data/etc:/etc/wireguard
    ports:
      - "${WG_PORT}:${WG_PORT}/udp"
      - "127.0.0.1:${PORT}:${PORT}/tcp" # docker игнорит iptables INPUT, поэтому ограничиваем доступ к порту (ссылка №6)
    restart: unless-stopped
    cap_add:
      - NET_ADMIN
      - SYS_MODULE
      # - NET_RAW # Uncomment if using Podman
    sysctls:
      - net.ipv4.ip_forward=1
      - net.ipv4.conf.all.src_valid_mark=1
    devices:
    - /dev/net/tun:/dev/net/tun
```

4. Запустить контейнер
```bash
docker-compose up -d
```

5. Пробросить порт по ssh
```bash
ssh -L 50080:127.0.0.1:50080 user@ip
```

6. Зайти в браузере по http://localhost:50080 и сгенерировать нового клиента
7. Скачать конфиг клиента


# Проксирующий сервер (мск)

1. Включить проброс трафика 

```bash
nano /etc/sysctl.conf
```

```conf
net.ipv4.ip_forward=1
```

Применить изменения
```bash
sysctl -p
```

2. Создать таблицу маршрутизации
```sh
echo 100 wgforward >> /etc/iproute2/rt_tables
```

3. Установить **wg** (`apt install wireguard`) и **awg** (*ссылка №3, в конце под спойлером*)

4. `/etc/wireguard/wg0.conf`
```conf
[Interface]
Table = wgforward
Address = 10.7.0.1/32
ListenPort = 58201
PrivateKey = ...
PostUp = ip rule add iif wg0 lookup wgforward
PostDown = ip rule del iif wg0 lookup wgforward

[Peer]
PublicKey = ...
AllowedIPs = 10.7.0.10/32
```

5. `/etc/amnezia/amneziawg/awg0.conf` (*взять скачанный конфиг и чуть подредачить*)
```conf
[Interface]
Table = wgforward
PrivateKey = ...
Address = 10.6.0.2/24
Jc = ...
Jmin = ...
Jmax = ...
S1 = ...
S2 = ...
H1 = ...
H2 = ...
H3 = ...
H4 = ...
PostUp = ip rule add iif awg0 lookup wgforward
PostUp = iptables -A POSTROUTING -o awg0 -j MASQUERADE -t nat
PostDown = ip rule del iif awg0 lookup wgforward
PostDown = iptables -D POSTROUTING -o awg0 -j MASQUERADE -t nat

[Peer]
PublicKey = ...
PresharedKey = ...
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
Endpoint = ip:port
```

6. Запустить сервисы
```bash
systemctl enable --now wg-quick@wg0
systemctl enable --now awg-quick@awg0
``` 
