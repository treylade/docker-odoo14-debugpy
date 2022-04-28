**Fork of:** [odoo/docker](https://github.com/odoo/docker) | [Docker Hub Page](https://hub.docker.com/_/odoo)

**The changes I did to this fork:**

- Offer only ODOO 14, with latest Nightly-Build version (not automated yet, I bump the Release-ID up manually)
- Add debugpy to image and implement attach-hook for remote debugging

**Setup:**

I used non-default port-mappings to prevent collisions with existing containers for ODOO 13.

```shell
docker pull lrstry/odoo14-latest-debugpy:latest
docker run -d -p 5433:5432 -e POSTGRES_USER=odoo -e PUID=1000 -e PGID=1000 -e POSTGRES_PASSWORD=odoo -e POSTGRES_DB=postgres --name db postgres:10
docker run -p 8070:8069 -p 3001:3000 -e PUID=1000 -e PGID=1000 -v /home/docker/Git/custom_swaf:/mnt/extra-addons --name odoo --link db:db -t lrstry/odoo14-latest-debugpy
```

**Debugging with VSCode using following launch.json:**

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "ODOO Docker",
      "type": "python",
      "request": "attach",
      "host": "localhost",
      "port": 3001,
      "pathMappings": [
        {
          "localRoot": "/home/docker/Git/custom_swaf/",
          "remoteRoot": "/mnt/extra-addons"
        },
        {
          "localRoot": "/home/docker/Git/odoo/odoo",
          "remoteRoot": "/usr/lib/python3/dist-packages/odoo"
        }
      ]
    }
  ]
}
```
