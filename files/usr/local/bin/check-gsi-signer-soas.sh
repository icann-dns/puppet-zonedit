#!/bin/bash
#
# Check SNS (Zonedit) and GSI status of a domain name hosted by ICANN
# Receive $1 as arg (domain name) 
#
PATH=/usr/local/bin:/usr/bin:/bin
debug=FALSE
SOAt=""

if [ -z "$1" ] ; then
   echo "ERROR: Must give a domain name as an argument."
   exit 2
else
   DOM="$1"
   DIGTCP="+tcp"
fi

if [ ! -z ${TCP} ] ; then 
   if [ ${TCP} -eq 1 ] ; then
      DIGTCP="+tcp"
   elif [ ${TCP} -eq 0 ] ; then
      DIGTCP=""
   fi
fi

function valid_ip() {
    local  ip=$1
    local  stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}

splitip () {
    local IFS
	IFS=.
	set -- $*
	echo "$@"
}

function Query() {
    domain=$1
    server=$2
	# Array SOA and Array KEY to get values.
    declare -a SOA=($(/usr/bin/dig -4 @${server} ${domain} SOA +tries=2 +time=2 +short ${DIGTCP}))
	#declare -a KEY=($(/usr/bin/dig -4 @${server} ${domain} DNSKEY +multiline +time=2 +tries=2 +tcp +dnssec ${DIGTCP}|egrep "RRSIG.DNSKEY" -A 1 |tail -n 1))
	KEY="$(dig @${server} ${domain} DNSKEY +dnssec ${DIGTCP}|egrep "RRSIG.*DNSKEY"| while read -r line ; do echo ${line} | cut -d " " -f11  ; done )"
	if [ "$debug" = TRUE ] ; then
	   /usr/bin/dig -4 @${server} ${domain} SOA +tries=1 +time=1 +short ${DIGTCP}
	   /usr/bin/dig -4 @${server} ${domain} DNSKEY +multiline +time=1 +tries=1 +dnssec ${DIGTCP}
	fi

    SER=${server}
	SERdesc=""
    SERrelax="FALSE"
	if valid_ip ${server} ; then
	   IP=($(splitip ${server}))
	   if [ "${IP[0]}" -eq "192" ] && [ "${IP[1]}" -eq "0" ] && [ "${IP[2]}" -eq "32" ] || [ "${IP[2]}" -eq "47" ] ; then
	      if [ "${IP[3]}" -eq "161" ] || [ "${IP[3]}" -eq "163" ] ; then
		     SERdesc="# NSD  ( SNS --> GSI )"
			 SERrelax=TRUE
	      elif [ "${IP[3]}" -eq "162" ] || [ "${IP[3]}" -eq "164" ] ; then
		     SERdesc="# Bind ( Out <-- GSI )"
          fi
	   fi
	else
	  SERdesc=""
	fi

	# Print Server
	if [ -z "${SERdesc}" ] ; then
 	   printf "%s %b %-23s %b" "#" "\033[0;32m" "${SER}" "\033[0m"
	else
 	   printf "%s %b %10s %b %-9s %b" "#" "\033[0;32m" "${SER}" "\033[0m\033[37m" "${SERdesc}" "\033[0m"
	fi

    # Check if there is a wrong SOA:
	# First we left the sns as is.
	if [[ "${server}" =~ "zonedit.dns.icann.org." ]]  ; then
       cSOA="\033[0;36m ${SOA[2]} \033[0m"
	   SOAt=""
	# Then we stablish the first one on the list to compare (usually gsi1.cjr)
	elif [ -z "${SOAt}" ] ; then
	   SOAt="${SOA[2]}"
       cSOA="\033[0;33m ${SOAt} \033[0m"
	# If SOA differs, then RED
	elif [ "${SOAt}" != "${SOA[2]}" ] ; then
	   if [ "${SERrelax}" = FALSE ] ; then
	         cSOA="\033[0;31m ${SOA[2]} \033[0m"
	   else
	   # if SOA differs but SERrelax is true, then is not red, but still different
	         cSOA="\033[0;37m ${SOA[2]} \033[0m"
			 SERrelax=FALSE
	   fi
	else
	   SOAt="${SOA[2]}"
       cSOA="\033[0;33m ${SOAt} \033[0m"	
	fi
    
	# Print SOA and KSK
	tKEY=""
	for i in $(echo ${KEY}|tr " " "\n"| sort -n) ; do tKEY+="${i} " ; done
	echo -e "Serial SOA: ${cSOA}; KSK:\033[0;36m ${tKEY} \033[0m"
}

function Header() {
    printf "##\033[1;34m $* \033[0m\n"
}

##########
## MAIN ##
##########

Header "QUERY FOR ZONE $DOM"
Header "Zonedit (SNS)"
for ser in {lax,iad}.zonedit.dns.icann.org. ; do
    Query ${DOM} ${ser}
done

Header "GSI"
for ser in 192.0.{32,47}.16{1..4} ; do
    Query ${DOM} ${ser}
done

Header "QUERY local resolver $(dig ${DIGTCP}|grep SERVER|cut -d " " -f2-)"
Header "Published NameServers (NS)"
for ser in $(dig $1 NS +short +cd ${DIGTCP}|sort); do
    Query ${DOM} ${ser}
done

Header "DS Records published"
#DSs="$(dig ${DOM} DS +time=1 +tries=1 +short ${DIGTCP} | cut -f1,3 -d ' ' | sort)"
DSs="$(dig ${DOM} DS +time=1 +tries=1 +noall +ans ${DIGTCP} | sort| grep ${DOM} | grep -v ";" | awk '{print $5 " " $7 "  (TTL: "  $2  ")"}')"
while read line; do
      printf "%s %b %-23s%b %s\n" "#" "\033[0;32m" "DS" "\033[0m" "${line}"
done <<< "$DSs"

Header "WHOIS info"
whois ${DOM} | egrep -i "(domain:|Domain Name:|organisation:|Registrar:)"
