FROM odoo:18.0

USER root

# Instalar cliente PostgreSQL para el setup
RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Copiar módulos custom (si los hay)
COPY --chown=odoo:odoo custom_addons /mnt/extra-addons

# Copiar entrypoint personalizado
COPY entrypoint.sh /entrypoint-custom.sh
RUN chmod +x /entrypoint-custom.sh

EXPOSE 8069

ENTRYPOINT ["/entrypoint-custom.sh"]
