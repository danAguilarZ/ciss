# CISS - COVID-19
Proyecto para actualizar HTML y base MySQL con la información actualizada de la OMS acerca de la pandemia COVID-19

Se debe instalar un ambiente virtual de python con:

python -m venv venv

E instalar como biblioteca el proyecto:

pip install git+https://github.com/danAguilarZ/ciss.git@master

## Pasos a seguir

* Configurar en una carpeta el shell
* Crear y configurar el archivo config.yml con la configuración de bd
* Instalar pdftotext de la página oficial - https://www.xpdfreader.com/pdftotext-man.html

### En caso de MAC

Instalar readlink:

* brew install coreutils
* sudo ln -s /usr/local/bin/greadlink /usr/local/bin/readlink

## Ejecutar

sh execute_covid_update.sh <ruta de ambiente virtual> <ruta html a actualizar> <tiempo para volver a descargar archivo>