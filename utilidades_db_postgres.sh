#!/bin/sh
#
# Autor: Ing. Argenis Osorio
#
# Fecha de creación: 13/08/23
#
# Última actualización: 25/07/25
#
# Descripción: Script de bash que permite crear usuarios y BD, borrar BD,
# restaurar y respaldar BD, listar todas las BD y sus dueños, y crear una copia
# de una base de datos existente y cambiar dueños de las bases de datos de
# manera rápida y sencilla.
#
# Para ejecutar el script, use el siguiente comando:
#
# bash utilidades_db_postgres.sh

# Verificar si la sesión de sudo está activa
clear
if sudo -n true 2>/dev/null; then
    echo "Sesión de sudo activa."
else
    # Solicitar la contraseña de sudo si no está activa
    echo
    echo "Por favor, introduzca su contraseña de sudo para continuar:"
    echo
    sudo -v
fi

# Mantener la sesión de sudo activa mientras el script se ejecuta
while true; do sudo -v; sleep 60; done &

while true; do
    echo
    echo "===================================================="
    echo "Utilidades para gestión de bases de datos PostgreSQL"
    echo "===================================================="
    echo
    echo "1) Crear un nuevo usuario en PostgreSQL"
    echo "2) Cambiar el dueño de una base de datos de PostgreSQL"
    echo "3) Eliminar una base de datos de PostgreSQL"
    echo "4) Crear una nueva base de datos en PostgreSQL"
    echo "5) Respaldar una base de datos a un archivo .sql"
    echo "6) Restaurar una base de datos desde un archivo .sql"
    echo "7) Listar todas las bases de datos y sus propietarios"
    echo "8) Clonar o Crear una copia de una base de datos existente (La copia se creará dentro de PostgreSQL)"
    echo "9) Salir"
    echo 
    read -p "Introduzca su opción y presione enter: " var

    case $var in
        1)
            clear
            echo
            echo "1) Crear un nuevo usuario en PostgreSQL"
            echo
            echo "Presione Ctrl + c si desea salir del script"
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
            clear
            echo "2) Cambiar el dueño de una base de datos"
            echo
            echo "Presione Ctrl + c si desea salir del script"
            echo
            read -p "Ingrese el nombre de la base de datos a la que desea cambiar el dueño: " db_name
            echo
            read -p "Ingrese el nombre del nuevo dueño: " new_owner
            echo
            echo "Cambiando el dueño de la base de datos '$db_name' a '$new_owner'..."
            sudo -u postgres psql -c "ALTER DATABASE $db_name OWNER TO $new_owner;"
            echo
            echo "┌────────────────────────────────────────────────────────────"
            echo "│  ✔ Dueño de la base de datos '$db_name' cambiado a '$new_owner'"
            echo "└────────────────────────────────────────────────────────────"
            ;;
        3)
            clear
            echo "3) Eliminar una base de datos de PostgreSQL"
            echo
            echo "Presione Ctrl + c si desea salir del script"
            echo
            read -p "Ingrese el nombre de la base de datos que desea eliminar y presione enter: " database_name
            echo
            read -p "¿Está seguro de que desea eliminar la base de datos '$database_name'? ingrese (S/N) y presione enter: " confirmation
            echo
            if [ "$confirmation" = "S" ] || [ "$confirmation" = "s" ]; then
                # Verificar si la base de datos existe antes de borrarla
                sudo -u postgres psql -t -c "SELECT 1 FROM pg_database WHERE datname='$database_name'" | grep -q 1
                if [ $? -eq 0 ]; then
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
                echo "Operación cancelada. No se ha eliminado la base de datos."
            fi
            ;;
        4)
            clear
            echo "4) Crear una nueva base de datos en PostgreSQL"
            echo
            echo "Presione Ctrl + c si desea salir del script"
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
        5)
            clear
            echo "5) Respaldar una base de datos a un archivo .sql"
            echo
            echo "Presione Ctrl + c si desea salir del script"
            echo
            read -p "Ingrese el nombre de la base de datos que desea respaldar: " nombre_bd
            echo
            read -p "Ingrese el nombre del propietario de la base de datos que desea respaldar: " nombre_dueno
            echo
            read -s -p "Ingrese la contraseña del propietario de la base de datos que desea respaldar: " contrasena
            echo
            read -p "Ingrese el nombre del archivo de respaldo .sql que será creado y presione enter (No escriba .sql al final, solo el nombre): " nombre_respaldo
            echo
            nombre_respaldo="$nombre_respaldo.sql"
            export PGPASSWORD="$contrasena"
            pg_dump -U "$nombre_dueno" -h 127.0.0.1 --no-owner --no-acl "$nombre_bd" > "$nombre_respaldo"
            unset PGPASSWORD
            echo
            echo "╭────────────────────────────────────────────────────────────"
            echo "│  ✔ Respaldo completado:                                    "
            echo "│     Base de datos: $nombre_bd                              "
            echo "│     Archivo generado: $nombre_respaldo                     "
            echo "╰────────────────────────────────────────────────────────────"
            ;;
        6)
            clear
            echo "6) Restaurar una base de datos desde un archivo .sql"
            echo
            echo "Presione Ctrl + c si desea salir del script"
            echo
            read -p "Ingrese el nombre de la base de datos que desea restaurar y presione enter (Debe estar creada en Postgresql y además estar vacía): " nombre_bd
            echo
            read -p "Ingrese el nombre del propietario de la base de datos que desea restaurar y presione enter: " nombre_dueno
            echo
            read -s -p "Ingrese la contraseña del propietario de la base de datos que desea restaurar y presione enter: " contrasena
            echo
            echo
            read -p "Ingrese el nombre del archivo .sql que es el respaldo que desea restaurar y presione enter (No escriba .sql al final, solo el nombre): " nombre_respaldo
            echo
            nombre_respaldo="$nombre_respaldo.sql"
            export PGPASSWORD="$contrasena"
            psql -h 127.0.0.1 -U "$nombre_dueno" -d "$nombre_bd" -f "$nombre_respaldo"
            unset PGPASSWORD
            echo
            echo "╭────────────────────────────────────────────────────────────"
            echo "│  ✔ Restauración completada:                               "
            echo "│     Base de datos: $nombre_bd                             "
            echo "│     Archivo utilizado: $nombre_respaldo                   "
            echo "╰───────────────────────────────────────────────────────────"
            ;;
        7)
            clear
            echo "7) Listar todas las bases de datos y sus propietarios"
            echo
            sudo -u postgres psql -c "SELECT d.datname as \"Base de Datos\", pg_catalog.pg_get_userbyid(d.datdba) as \"Dueño\" FROM pg_catalog.pg_database d ORDER BY 1;"
            ;;
        8)
            clear
            echo "8) Clonar o Crear una copia de una base de datos existente (La copia se creará dentro de PostgreSQL)"
            echo
            echo "Presione Ctrl + c si desea salir del script"
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
        9)
            clear
            echo
            echo "┌──────────────────────────────────────"
            echo "│  ¡Gracias por usar el script!        "
            echo "│  Hasta pronto...                     "
            echo "└──────────────────────────────────────"
            echo
            exit 0
            ;;
        *)
            echo
            echo "┌─────────────────────────────────────────────────────────────"
            echo "│¡Opción inválida! Por favor, seleccione una opción del 1 al 9."
            echo "└─────────────────────────────────────────────────────────────"
            ;;
    esac
done
