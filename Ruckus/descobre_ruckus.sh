#!/bin/bash
#
# versao 1.0
#
# NOME
#   descobre_ruckus.sh
#
# DESCRICAO
#   Esse script utiliza consultas SNMP ao controller Ruckus para gerar um JSON no Padrão Zabbix, que será utilizado  
# em uma regra LLD para descoberta de APs conectados ao Controller, ao final da execução é devolvido um JSON contendo duas 
# Macros {#NOMEAP} e {#OID} que contém respectivamente o nome do AP e o indice correpondente para consultas de quantidade
# de clientes conectados.
#
# NOTA
#   Esse script gera dois arquivos temporários que são sobrescritos a cada execução /tmp/ruckus.tmp e /tmp/ruckus.json 
#   Esse script deve ser utilizado em conjunto com o template Ruckus, ele deve ser inserido na pasta /usr/lib/zabbix/externalscripts/
# concedido permissão para execução, alterado dono para usuário zabbix.
#
# AUTOR
#   Peterson Basso
#
# MODIFICADO_POR  (DD/MM/YYYY)
#   Peterson Basso     21/02/2017 - Primeira versao.
#

COMMUNITY=$1
CONTROLLER_IP=$2
CONTROLLER_NOME=$3

ips_ap=($(snmpwalk -v2c -c $COMMUNITY $CONTROLLER_IP 1.3.6.1.4.1.25053.1.2.2.4.1.1.1.1.16 2> /dev/null | cut -d" " -f 4))

nomes_ap=($(snmpwalk -v2c -c $COMMUNITY $CONTROLLER_IP 1.3.6.1.4.1.25053.1.2.2.4.1.1.1.1.5 2> /dev/null | cut -d" " -f 4 | tr -d \"))

snmpwalk -v2c -c $COMMUNITY $CONTROLLER_IP 1.3.6.1.4.1.25053.1.2.2.1.1.2.1.1.10 2> /dev/null > /tmp/ruckus.tmp

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

zabbix_sender -z 127.0.0.1 -s "$CONTROLLER_NOME" -k "descobreruckus" -o "$(cat /tmp/ruckus.json)"

echo 1
