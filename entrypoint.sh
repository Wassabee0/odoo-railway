#!/bin/bash
set -e

# Variables de Railway PostgreSQL
DB_HOST=${PGHOST:-postgresql.railway.internal}
DB_PORT=${PGPORT:-5432}
DB_SUPERUSER=${PGUSER:-postgres}
DB_SUPERPASS=${PGPASSWORD:-postgres}

# Usuario dedicado para Odoo
ODOO_DB_USER=${ODOO_DB_USER:-odoo}
ODOO_DB_PASSWORD=${ODOO_DB_PASSWORD:-odoo_secure_123}
ODOO_DATABASE=${PGDATABASE:-${ODOO_DATABASE:-odoo_prod}}  # ← FIX: Lee PGDATABASE primero

# Puerto de Railway (FIX: 8080 no 8069)
PORT=${PORT:-8080}

echo "========================================"
echo "Esperando PostgreSQL..."
echo "DB_HOST=$DB_HOST"
echo "DB_PORT=$DB_PORT"
echo "ODOO_DATABASE=$ODOO_DATABASE"
echo "========================================"

# ESPERA A POSTGRESQL
export PGPASSWORD="$DB_SUPERPASS"
until PGPASSWORD="$DB_SUPERPASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_SUPERUSER" -d "postgres" -c '\q' 2>/dev/null; do
  >&2 echo "PostgreSQL no está listo - esperando..."
  sleep 2
done

echo "PostgreSQL listo ✅"

echo "========================================"
echo "Configurando usuario de base de datos..."
echo "========================================"

# Crear usuario odoo si no existe
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_SUPERUSER" -d "postgres" <<-EOSQL || true
    DO \$\$
    BEGIN
        IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '$ODOO_DB_USER') THEN
            CREATE ROLE $ODOO_DB_USER WITH LOGIN PASSWORD '$ODOO_DB_PASSWORD' CREATEDB;
        END IF;
    END
    \$\$;
EOSQL

# Crear base de datos si no existe
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_SUPERUSER" -d "postgres" -c "CREATE DATABASE \"$ODOO_DATABASE\" OWNER \"$ODOO_DB_USER\";" 2>/dev/null || echo "Database ya existe"

# Construir addons-path
ADDONS_PATH="/usr/lib/python3/dist-packages/odoo/addons"

if find /mnt/extra-addons -maxdepth 2 -name "__manifest__.py" 2>/dev/null | grep -q .; then
    ADDONS_PATH="/mnt/extra-addons,$ADDONS_PATH"
    echo "Módulos custom encontrados en /mnt/extra-addons"
else
    echo "No hay módulos custom (o carpeta vacía)"
fi

echo "========================================"
echo "Iniciando Odoo en puerto $PORT"
echo "Addons path: $ADDONS_PATH"
echo "========================================"

# Ejecutar Odoo
exec su odoo -s /bin/bash -c "odoo \
    --db_host=$DB_HOST \
    --db_port=$DB_PORT \
    --db_user=$ODOO_DB_USER \
    --db_password=$ODOO_DB_PASSWORD \
    --http-port=$PORT \
    --admin_passwd=$ODOO_ADMIN_PASSWORD \
    --proxy-mode \
    --workers=${ODOO_WORKERS:-1} \
    --without-demo=True \
    --log-level=${ODOO_LOG_LEVEL:-info} \
    --limit-memory-soft=268435456 \
    --limit-memory-hard=402653184 \
    --addons-path=$ADDONS_PATH \
    --database=$ODOO_DATABASE"


