#!/bin/bash

# Leandro Sehnem Heck (leoheck@gmail.com)

# MAIN SCRIPT TO CONFIGURE INSTALL GAPH CONFIGS

# GITHUB REPOSITORY CONFIG
REPO="gaph-host-config"
BRANCH="ubuntu-16.04"

GITHUB="https://github.com/leoheck/$REPO/archive/"
PKG=$BRANCH.zip

PROJECTDIR=/tmp/$REPO-$BRANCH

export PATH=./scripts:$PATH
export PATH=$PROJECTDIR/scripts:$PATH

# Ctrl+c function to halt execution
control_c()
{
	echo -e "\n\n$0 ended by user\n"
	exit $?
}

trap control_c SIGINT

# Use colors only if connected to a terminal which supports them
if which tput >/dev/null 2>&1; then
	ncolors=$(tput colors)
fi

if [ -t 1 ] && [ -n "$ncolors" ] && [ "$ncolors" -ge 8 ]; then
	RED="$(tput setaf 1)"
	GREEN="$(tput setaf 2)"
	YELLOW="$(tput setaf 3)"
	BLUE="$(tput setaf 4)"
	BOLD="$(tput bold)"
	NORMAL="$(tput sgr0)"
else
	RED=""
	GREEN=""
	YELLOW=""
	BLUE=""
	BOLD=""
	NORMAL=""
fi

# Only enable exit-on-error after the non-critical colorization stuff,
# which may fail on systems lacking tput or terminfo
set -e

# Prevent the cloned repository from having insecure permissions. Failing to do
# so causes compinit() calls to fail with "command not found: compdef" errors
# for users with insecure umasks (e.g., "002", allowing group writability). Note
# that this will be ignored under Cygwin by default, as Windows ACLs take
# precedence over umasks except for filesystems mounted with option "noacl".
umask g-w,o-w

# Check for super power
if [ "$(id -u)" != "0" ]; then
	echo -e "\n${YELLOW}Hey kid, you need superior powers, Go call your father.${NORMAL}\n"
	exit 1
fi

main()
{
	if [ -f $PKG ]; then
		printf "%s  Removing previows /tmp/$PKG ...%s\n" "${BLUE}" "${NORMAL}"
		rm -rf $PKG
	fi

	printf "%s  Donwloading an updated $PKG from github in /tmp ...%s\n" "${BLUE}" "${NORMAL}"
	wget $GITHUB/$PKG -O /tmp/$PKG 2> /dev/null

	if [ -d $PROJECTDIR ]; then
		printf "%s  Removing $PROJECTDIR ...%s\n" "${BLUE}" "${NORMAL}"
		rm -rf $PROJECTDIR
	fi

	printf "%s  Unpacking /tmp/$PKG into $PROJECTDIR ...%s\n" "${BLUE}" "${NORMAL}"
	unzip -qq /tmp/$PKG -d /tmp > /dev/null

	echo "${GREEN}"
	echo "   _____  _____  _____  _____           _____  _____  _____  _____   "
	echo "  |   __||  _  ||  _  ||  |  |   ___   |  |  ||     ||   __||_   _|  "
	echo "  |  |  ||     ||   __||     |  |___|  |     ||  |  ||__   |  | |    "
	echo "  |_____||__|__||__|   |__|__|         |__|__||_____||_____|  |_|    "
	echo "                                                                     "
	echo "  CONFIGURATION SCRIPT (MADE FOR UBUNTU 16.04)${NORMAL}"
	echo
	echo "  [1] ${BOLD}TURN MACHINE INTO A GAPH HOST${NORMAL}"
	echo "  [2] Turn machine into a GAPH-COMPATIBLE host (install programs only)"
	echo "  [3] Apply/upgrade configurations only"
	echo "  [4] Remove configurations (revert configuration files only)"
	echo
	echo "${BLUE}  Hit CTRL+C to exit${NORMAL}"
	echo

	while :;
	do
	  read -p '  #> ' choice
	  case $choice in
		1 ) break ;;
		2 ) break ;;
		3 ) break ;;
		4 ) break ;;
		* )
			tput cuu1
			tput el1
			tput el
			;;
	  esac
	done
}

install_base_software()
{
	echo "  - Instaling base apps"
	# Recover from a possible bronken installation
	# dpkg-reconfigure --all
	if [ ! -f /etc/gaph/gaph.conf ]; then
		if [ ! "$DISPLAY" = "" ]; then
			xterm -e bash -c "initial-software.sh | tee configure.log"
		else
			bash -c "initial-software.sh | tee configure.log"
		fi
	fi
	echo "    - See installation logs at configure.log"
}

install_extra_software()
{
	echo "  - Instaling extra apps, this can take hours, go take a coffe :) ... "
	# Recover from a possible bronken installation
	# dpkg-reconfigure --all
	if [ ! "$DISPLAY" = "" ]; then
		xterm -e bash -c "extra-software.sh | tee -a configure.log"
	else
		bash -c "extra-software.sh | tee -a configure.log"
	fi
	echo "    - See installation logs at configure.log"
}

apply_and_upgrade_configs()
{
	echo
	echo "${YELLOW}  Appling/updating configurations ...${NORMAL}"
	install_base_software
	install-scripts.sh -i $PROJECTDIR
	crontab-config.sh -i
	admin-config.sh -i
	config-printers.sh -i
	fstab-config.sh -i
	hosts-config.sh -i
	lightdm-config.sh -i
	nslcd-config.sh -i
	nsswitch-config.sh -i
	saltstack-config.sh -i
	misc-hacks.sh
	users-config.sh
	echo "GAPH host installed on: $(date +%Y-%m-%d-%H-%M-%S)" > /etc/gaph/gaph.conf
}

revert_configurations()
{
	echo
	echo "${YELLOW}  Removing configurations ...${NORMAL}"
	install-scripts.sh -r
	crontab-config.sh -r
	admin-config.sh -r
	config-printers.sh -r
	fstab-config.sh -r
	hosts-config.sh -r
	lightdm-config.sh -r
	nslcd-config.sh -r
	nsswitch-config.sh -r
	saltstack-config.sh -r
	# misc-hacks.sh
	# users-config.sh
	customization.sh -r
	rm -f /etc/gaph/gaph.conf
}

configure_gaph_host()
{
	echo
	echo "${YELLOW}  Configuring GAPH host ...${NORMAL}"
	install_base_software
	apply_and_upgrade_configs
	install_extra_software
	misc-hacks.sh
	customization.sh -i $PROJECTDIR
	echo "${RED}  The system is going to reboot in 3 minutes! ${NORMAL}"
	shutdown -r +3 > /dev/null
}

configure_gaph_compatible()
{
	echo
	echo "${YELLOW}  Configuring GAPH COMPATIBLE host ...${NORMAL}"
	install_base_software
	install_extra_software
	misc-hacks.sh
	echo
	echo "${RED}  == SYSTEM WILL REBOOT in 5 MINUTES! ${NORMAL}"
	echo
	shutdown -r +5 > /dev/null
}

clear
echo
main

case $choice in
	1 ) configure_gaph_host ;;
	2 ) configure_gaph_compatible ;;
	3 ) apply_and_upgrade_configs ;;
	4 ) revert_configurations ;;
esac

echo "${YELLOW}  DONE!${NORMAL}"
echo
