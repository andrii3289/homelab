#!/usr/bin/python
from sys import argv
from libvirt import openReadOnly
vm = {}
conn = openReadOnly('qemu:///system')
for lease in conn.networkLookupByName('default').DHCPLeases():
    vm[lease['hostname']] = lease['mac']
with open('/proc/net/arp') as f:
    for line in f.readlines():
        for k,v in vm.items():
            if v == line.split()[3]:
                if len(argv) > 1:
                    if argv[1] == "-f" or "--full":
                        print k,"has mac",v,"and","ip",line.split()[0]
                else:
                    print k,"has ip",line.split()[0]
