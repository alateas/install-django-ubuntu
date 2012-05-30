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
wget http://www.djangoproject.com/download/1.4/tarball/
tar xzvf Django-1.4.tar.gz
cd Django-1.4
python setup.py install

#setup
cd /home/user
mkdir djangoprojects
cd djangoprojects