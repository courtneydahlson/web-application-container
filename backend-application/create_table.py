import mysql.connector
import boto3
import json
import config
import time
from botocore.exceptions import ClientError
from mysql.connector import errorcode

def get_secret(secret_name, region_name):
    client = boto3.client('secretsmanager', region_name=region_name)

    try: 
        response = client.get_secret_value(SecretId=secret_name)

    except ClientError as e:
        raise Exception(f"Failed to retrieve secret: {e}")
    
    if 'SecretString' in response:
        secret = response['SecretString']
        return json.loads(secret)
    else:
        raise Exception("Cannot find secret")


def get_db_connection():
    credentials = get_secret(config.secret_name, config.region_name)
    mysql_user = credentials['username']
    mysql_password = credentials['password']
    endpoint_credentials = get_secret(config.endpoint_secret, config.region_name)
    mysql_host = endpoint_credentials['endpoint']
    return mysql.connector.connect(
        host=mysql_host,
        user=mysql_user,
        password=mysql_password,
        database=config.MYSQL_DB
    )

def create_table():
    MAX_RETRIES = 5
    BASE_BACKOFF = 15
    for attempt in range(1, MAX_RETRIES + 1):
        try:
            connection = get_db_connection()
            cursor = connection.cursor()
            create_table_query = """
            CREATE TABLE IF NOT EXISTS orders (
                id INT AUTO_INCREMENT PRIMARY KEY,
                customer_id VARCHAR(50) NOT NULL,
                product_id VARCHAR(50) NOT NULL,
                quantity INT NOT NULL,
                order_date VARCHAR(50),
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
            """
            cursor.execute(create_table_query)
            connection.commit()
            cursor.close()
            connection.close()
            print("Table created successfully")
            break
        except mysql.connector.Error as err:
            if err.errno == errorcode.ER_ACCESS_DENIED_ERROR:
                print("Access Denied. Check your username and password")
            elif err.errno == errorcode.ER_BAD_DB_ERROR:
                print("Database does not exist")
            else:
                print(f"Error: {err}")
        except Exception as e:
            print(f"Error creating table: {e}")
        
        if attempt < MAX_RETRIES:
            sleep_time = BASE_BACKOFF * (2 ** (attempt - 1))
            print(f"Retrying in {sleep_time} seconds...")
            time.sleep(sleep_time)
        else:
            print("Max retries reached. Failed to create table.")


if __name__ == "__main__":
    create_table()

