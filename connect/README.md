## Addressing plan

Subnet A: 192.168.10.0/24
Subnet B: 192.168.20.0/24

Usable hosts: 254 per subnet (256 addresses - network address - broadcast address).
Why /24: easy to read, plenty of room for a small office, and space to grow.

Reserved addresses:

Subnet A (192.168.10.0/24)
- .0          network address
- .1          gateway
- .2          DHCP + DNS server
- .3          client A (static DHCP reservation, by MAC)
- .100-.200   DHCP pool
- .255        broadcast

Subnet B (192.168.20.0/24)
- .0          network address
- .1          gateway
- .2          client B (static)
- .255        broadcast