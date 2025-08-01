#!/bin/bash
yum update -y
yum install -y git python3 python3-pip nc
dnf install mariadb105 -y

while true; do
    echo "Rerieving DB host from Secrets manager"

    MYSQL_HOST=$(aws secretsmanager get-secret-value --secret-id rds/endpoint --region us-east-1 | jq -r '.SecretString' | jq -r '.endpoint')
    echo "Checking Aurora MySQL connectivity to $MYSQL_HOST:3306"
    nc -z -w10 "$MYSQL_HOST" 3306
    if [ $? -eq 0 ]; then
        echo "Aurora MySQL is reachable: $MYSQL_HOST"
        break
    else
        echo "Aurora MySQL is not reachable. Retrying in 30 seconds..."
        sleep 30
    fi
done 

git clone -b dev https://github.com/courtneydahlson/web-application-container.git
cd web-application-container/backend-application
pip3 install -r requirements.txt
python3 create_table.py