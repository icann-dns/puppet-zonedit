#!/bin/bash
# Update all the zones from the current serial to a newer one
# (todays date if older, +1 if date is already on that date)

zonesdir="/var/git_repos/zones"
gitbase="git@git.dns.icann.org:zonedit/zones.git"
today="$(date +%Y%m%d -u)00"
todaylast="$((today +99))"
tag="; serial"

if [ -z "${verbose}" ]    ; then verbose=true  ; fi
if [ -z "${force}" ]      ; then force=false   ; fi
if [ -z "${sleeptime}" ]  ; then sleeptime=120 ; fi
if [ -z "${limitzones}" ] ; then limitzones=15 ; fi
if [ -z "${exclude}" ]    ; then exclude=".100.in-addr.arpa$|d.f.ip6.arpa" ; fi
if [ -z "${dryrun}" ]     ; then dryrun=false  ; fi

if [ ${force} = "false" ] ; then
	echo "#################"
	echo "#### WARNING ####"
	echo "#################"
	echo "#"
	echo "# This script will bump every serial SOA for each zone in ${zonesdir}"
	echo "# AND will push it to git (unless dryrun=true)"
	echo
	read -n 1 -s -r -p "Press any key to continue"
	echo
fi

function PrintMessage(){
	if [ "${verbose}" = "true" ] ; then
		echo "$*"
	fi
}

#Looking for sed binaries (To use in MacOS)
SED=$(which gsed)
if [ $? -ne 0 ] ; then
	SED=$(which sed)
fi

function BumpZone(){
	ZONE=$1
	# Let's check if this are valid zones
	grep -q "SOA" ${ZONE}
	exitcode=$?
	if [ ${exitcode} -ne 0 ] ; then return ${exitcode} ; fi
	grep -q "; serial" ${ZONE}
	exitcode=$?
	if [ ${exitcode} -ne 0 ] ; then return ${exitcode} ; fi

	# hardcoded the zones
	if [[ ${ZONE} =~ (.100.in-addr.arpa$|d.f.ip6.arpa)$ ]] ; then
		echo "WARN: ${ZONE} shouldn't be bumped... are you sure?"
		read -n 1 -s -r -p " (CTRL+C to quit or ENTER to continue)"
		echo
	fi

	# Getting Current serial
	curr=$(grep -e "${tag}" ${ZONE}| awk '{print $1}')
	if [ ${curr} -lt ${today} ]; then
		serial="${today}"
	else
		if [ $((curr+1)) -le ${todaylast} ] ; then
			serial=$((curr+1))
		else
			echo "WARN: Serial for ${ZONE} is already ${curr}. Skipping update for this zone."
			continue
		fi
	fi
	${SED} -i -e "s/${curr}\([[:blank:]]*\)${tag}/${serial}\1${tag}/" ${ZONE}
	#git diff ${ZONE}
	PrintMessage "# Bumping ${ZONE} from ${curr} to ${serial}"
}

function CommitAndPush(){
	zonelist="$*"

	PrintMessage "# NOTICE: Running Git commit for ${zonelist}"
	if [ ${dryrun} = "false" ] ; then
		git commit ${zonelist} -m "Mega Bump of zones ${zonelist}"
		git push
	else
		echo "# NOT RUNNING (dryrun=true): git commit ${zonelist} -m \"Mega Bump of zones ${zonelist}\""
		echo "# NOT RUNNING (dryrun=true): git push"
	fi
	PrintMessage
	PrintMessage "# NOTICE: Sleeping ${sleeptime} seconds before next round"
	PrintMessage
	sleep ${sleeptime}
}

# Check if the Working DIR is the right git directory (
if [ ! -z "${1}" ] ; then zonesdir="${1}" ; fi
PrintMessage "# NOTICE: Changing to dir ${zonesdir}"
cd ${zonesdir}
PrintMessage

if [ -e .git/config ] ; then
	gitnew="$(grep url .git/config | awk '{ print $3}')"
	if [ "${gitbase}" != "${gitnew}" ] ; then
		echo
		echo "ERROR: Run this script inside a git zone managed folder"
		echo "       (i.e. ${gitbase})"
		exit 1
	fi
	else
		echo
		echo "ERROR: The dir ${zonesdir} is not the currently managed under git"
		echo "       (i.e. should be ${gitbase})"
		exit 1
fi

# Bring back the latest zones changes from Git
PrintMessage "# NOTICE: Updating git..."
git pull
if [ $? -ne 0 ] ; then
	echo
	echo "ERROR: Git needs manual revision first"
	echo "       ...or you can just rebuild from latest version: git reset --hard && git pull"
	exit 1;
fi
git status -s && git diff --quiet
if [ $? -ne 0 ] ; then
	echo
	echo "ERROR: Git needs manual revision first"
	echo "       ...or you can just rebuild from latest version: git reset --hard && git pull"
	exit 1;
fi

# Init counters, list and time of usage
cont=0
zonelist=""
NOW=$(date +%s)

PrintMessage "# NOTICE: Every zone will be Bumped except those excluded: ${exclude}"
for ZONE in $(ls | egrep -v "(.sh$|~|${exclude})") ; do
	if [ ${cont} -gt ${limitzones} ] ; then
		# [GIT WORK HERE] If number of zones is already bigger, means that we need to push to git
		if [ "${force}" = "true" ] || [ "${force}" = "yes" ] ; then
			CommitAndPush "${zonelist}"
		else
			echo; read -p "Continue to push zones into git? (y/N)" choice ; echo
			case ${choice:0:1} in
				y|Y )
					# [GIT WORK HERE] If number of zones is already bigger, means that we need to push to git
					CommitAndPush "${zonelist}"
					;;
				* )
					PrintMessage "# NOTICE: We didn't commit nor push the changes for ${zonelist} (although the files changed)"
					PrintMessage
					;;
			esac
		fi
		# Adding the remaining ${ZONE}
		BumpZone ${ZONE}
		zonelist="${ZONE}"
		cont=0
	else
		# SOA Serial++
		BumpZone ${ZONE}
		exitcode=$?
		if [ ${exitcode} -ne 0 ] ; then continue ; fi

		# Let's +1 the counters and list
		cont=$((cont+1))
		zonelist="${ZONE} ${zonelist}"
	fi
done

# Case when list is less than the actual ${limitzones}
if [ ${cont} -gt 0 ] ; then
	if [ "${force}" = "true" ] || [ "${force}" = "yes" ] ; then
		CommitAndPush "${zonelist}"
	else
		echo; read -p "Continue to push zones into git? (y/N)" choice ; echo
		case ${choice:0:1} in
			y|Y )
				CommitAndPush "${zonelist}"
				;;
			* )
				PrintMessage "# NOTICE: We didn't commit nor push the changes for ${zonelist} (although the files changed)"
				PrintMessage
				;;
		esac
	fi
fi

NEWNOW=$(date +%s)
if [ ${dryrun} != "false" ] ; then
	PrintMessage "####################################### END ########################################################"
	PrintMessage "#  $0 was executed as 'dryrun' (i.e.: No changes were pushed, but changes were made locally."
	PrintMessage "#  To recover previous version of ${zonesdir}, reset your git repo and get the latest changes: "
	PrintMessage "#      git reset --hard && git pull"
	PrintMessage "#  This process took $((NEWNOW - NOW)) seconds to run."
	PrintMessage "####################################################################################################"
else
	PrintMessage
	PrintMessage "####################################### END ########################################################"
	PrintMessage "# NOTICE: All zones in ${zonesdir} should have been incremented  "
	PrintMessage "#         This process took $((NEWNOW - NOW)) seconds to run."
	PrintMessage "#         (TIP: Do you need to do the same on RDNS?)"
	PrintMessage "####################################################################################################"
fi
