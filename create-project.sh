#!/usr/bin/env bash
# common ############################################################### START #
function error_msg() {
    local MSG="${1}"
    echo "${MSG}"
    exit 1
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

# common ################################################################# END #

#checks
check_root
check_sudo
check_ubuntu "all"

if [ ! -n "$1" ] 
then
    echo 'Missed argument : project name'
    exit 1
fi

if [ ! -n "$2" ]
then
    echo 'Missed argument : mysql root password'
    exit 1
fi

#username and database name same as project name
db_user=$1
db_name=$1

#generating reverse password for mysql user (for example: if user is 'vasya', then password will be 'aysav')
copy=${db_user}
len=${#copy}
for((i=$len-1;i>=0;i--)); do db_pass="$db_pass${copy:$i:1}"; done

#creating mysql database and user
mysql -uroot -p$2 << EOFMYSQL
CREATE DATABASE ${db_name} CHARACTER SET utf8 COLLATE utf8_general_ci;
GRANT ALL PRIVILEGES ON ${db_name}.* TO ${db_user}@localhost IDENTIFIED BY '${db_pass}';
EOFMYSQL

SCRIPT_DIR="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

#creating project cstructure
mkdir /home/djangoprojects/$1
cd /home/djangoprojects/$1
django-admin.py startproject src
mv src/src/* src/
mv src/manage.py ./
rm -rf src/src/
mkdir logs protected_media scripts tmp src/media src/templates
chmod 777 logs protected_media tmp
cd src

#creating project-specific settings
rm -r settings.py
cat ${SCRIPT_DIR}/settings.py.tpl | sed -e "s/<projectname>/$1/g" > settings.py
cat ${SCRIPT_DIR}/db_settings.py.tpl | sed -e "s/<db_user>/$db_user/g" | sed -e "s/<db_name>/$db_name/g" | sed -e "s/<db_pass>/$db_pass/g"  > db_settings.py
cd ..
cat ${SCRIPT_DIR}/runfastcgi.sh.tpl | sed -e "s/<projectname>/$1/g" > scripts/runfastcgi.sh
python manage.py syncdb

#adding new virual host to nginx
cat ${SCRIPT_DIR}/virtual.conf | sed -e "s/<projectname>/$1/g" > /etc/nginx/sites-available/$1
ln -s /etc/nginx/sites-available/$1 /etc/nginx/sites-enabled/$1