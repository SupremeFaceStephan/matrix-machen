# Mautrix whatsapp config

### 1. Creating database
```bash
docker exec -it matrix-postgres psql -U synapse -c "CREATE DATABASE mautrix_whatsapp;"
```

```bash
docker exec -it matrix-postgres psql -U synapse -c "GRANT ALL PRIVILEGES ON DATABASE mautrix_whatsapp TO synapse;"
```

### 2. Generating mautrix
```bash
docker run --rm \
		-v "./mautrix-whatsapp:/data" \
		dock.mau.dev/mautrix/whatsapp:latest
```

### 3. Configuration
- Change displayname-template to  `displayname_template: "{{or .BusinessName .FullName .PushName .Phone}}"` if you want cleaner list.
- Find appservice and change `address` to `http://whatsapp-bridge:29318` for proper registration generation
- In `appservice` change `hostname` from `127.0.0.1` to `0.0.0.0` else you will face connection issues.
- In `appservice` change the public domain to your domain (example: `https://matrix.example.com`)
- (Optional, if you want older messages) Go to backfill category and enable it, configure it to your liking, or leave the default.
- Find `permissions` and change `"@admin:example.com": admin` to `<your matrix username>: admin`

#### Again generate mautrix
```bash
docker run --rm \
		-v "./mautrix-whatsapp:/data" \
		dock.mau.dev/mautrix/whatsapp:latest
```

#### Open homeserver
```bash
nano ./files/homeserver.yaml
```
and add on bottom:

```yaml
app_service_config_files:
	- /data/whatsapp-registration.yaml
```

#### Edit synapse in compose.yml
```bash
volumes:
  - ./files:/data
  - ./mautrix-meta/registration.yaml:/data/meta-registration.yaml:ro
  - ./mautrix-whatsapp/registration.yaml:/data/whatsapp-registration.yaml:ro
```