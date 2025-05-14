#!/bin/sh
#
# Autor: Ing. Argenis Osorio
#
# Fecha de creación: 13/08/23
#
# Última actualización: 14/05/25
#
# Descripción: Script de bash que permite crear usuarios y BD, borrar BD,
# restaurar y respaldar BD, listar todas las BD y sus dueños, y crear una copia
# de una base de datos existente de manera rápida y sencilla.
#
# Para ejecutar el script, use el siguiente comando:
#
# bash utilidades_db_postgres.sh

# Verificar si la sesión de sudo está activa
if sudo -n true 2>/dev/null; then
    echo
    echo "Sesión de sudo activa. Continuando..."
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
            read -p "Ingrese el nombre de la base de datos que desea respaldar: " nombre_bd
            echo
            read -p "Ingrese el nombre del propietario de la base de datos que desea respaldar: " nombre_dueno
            echo
            read -s -p "Ingrese la contraseña del propietario de la base de datos que desea respaldar: " contrasena
            echo
            read -p "Ingrese el nombre del archivo .sql que será creado y presione enter (No escriba .sql al final, solo el nombre): " nombre_respaldo
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
        5)
            echo
            read -p "Ingrese el nombre de la base de datos que desea restaurar y presione enter (Debe estar creada en Postgresql y además estar vacía): " nombre_bd
            echo
            read -p "Ingrese el nombre del propietario de la base de datos que desea restaurar y presione enter: " nombre_dueno
            echo
            read -s -p "Ingrese la contraseña del propietario de la base de datos que desea restaurar y presione enter: " contrasena
            echo
            read -p "Ingrese el nombre del archivo .sql que es el respaldo que desea restaurar y presione enter (No escriba .sql al final, solo el nombre): " nombre_respaldo
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
        6)
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
