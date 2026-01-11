FROM odoo:18.0

USER root

# Instalar cliente PostgreSQL para el setup
RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Crear carpeta para módulos custom
RUN mkdir -p /mnt/extra-addons && chown odoo:odoo /mnt/extra-addons

# Copiar módulos custom si existen
COPY --chown=odoo:odoo custom_addons/ /mnt/extra-addons/

# Copiar entrypoint personalizado (CAMBIADO)
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8080

ENTRYPOINT ["/entrypoint.sh"]
