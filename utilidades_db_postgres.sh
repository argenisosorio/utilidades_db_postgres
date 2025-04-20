#!/bin/sh
#
# Autor: Ing. Argenis Osorio
#
# Fecha de creación: 13/08/23
#
# Última actualización: 19/04/25
#
# Descripción: Este script permite administrar bases de datos y usuarios de
# PostgreSQL de forma rápida y sencilla, ofreciendo las siguientes
# funcionalidades:
#
# -Creación de usuarios y bases de datos.
# -Eliminación de bases de datos.
# -Respaldo (backup) y restauración de bases de datos.
# -Listado de todas las bases de datos con sus respectivos propietarios.
# -Copia de una base de datos existente.
#
# Para ejecutar el script, use el siguiente comando:
#
# bash utilidades_db_postgres.sh
#
# utilidades_db_postgres.sh es software libre: Puedes redistribuirlo y/o
# modificar bajo los términos de la Licencia Pública General GNU publicada por
# la Free Software Foundation, ya sea la versión 3 de la Licencia, o (a su
# elección) cualquier versión posterior.
#
# utilidades_db_postgres.sh se distribuye con la esperanza de que sea útil, pero
# SIN NINGUNA GARANTIA; sin siquiera la garantía implícita de COMERCIABILIDAD o
# IDONEIDAD PARA UN FIN DETERMINADO. Ver el Licencia Pública General GNU para
# más detalles.

while true; do
    echo
    echo "--------------------------------------------------"
    echo "Operaciones con bases de datos de Postgresql by dM"
    echo "--------------------------------------------------"
    echo
    echo "1 = Crear un nuevo usuario en PostgreSQL"
    echo "2 = Borrar una base de datos de PostgreSQL"
    echo "3 = Crear una nueva base de datos de PostgreSQL"
    echo "4 = Respaldar una base de datos de PostgreSQL en un archivo .sql"
    echo "5 = Restaurar una base de datos de PostgreSQL desde un archivo .sql"
    echo "6 = Listar todas las bases de datos de PostgreSQL y sus dueños"
    echo "7 = Crear una copia de una base de datos existente"
    echo "8 = Salir"
    echo 
    read -p "Introduzca su opción y presione enter: " var

    case $var in
        1)
            echo
            read -p "Ingrese el nombre del nuevo usuario que desea crear: " nuevo_usuario
            echo
            read -s -p "Ingrese la contraseña para el nuevo usuario: " contrasena_usuario
            echo
            echo "Creando el usuario '$nuevo_usuario'..."
            sudo -u postgres psql -c "CREATE USER $nuevo_usuario WITH PASSWORD '$contrasena_usuario';"
            echo
            echo "┌───────────────────────────────────────────────────"
            echo "│  ✔ Usuario '$nuevo_usuario' creado exitosamente  "
            echo "└──────────────────────────────────────────────────"
            ;;
        2)
            echo
            read -p "Ingrese el nombre de la base de datos que desea borrar y presione enter: " database_name
            echo
            read -p "¿Está seguro de que desea borrar la base de datos '$database_name'? ingrese (S/N) y presione enter: " confirmation
            if [ "$confirmation" == "S" ] || [ "$confirmation" == "s" ]; then
                # Verificar si la base de datos existe antes de borrarla
                sudo -u postgres psql -t -c "SELECT 1 FROM pg_database WHERE datname='$database_name'" | grep -q 1
                if [ $? -eq 0 ]; then
                    echo
                    echo "Ingrese su contraseña de usuario sudo (Si ya lo ha hecho antes, no será necesario):"
                    sudo -u postgres psql -c "DROP DATABASE $database_name"
                    echo
                    echo "┌──────────────────────────────────────────────"
                    echo "│  ✔ Base de datos '$database_name' eliminada  "
                    echo "└──────────────────────────────────────────────"
                else
                    echo
                    echo "La base de datos '$database_name' no existe."
                fi
            else
                echo "Operación cancelada. No se ha borrado la base de datos."
            fi
            ;;
        3)
            echo
            read -p "Ingrese el nombre de la nueva base de datos que desea crear: " new_database_name
            echo
            read -p "Ingrese el nombre del propietario de la nueva base de datos que desea crear: " owner_name
            echo
            sudo -u postgres psql -c "CREATE DATABASE $new_database_name OWNER $owner_name"
            echo
            echo "┌───────────────────────────────────────────────"
            echo "│  ✔ Base de datos '$new_database_name' creada  "
            echo "└───────────────────────────────────────────────"
            ;;
        4)
            echo
            # Solicitar el nombre de la base de datos
            read -p "Ingrese el nombre de la base de datos que desea respaldar: " nombre_bd
            echo
            # Solicitar el nombre del dueño de la base de datos
            read -p "Ingrese el nombre del propietario de la base de datos que desea respaldar: " nombre_dueno
            echo
            # Solicitar la contraseña del dueño de la base de datos
            read -s -p "Ingrese la contraseña del propietario de la base de datos que desea respaldar: " contrasena
            echo
            echo
            # Solicitar el nombre del archivo de respaldo
            read -p "Ingrese el nombre del archivo .sql que será creado y presione enter (No escriba .sql al final, solo el nombre): " nombre_respaldo
            # Agregar la extensión .sql al nombre del archivo de respaldo
            nombre_respaldo="$nombre_respaldo.sql"
            # Establecer la contraseña del dueño de la base de datos
            export PGPASSWORD="$contrasena"
            # Ejecutar el comando pg_dump para realizar el respaldo
            #pg_dump -U "$nombre_dueno" -h 127.0.0.1 --no-owner "$nombre_bd" > "$nombre_respaldo"
            pg_dump -U "$nombre_dueno" -h 127.0.0.1 --no-owner --no-acl "$nombre_bd" > "$nombre_respaldo"
            # Limpiar la variable de entorno PGPASSWORD
            unset PGPASSWORD
            echo
            # Indicar al usuario que se realizó el respaldo con éxito
            echo "╭────────────────────────────────────────────────────────────"
            echo "│  ✔ Respaldo completado:                                    "
            echo "│     Base de datos: $nombre_bd                              "
            echo "│     Archivo generado: $nombre_respaldo                     "
            echo "╰────────────────────────────────────────────────────────────"
            ;;
        5)
            echo
            # Solicitar el nombre de la base de datos
            read -p "Ingrese el nombre de la base de datos que desea restaurar y presione enter (Debe estar creada en Postgresql y además estar vacía): " nombre_bd
            echo
            # Solicitar el nombre del dueño de la base de datos
            read -p "Ingrese el nombre del propietario de la base de datos que desea restaurar y presione enter: " nombre_dueno
            echo
            # Solicitar la contraseña del dueño de la base de datos
            read -s -p "Ingrese la contraseña del propietario de la base de datos que desea restaurar y presione enter: " contrasena
            echo
            echo
            # Solicitar el nombre del archivo de respaldo
            read -p "Ingrese el nombre del archivo .sql que es el respaldo que desea restaurar y presione enter (No escriba .sql al final, solo el nombre): " nombre_respaldo
            # Agregar la extensión .sql al nombre del archivo de respaldo
            nombre_respaldo="$nombre_respaldo.sql"
            # Establecer la contraseña del dueño de la base de datos
            export PGPASSWORD="$contrasena"
            # Ejecutar el comando psql para restaurar el respaldo
            psql -h 127.0.0.1 -U "$nombre_dueno" -d "$nombre_bd" -f "$nombre_respaldo"
            set -x
            set +x
            # Limpiar la variable de entorno PGPASSWORD
            unset PGPASSWORD
            echo
            # Indicar al usuario que se realizó el respaldo con éxito
            echo "╭────────────────────────────────────────────────────────────"
            echo "│  ✔ Restauración completada:                               "
            echo "│     Base de datos: $nombre_bd                             "
            echo "│     Archivo utilizado: $nombre_respaldo                   "
            echo "╰───────────────────────────────────────────────────────────"
            ;;
        6)
            # Nueva opción para listar bases de datos y sus dueños
            echo
            echo "Listando todas las bases de datos y sus propietarios:"
            echo "----------------------------------------------------"
            sudo -u postgres psql -c "SELECT d.datname as \"Base de Datos\", pg_catalog.pg_get_userbyid(d.datdba) as \"Dueño\" FROM pg_catalog.pg_database d ORDER BY 1;"
            echo "----------------------------------------------------"
            ;;
        7)
            echo
            read -p "Ingrese el nombre de la base de datos que desea copiar: " original_db
            echo
            read -p "Ingrese el nombre de la nueva base de datos (copia): " new_db
            echo
            read -p "Ingrese el nombre del propietario de la nueva base de datos: " owner_name
            echo
            echo "Creando una copia de la base de datos '$original_db' con el nombre '$new_db'..."
            sudo -u postgres psql -c "CREATE DATABASE $new_db WITH TEMPLATE $original_db OWNER $owner_name;"
            echo
            echo "┌────────────────────────────────────────────────────────────"
            echo "│  ✔ Copia creada exitosamente:                              "
            echo "│     Base de datos original: $original_db                   "
            echo "│     Nueva base de datos: $new_db                           "
            echo "└────────────────────────────────────────────────────────────"
            ;;
        8)
            # Opción para Salir del script
            echo
            echo "┌──────────────────────────────────────"
            echo "│  ¡Gracias por usar el script!        "
            echo "│  Hasta pronto...                     "
            echo "└──────────────────────────────────────"
            echo
            exit 0
            ;;
        *)
            echo "¡Opción inválida!"
            ;;
    esac
done