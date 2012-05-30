if [ ! -n "$1" ] 
then
    echo 'Missed argument : MySQL password'
    exit 1
fi
    
#mysql


#nginx
apt-get -y install nginx
rm -f /etc/nginx/nginx.conf
cp nginx.conf /etc/nginx/
cp virtual.conf /etc/nginx/conf.d/django.conf
cp fastcgi.conf /etc/nginx/django_fastcgi.conf

#python
yum -y install python-setuptools python-devel python-flup python-sqlite2
easy_install MySQL-python

#django
cd /tmp
wget http://www.djangoproject.com/download/1.4/tarball/
tar xzvf Django-1.4.tar.gz
cd Django-1.4
python setup.py install

#mysql
mysql -u root --password=$1 -e "create database astertools";

#setup
cd /home/user
mkdir projects
cd projects
#cat /home/astertools/scripts/install/db_settings.py | sed -e "s/<password>/$1/" > db_settings.py
python manage.py syncdb --noinput
python manage.py createsuperuser --username admin --email dmitrymashkin@gmail.com --noinput
python manage.py changepassword admin

#permissions
#cd /home/user/projetcts

#chmod -R 777 tmp logs protected_media

#adding to startup
#update-rc.d ssh defaults
#echo -e "sh /home/astertools/scripts/runfcgi.sh" >> /etc/rc.d/rc.local

#start
#sh /home/astertools/scripts/nginx_run.sh

