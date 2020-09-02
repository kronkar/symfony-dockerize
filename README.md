# symfony-dockerize
#### Automatización para la creación de un proyecto Symfony + Docker (php-fpm, nginx mysql:5.7)

El script crea un directorio para el proyecto y luego genera un arbol con todo lo necesario para comenzar un proyecto de symfony con Docker

* Arbol de directorios:
* |--docker (configuración para docker)
* |----logs (archivos de logs de nginx)
* |----database (archivos de persistencia de las BBDD)
* |----nginx (configuración de nginx)
* |------*default.conf* (configuración de domnio nginx)
* |------*Dockerfile* (configuración de Docker nginx)
* |----php (configuración de php)
* |------*Dockerfile* (configuración de Docker php)
* |--symfony (archivos symfony)
* |--*start.sh* (archivo para el inicio de los docker)
* |--*docker-compose.yml* (configuración de los contenedores)

**Importante!!** este script configura el uso de tu usuario en los contenedores, por lo que el comando start.sh contiene la configuración de unas variables que son necesarias para su uso
en el caso de que inicies a traves de los comandos de composer, antes debes exportar las siguientes variables de entorno:  
export UID=$(id -u)  
export GID=$(id -g)