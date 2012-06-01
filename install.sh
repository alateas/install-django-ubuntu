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

#checks
check_root
check_sudo
check_ubuntu "all"

#nginx
apt-get -y install nginx
rm -f /etc/nginx/nginx.conf
cp nginx.conf /etc/nginx/
#cp virtual.conf /etc/nginx/conf.d/django.conf
cp fastcgi.conf /etc/nginx/django_fastcgi.conf

#python
yum -y install python-setuptools python-devel python-flup python-sqlite2
easy_install MySQL-python

#mysql
apt-get -y install mysql-server

#django
cd /tmp
wget --content-disposition http://www.djangoproject.com/download/1.4/tarball/
tar xzvf Django-1.4.tar.gz
cd Django-1.4
python setup.py install

#setup
cd /home/user
mkdir djangoprojects
cd djangoprojects