**Mac ARM Build:**
```shell
docker buildx build --platform linux/amd64 -t odoo .
docker run --platform linux/amd64 -p 80:8069 -p 8088:443 -p 3001:3000 -e PUID=1000 -e PGID=1000 -v /Users/treyla/Git/custom_swaf:/mnt/extra-addons --name odoo --link db:db -t odoo
docker exec -it -u root odoo bash
pip3 install cachetools apispec>=4.0.0 cerberus pyquerystring parse-accept-language marshmallow marshmallow-objects>=2.0.0
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
