# Synapse in docker compose with bridges
Guide on how to set up Synapse with Mautrix-meta.
## 1. Basics
### 1. Install docker
   ```bash
   curl -fsSL https://raw.githubusercontent.com/SupremeFaceStephan/matrix-machen/refs/heads/main/install-docker-compose.sh | bash
   ```
### 2. Make folder
   ```bash
   mkdir -p /docker /docker/matrix
   cd /docker/matrix
   ```
### 3. Get basic config
   ```bash
    curl -o compose.yml https://raw.githubusercontent.com/SupremeFaceStephan/matrix-machen/refs/heads/main/basic-config.yaml
   ```
   ### 4. Generate config
   ```bash
   docker compose run --rm -e SYNAPSE_SERVER_NAME=matrix.twojadomena.pl synapse generate
   ```
### 5. Edit homeserver.yaml
   ```bash
   nano ./files/homeserver.yaml
   ```
```yaml
database:
  name: psycopg2
  args:
    user: "synapse"
    password: "synapse"
    database: "synapse"
    host: "db"                                                                                                                
    port: 5432
    cp_min: 5
    cp_max: 10
```
In the config file, change bind-addreses from `['::1', '127.0.0.1']` to `['0.0.0.0']` to bind synapse to all interfaces.

## 2. DNS
### You need to open port 8008 (and 8448 if you don't use a proxy or SRV record and want [federation](https://element-hq.github.io/synapse/latest/federate.html)).

As your server is running on a single port, you need to add 2 records to your DNS:

`A <your domain> <your ip>` - to point to your server.

`SRV _matrix._tcp <your domain> 10 0 8008 <your domain>` - clients will use this to detect the federation server.



### [Nginx Proxy manager setup](docs/NPM-config.md)
### [Nginx (WWW) setup](docs/Nginx-config.md)

## 3. Creating user
```bash
curl https://raw.githubusercontent.com/SupremeFaceStephan/matrix-machen/refs/heads/main/create-user.sh
chmod +x create-user.sh
./create-user.sh alice MyStrongP@ssw0rd admin
```

## With that you have your basic synapse config

## 4. Mautrix (bridges)

### 1. Creating database
```bash
docker exec -it matrix-postgres psql -U synapse -c "CREATE DATABASE mautrix_meta;"
```

```bash
docker exec -it matrix-postgres psql -U synapse -c "GRANT ALL PRIVILEGES ON DATABASE mautrix_meta TO synapse;"
```

### 2. Generating mautrix
```bash
docker run --rm \
		-v "./mautrix-meta:/data" \
		dock.mau.dev/mautrix/meta:latest
```

### 3. Configuration
- Find homeserver and change `address` to `http://synapse:8008` and domain to your domain.
- Find appservice and change `address` to `http://meta-bridge:29319` for proper registration generation.
- In `appservice`, change `hostname` from `127.0.0.1` to `0.0.0.0`, or you will face connection issues.
- In `appservice`, change the public domain to your domain (example: `https://matrix.example.com`).
- Optional: if you want older messages, go to the backfill category and enable it, configure it to your liking, or leave the default.
- Find `permissions` and change `"@admin:example.com": admin` to `<your matrix username>: admin`.

### 4. Again generate mautrix
```bash
docker run --rm \
		-v "./mautrix-meta:/data" \
		dock.mau.dev/mautrix/meta:latest
```

### 5. Open homeserver
```bash
nano ./files/homeserver.yaml
```
and add at the bottom:

```yaml
app_service_config_files:
	- /data/meta-registration.yaml
```

### 6. Edit synapse in compose.yml
```bash
volumes:
  - ./files:/data
  - ./mautrix-meta/registration.yaml:/data/meta-registration.yaml:ro
```

### 7. Add mautrix to config <br>
(for meta-bridge your `compose.yml` should look like this)
```yaml
services:
  synapse:
    image: docker.io/matrixdotorg/synapse:latest
    container_name: matrix-synapse
    restart: unless-stopped
    environment:
      - SYNAPSE_CONFIG_PATH=/data/homeserver.yaml
      - UID=991
      - GID=991
      - SYNAPSE_REPORT_STATS=no
    ports:
      - 8008:8008
    volumes:
      - ./files:/data
      - ./mautrix-meta/registration.yaml:/data/meta-registration.yaml:ro
    depends_on:
      - db
    networks:
      - synapse-network
 meta-bridge:
    image: dock.mau.dev/mautrix/meta:latest
    container_name: matrix-meta-bridge
    environment:
      - UID=991
      - GID=991
    restart: unless-stopped
    volumes:
      - ./mautrix-meta:/data
    depends_on:
      - db
      - synapse
    networks:
      - synapse-network
  db:
    image: docker.io/postgres:18-alpine
    container_name: matrix-postgres
    restart: unless-stopped
    environment:
      - POSTGRES_USER=synapse
      - POSTGRES_PASSWORD=synapse
      - POSTGRES_INITDB_ARGS=--encoding=UTF-8 --lc-collate=C --lc-ctype=C
    volumes:
      - ./db_data:/var/lib/postgresql/18/docker 
    networks:
      - synapse-network
networks:
  synapse-network: {}
```

### Starting the bridge
1. Restart the Synapse container
```bash
docker compose restart synapse
```
2. Run it to check for any potential errors.
```bash
docker compose up meta-bridge
```

3. If no errors, turn it off and run in detached mode.
```bash
docker compose up -d meta-bridge
```

4. Find `@metabot:matrix.yourdomain.com` and create a DM with it. If it has the Meta logo avatar, that means everything is good. Run `help` to see the help message.

### You can now use the Facebook bridge!

## [Adding whatsapp bridge](docs/whatsapp-bridge.md)
## [Double puppeting](docs/double-puppeting.md)