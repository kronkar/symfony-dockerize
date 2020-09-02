if ! command -v symfony &> /dev/null
then
    wget https://get.symfony.com/cli/installer -O - | bash
    sudo mv ~/.symfony/bin/symfony /usr/local/bin/symfony
fi

path=$(basename $(pwd))
ddbb="symfony_"$path"_db"

mkdir docker docker/database docker/logs docker/nginx docker/php

cat <<EOF >./docker-compose.yml
version: '3.4'
services:
  nginx:
    build:
      context: .
      dockerfile: ./docker/nginx/Dockerfile
    volumes:
    - ./symfony/:/var/www/symfony/
    ports:
    - 8001:80
    networks:
      - symfony
    depends_on:
      - php
  php:
    user: \$UID:\$GID
    build:
      context: .
      dockerfile: ./docker/php/Dockerfile
    environment:
      APP_ENV: dev
    volumes:
    - ./symfony/:/var/www/symfony
    - /etc/group:/etc/group:ro
    - /etc/passwd:/etc/passwd:ro
    - /etc/shadow:/etc/shadow:ro
    networks:
      - symfony
    depends_on:
      - mysql
  mysql:
    image: mysql:5.7
    user: \$UID:\$GID
    command: ['--character-set-server=utf8mb4', '--collation-server=utf8mb4_unicode_ci', '--default-authentication-plugin=mysql_native_password']
    environment:
      MYSQL_DATABASE: $ddbb
      MYSQL_USER: user
      MYSQL_PASSWORD: password
      MYSQL_ROOT_PASSWORD: root
    ports:
    - 3306:3306
    volumes:
      - ./docker/database:/var/lib/mysql
    networks:
      - symfony
networks:
  symfony:
EOF

cat <<EOF > ./docker/nginx/default.conf
server {
    listen 80;
    server_name localhost;
    root /var/www/symfony/public;

    location / {
        try_files \$uri /index.php\$is_args\$args;
    }

    location ~ ^/index\.php(/|$) {
        # Conect to the Docker service using FPM
        fastcgi_pass php:9000;
        fastcgi_split_path_info ^(.+\.php)(/.*)$;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        fastcgi_param DOCUMENT_ROOT \$realpath_root;
        internal;
    }

    # return 404 for all other php files not matching the front controller
    # this prevents access to other php files you don't want to be accessible.
    location ~ \.php$ {
        return 404;
    }

    error_log /var/log/nginx/error.log;
    access_log /var/log/nginx/project_access.log;
}
EOF

cat <<EOF > ./start.sh
# shellcheck disable=SC2155
export UID=$(id -u)
export GID=$(id -g)
docker-compose up -d
EOF

chmod 755 ./start.sh

cat <<EOF > ./docker/nginx/Dockerfile
FROM nginx:latest
COPY ./docker/nginx/default.conf /etc/nginx/conf.d/
EOF

cat <<EOF > ./docker/php/Dockerfile
FROM php:7.4-fpm

RUN apt update && apt install -y

RUN apt update && apt install -y --no-install-recommends \\
        git \\
        zlib1g-dev \\
        libxml2-dev \\
        libzip-dev \\
    && docker-php-ext-install \\
        zip \\
        intl \\
        mysqli \\
        pdo pdo_mysql

RUN curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer
COPY ./symfony /var/www/symfony
WORKDIR /var/www/symfony
EOF

symfony new symfony --full
sed -i 's/db_user:db_password@127.0.0.1:3306\/db_name/user:password@mysql:3306\/'$ddbb'/g' ./symfony/.env
