if [ ! -n "$1" ] 
then
    echo 'Missed argument : project name'
    exit 1
fi

cd /home/djangoprojects
django-admin.py startproject $1
cd $1
python manage.py syncdb