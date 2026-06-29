# Nginx (WWW) setup.
```bash
sudo nano /etc/nginx/sites-available/example.com # or whatever.
```

```yaml
server {
    listen 443 ssl;
    listen [::]:443 ssl;
    server_name matrix.example.com;

    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;

    # If you don't want to serve a site, comment this out.
    root /var/www/example.com;
    index index.html index.htm;

    location /_matrix {
      proxy_pass http://0.0.0.0:8008;
      proxy_set_header X-Forwarded-For $remote_addr;
    }
 }
```

```bash
sudo ln -s /etc/nginx/sites-available/example.com /etc/nginx/sites-enabled/example.com
```