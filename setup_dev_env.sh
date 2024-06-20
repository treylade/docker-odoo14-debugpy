#!/bin/zsh

# Stop the containers
docker stop odoo16 odoo_16_pg

# Remove the containers
docker rm -v odoo16 odoo_16_pg

# Build the docker image
docker buildx build --platform linux/amd64 -t odoo ~/Git/docker-odoo16-debugpy

# Run the postgres container
docker run -d -p 5432:5432 -e POSTGRES_USER=odoo -e PUID=1000 -e PGID=1000 -e POSTGRES_PASSWORD=odoo -e POSTGRES_DB=postgres --name odoo_16_pg postgres:14

# Give it a moment to ensure the database is up
sleep 10

# Check if the dump file exists
if [ -f bak.dump ]; then
    # Create the test database
    echo "CREATE DATABASE stage ENCODING 'unicode' TEMPLATE template1;" | docker exec -i -u root odoo_16_pg psql -U odoo postgres
    
    # Copy the dump file to the container
    docker cp bak.dump odoo_16_pg:/var/lib/postgresql/data

    # Restore the database from the dump
    docker exec odoo_16_pg pg_restore -U odoo --dbname=stage --no-owner /var/lib/postgresql/data/bak.dump

    # Update some data for development
    echo "UPDATE ir_mail_server SET smtp_user = null, smtp_pass = null;" | docker exec -i -u root odoo_16_pg psql -U odoo stage
    echo "UPDATE ir_cron SET active = false;" | docker exec -i -u root odoo_16_pg psql -U odoo stage
else
    echo "Dump file bak.dump not found. Skipping database restore and updates."
fi

# Run the odoo container
docker run -d --platform linux/amd64 -p 80:8069 -p 8088:443 -p 3001:3000 -e PUID=1000 -e PGID=1000 -v /Users/treyla/Git/custom_swaf:/mnt/extra-addons -e POSTGRES_DB=odoo_16_pg --name odoo16 --link odoo_16_pg:db -t odoo

echo "Development environment successfully created. Please attach debug mode to continue."
