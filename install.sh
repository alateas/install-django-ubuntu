#!/usr/bin/env bash
# common ############################################################### START #
sp="/-\|"
log="${PWD}/`basename ${0}`.log"
echo $log

function error_msg() {
    local MSG="${1}"
    echo "${MSG}"
    exit 1
}

function cecho() {
    echo -e "$1"
    echo -e "$1" >>"$log"
    tput sgr0;
}

function ncecho() {
    echo -ne "$1"
    echo -ne "$1" >>"$log"
    tput sgr0
}

function spinny() {
    echo -ne "\b${sp:i++%${#sp}:1}"
}

function progress() {
    ncecho "  ";
    while [ /bin/true ]; do
        kill -0 $pid 2>/dev/null;
        if [[ $? = "0" ]]; then
            spinny
            sleep 0.25
        else
            ncecho "\b\b";
            wait $pid
            retcode=$?
            echo "$pid's retcode: $retcode" >> "$log"
            if [[ $retcode = "0" ]] || [[ $retcode = "255" ]]; then
                cecho success
            else
                cecho failed
                echo -e " [i] Showing the last 5 lines from the logfile ($log)...";
                tail -n5 "$log"
                exit 1;
            fi
            break 2;
        fi
    done
}

function progress_loop() {
    ncecho "  ";
    while [ /bin/true ]; do
        kill -0 $pid 2>/dev/null;
        if [[ $? = "0" ]]; then
            spinny
            sleep 0.25
        else
            ncecho "\b\b";
            wait $pid
            retcode=$?
            echo "$pid's retcode: $retcode" >> "$log"
            if [[ $retcode = "0" ]] || [[ $retcode = "255" ]]; then
                cecho success
            else
                cecho failed
                echo -e " [i] Showing the last 5 lines from the logfile ($log)...";
                tail -n5 "$log"
                exit 1;
            fi
            break 1;
        fi
    done
}

function progress_can_fail() {
    ncecho "  ";
    while [ /bin/true ]; do
        kill -0 $pid 2>/dev/null;
        if [[ $? = "0" ]]; then
            spinny
            sleep 0.25
        else
            ncecho "\b\b";
            wait $pid
            retcode=$?
            echo "$pid's retcode: $retcode" >> "$log"
            cecho success
            break 2;
        fi
    done
}

function check_root() {
    if [ "$(id -u)" != "0" ]; then
        error_msg "ERROR! You must execute the script as the 'root' user."
    fi
}

function check_sudo() {
    if [ ! -n ${SUDO_USER} ]; then
        error_msg "ERROR! You must invoke the script using 'sudo'."
    fi
}

function check_ubuntu() {
    if [ "${1}" != "" ]; then
        SUPPORTED_CODENAMES="${1}"
    else
        SUPPORTED_CODENAMES="all"
    fi

    # Source the lsb-release file.
    lsb

    # Check if this script is supported on this version of Ubuntu.
    if [ "${SUPPORTED_CODENAMES}" == "all" ]; then
        SUPPORTED=1
    else
        SUPPORTED=0
        for CHECK_CODENAME in `echo ${SUPPORTED_CODENAMES}`
        do
            if [ "${LSB_CODE}" == "${CHECK_CODENAME}" ]; then
                SUPPORTED=1
            fi
        done
    fi

    if [ ${SUPPORTED} -eq 0 ]; then
        error_msg "ERROR! ${0} is not supported on this version of Ubuntu."
    fi
}

function lsb() {
    local CMD_LSB_RELEASE=`which lsb_release`
    if [ "${CMD_LSB_RELEASE}" == "" ]; then
        error_msg "ERROR! 'lsb_release' was not found. I can't identify your distribution."
    fi
    LSB_ID=`lsb_release -i | cut -f2 | sed 's/ //g'`
    LSB_REL=`lsb_release -r | cut -f2 | sed 's/ //g'`
    LSB_CODE=`lsb_release -c | cut -f2 | sed 's/ //g'`
    LSB_DESC=`lsb_release -d | cut -f2`
    LSB_ARCH=`dpkg --print-architecture`
    LSB_MACH=`uname -m`
    LSB_NUM=`echo ${LSB_REL} | sed s'/\.//g'`
}

function apt_update() {
    ncecho " [x] Update package list "
    apt-get -y update >>"$log" 2>&1 &
    pid=$!;progress $pid
}
# common ################################################################# END #

#checks
check_root
check_sudo
check_ubuntu "all"

#nginx
ncecho " [x] Installing nginx"
apt-get -y install nginx  >> "$log" 2>&1 &
rm -f /etc/nginx/nginx.conf >> "$log" 2>&1 &
cp nginx.conf /etc/nginx/ >> "$log" 2>&1 &
#cp virtual.conf /etc/nginx/conf.d/django.conf
cp fastcgi.conf /etc/nginx/django_fastcgi.conf >> "$log" 2>&1 &
pid=$!;progress $pid

#python
ncecho " [x] Installing python modules"
yum -y install python-setuptools python-devel python-flup python-sqlite2 >> "$log" 2>&1 &
easy_install MySQL-python >> "$log" 2>&1 &
pid=$!;progress $pid

#mysql
ncecho " [x] Installing mysql"
apt-get -y install mysql-server >> "$log" 2>&1 &
pid=$!;progress $pid

#django
ncecho " [x] Copying and unpucking django distr"
cd /tmp >> "$log" 2>&1 &
wget --content-disposition http://www.djangoproject.com/download/1.4/tarball/ >> "$log" 2>&1 &
tar xzvf Django-1.4.tar.gz >> "$log" 2>&1 &
pid=$!;progress $pid

ncecho " [x] Installing Django"
cd Django-1.4 >> "$log" 2>&1 &
python setup.py install >> "$log" 2>&1 &
pid=$!;progress $pid


#setup
ncecho " [x] Adjust folder structure for django projects"
cd /home/user >> "$log" 2>&1 &
mkdir djangoprojects >> "$log" 2>&1 &
cd djangoprojects >> "$log" 2>&1 &
pid=$!;progress $pid