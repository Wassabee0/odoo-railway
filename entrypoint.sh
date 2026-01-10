#!/bin/bash
set -e

# Variables de Railway PostgreSQL
DB_HOST=${PGHOST:-localhost}
DB_PORT=${PGPORT:-5432}
DB_SUPERUSER=${PGUSER:-postgres}
DB_SUPERPASS=${PGPASSWORD:-postgres}

# Usuario dedicado para Odoo
ODOO_DB_USER=${ODOO_DB_USER:-odoo}
ODOO_DB_PASSWORD=${ODOO_DB_PASSWORD:-odoo_secure_123}

# Puerto de Railway
PORT=${PORT:-8069}

echo "========================================"
echo "Configurando usuario de base de datos..."
echo "========================================"

# Crear usuario odoo si no existe
export PGPASSWORD="$DB_SUPERPASS"
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_SUPERUSER" -d "postgres" <<-EOSQL || true
    DO \$\$
    BEGIN
        IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '$ODOO_DB_USER') THEN
            CREATE ROLE $ODOO_DB_USER WITH LOGIN PASSWORD '$ODOO_DB_PASSWORD' CREATEDB;
        END IF;
    END
    \$\$;
EOSQL

# Construir addons-path solo con directorios válidos
ADDONS_PATH="/usr/lib/python3/dist-packages/odoo/addons"

# Solo añadir extra-addons si contiene módulos válidos (carpetas con __manifest__.py)
if find /mnt/extra-addons -maxdepth 2 -name "__manifest__.py" 2>/dev/null | grep -q .; then
    ADDONS_PATH="/mnt/extra-addons,$ADDONS_PATH"
    echo "Modulos custom encontrados en /mnt/extra-addons"
else
    echo "No hay modulos custom (o carpeta vacia)"
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
    --proxy-mode \
    --workers=${ODOO_WORKERS:-1} \
    --without-demo=True \
    --log-level=${ODOO_LOG_LEVEL:-warn} \
    --limit-memory-soft=268435456 \
    --limit-memory-hard=402653184 \
    --addons-path=$ADDONS_PATH \
    ${ODOO_DATABASE:+--database=$ODOO_DATABASE} \
    ${ODOO_ADMIN_PASSWORD:+--admin_passwd=$ODOO_ADMIN_PASSWORD}"

