**Fork of:** [odoo/docker](https://github.com/odoo/docker) | [Docker Hub Page](https://hub.docker.com/_/odoo)

**The changes I did to this fork:**

- Offer only ODOO 14, with latest Nightly-Build version (not automated yet, I bump the Release-ID up manually)
- Add ptvsd to image and implement attach-hook for remote debugging

**Setup:**

I used non-default port-mappings to prevent collisions with existing containers for ODOO 13.

```shell
docker pull lrstry/odoo14-latest-ptvsd
docker run -d -p 5433:5432 -e POSTGRES_USER=odoo -e POSTGRES_PASSWORD=odoo -e POSTGRES_DB=postgres --name odoo14_db postgres:10
docker run -p 8070:8069 -p 3001:3000 -v /path/to/local/extra-addons:/mnt/extra-addons --name odoo14 --link odoo14_db:db -t lrstry/odoo14-latest-ptvsd
```

**Debugging with VSCode using following launch.json:**

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Python: Remote Attach",
      "type": "python",
      "request": "attach",
      "port": 3000,
      "debugServer": 3000,
      "host": "localhost",
      "pathMappings": [
        {
          "localRoot": "{path to local addons folder}",
          "remoteRoot": "/mnt/extra-addons/"
        }
      ]
    }
  ]
}
```
