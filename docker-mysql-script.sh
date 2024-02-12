#!/bin/bash
sudo docker pull mysql:latest

# Set Variables

unset ContainerName
while [ -z ${ContainerName} ]; do
    read -p 'Enter container name: ' ContainerName
done

read -p 'Enter local port ([3306]): ' LocalPort
LocalPort=${LocalPort:-3306}

read -p 'Enter container port ([3306]): ' ContainerPort
ContainerPort=${ContainerPort:-3306}

read -p 'Enter bind host ([127.0.0.1]): ' BindHost
BindHost=${BindHost:-127.0.0.1}

unset RootUserPassword
while [ -z ${RootUserPassword} ]; do
    read -s -p 'Enter root password: ' RootUserPassword
done

echo

unset SetDatabaseOnInitialize
while [ -z ${SetDatabaseOnInitialize} ]; do
    read -p 'Do you want to create database and user credentials ([Y]/N): ' SetDatabaseOnInitialize
    SetDatabaseOnInitialize=${SetDatabaseOnInitialize:-Y}
done

if [[ "$SetDatabaseOnInitialize" = "Y" ]]; then
    unset DatabaseName
    while [ -z ${DatabaseName} ]; do
        read -p 'Enter database name: ' DatabaseName
    done

    unset DatabaseUser
    while [ -z ${DatabaseUser} ]; do
        read -p 'Enter database user: ' DatabaseUser
    done

    unset DatabasePassword
    while [ -z ${DatabasePassword} ]; do
        read -s -p 'Enter database password: ' DatabasePassword
    done

    echo
fi

unset PersistConfig
while [ -z ${PersistConfig} ]; do
    read -p 'Do you want to persist configuration to local storage - /etc/docker/'${ContainerName}'/my.cnf ([Y]/N): ' PersistConfig
    PersistConfig=${PersistConfig:-Y}
done

if [[ "$PersistConfig" = "Y" ]]; then
    sudo mkdir -p /etc/docker/${ContainerName}
    sudo touch /etc/docker/${ContainerName}/my.cnf

sudo tee -a /etc/docker/${ContainerName}/my.cnf <<EOF
innodb_buffer_pool_size         = 200M
query_cache_size                = 0
thread_pool_size                = 24
bind-address                    = ${BindHost}
#mysql_bind_host                 =
validate_password_policy        = MEDIUM
max_connections                 = 50
#innodb_file_per_table           =
innodb_io_capacity              = 100
character_set_server            = utf8mb4
collation_server                = utf8mb4_0900_ai_ci
log_bin                         = 1
EOF
fi

unset PersistData
while [ -z ${PersistData} ]; do
    read -p 'Do you want to persist data to local storage - ./'${ContainerName}'-data ([Y]/N): ' PersistData
    PersistData=${PersistData:-Y}
done

if [[ "$PersistData" = "Y" ]]; then
    sudo docker volume create ${ContainerName}-data
fi

sudo docker run \
--name "$ContainerName" \
-e MYSQL_ROOT_PASSWORD="$RootUserPassword" \
$([ "$SetDatabaseOnInitialize" == "Y" ] && echo "-e MYSQL_DATABASE=${DatabaseName} -e MYSQL_USER=${DatabaseUser} -e MYSQL_PASSWORD=${DatabasePassword} " || echo "") \
-p "$LocalPort":"$ContainerPort" \
$([ "$PersisConfig" == "Y" ] && echo "-v /etc/docker/${ContainerName}:/etc/mysql/conf.d" || echo "") \
$([ "$PersistData" == "Y" ] && echo "-v ${ContainerName}-data:/var/lib/mysql" || echo "") \
-d mysql
