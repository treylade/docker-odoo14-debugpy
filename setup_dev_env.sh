#!/bin/zsh

# Stop the containers
docker stop odoo db

# Remove the containers
docker rm -v odoo db

# Build the docker image
docker buildx build --platform linux/amd64 -t odoo ~/Git/docker-odoo14-debugpy

# Run the postgres container
docker run -d -p 5432:5432 -e POSTGRES_USER=odoo -e PUID=1000 -e PGID=1000 -e POSTGRES_PASSWORD=odoo -e POSTGRES_DB=postgres --name db postgres:14

# Give it a moment to ensure the database is up
sleep 10

# Create the test database
echo "CREATE DATABASE stage ENCODING 'unicode' TEMPLATE template1;" | docker exec -i -u root db psql -U odoo postgres

# Copy the dump file to the container
docker cp bak.dump db:/var/lib/postgresql/data

# Restore the database from the dump
docker exec db pg_restore -U odoo --dbname=stage --no-owner /var/lib/postgresql/data/bak.dump

# Update some data for development
echo "UPDATE ir_mail_server SET smtp_user = null, smtp_pass = null;" | docker exec -i -u root db psql -U odoo stage
echo "UPDATE ir_cron SET active = false;" | docker exec -i -u root db psql -U odoo stage

# Run the odoo container
docker run -d --platform linux/amd64 -p 80:8069 -p 8088:443 -p 3001:3000 -e PUID=1000 -e PGID=1000 -v /Users/treyla/Git/custom_swaf:/mnt/extra-addons --name odoo --link db:db -t odoo

echo "Development environment successfully created. Please attach debug mode to continue."