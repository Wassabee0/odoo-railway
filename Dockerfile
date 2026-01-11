FROM odoo:19.0
COPY ./addons /mnt/extra-addons
RUN chown -R odoo:odoo /mnt/extra-addons
