#!/bin/bash

ips_ap=($(snmpwalk -v2c -c COMM_PROC 10.212.248.3 1.3.6.1.4.1.25053.1.2.2.4.1.1.1.1.16 2> /dev/null | cut -d" " -f 4))

nomes_ap=($(snmpwalk -v2c -c COMM_PROC 10.212.248.3 1.3.6.1.4.1.25053.1.2.2.4.1.1.1.1.5 2> /dev/null | cut -d" " -f 4 | tr -d \"))

snmpwalk -v2c -c COMM_PROC 10.212.248.3 1.3.6.1.4.1.25053.1.2.2.1.1.2.1.1.10 2> /dev/null > /tmp/ruckus.tmp

rm -rf /tmp/ruckus.json

echo -e "{\n\t\"data\":[\n\n" >> /tmp/ruckus.json

linhas=${#ips_ap[@]}
x=0

for ip in "${ips_ap[@]}"; do
        let x=$x+1

        oid=$(grep "$ip" /tmp/ruckus.tmp | cut -d" " -f 1 | cut -d"." -f 12-)

        [ $x -ne $linhas ] && echo -e "\t{\n\t\t\"{#NOMEAP}\":\"${nomes_ap[$x-1]}\",\n\t\t\"{#OID}\":\"$oid\"\n\t}," >> /tmp/ruckus.json
        [ $x -eq $linhas ] && echo -e "\t{\n\t\t\"{#NOMEAP}\":\"${nomes_ap[$x-1]}\",\n\t\t\"{#OID}\":\"$oid\"\n\t}" >> /tmp/ruckus.json

#        let x=$x+1
done

echo -e "\n\t]\n}" >> /tmp/ruckus.json

zabbix_sender -z 127.0.0.1 -s "PROCEMPA-RUCKUS-CT01" -k "descobreruckus" -o "$(cat /tmp/ruckus.json)"

echo 1