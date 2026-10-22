# Developer documentation

How to set up, build and manage the project. The design choices are explained
in the [README](README.md).

## Prerequisites

- Docker and Docker Compose v2 (`docker compose`, not `docker-compose`)
- GNU Make
- `sudo`, to edit `/etc/hosts`

## Project layout

```
.
├── Makefile
├── secrets/                  # passwords, ignored by Git
└── srcs/
    ├── .env                  # configuration, ignored by Git
    ├── .env.example
    ├── docker-compose.yml
    └── requirements/
        ├── mariadb/   (Dockerfile, conf/, tools/entrypoint.sh)
        ├── wordpress/ (Dockerfile, conf/, tools/entrypoint.sh)
        └── nginx/     (Dockerfile, conf/, tools/entrypoint.sh)
```

## Setup from scratch

### 1. The `.env` file

```bash
cp srcs/.env.example srcs/.env
```

Fill every value. The file only contains non-sensitive settings:

| Variable | Used by | Example |
|---|---|---|
| `MARIADB_DATABASE` | mariadb, wordpress | `wordpress` |
| `MARIADB_USER` | mariadb, wordpress | `wpuser` |
| `MARIADB_HOST` | wordpress | `mariadb` (the service name) |
| `WP_URL` | wordpress | `dufama.42.fr` |
| `WP_TITLE` | wordpress | `Inception` |
| `WP_ADMIN_USER` / `WP_ADMIN_EMAIL` | wordpress | the login must not contain `admin` |
| `WP_USER` / `WP_USER_EMAIL` | wordpress | second account (role author) |
| `DOMAIN_NAME` | nginx | `dufama.42.fr` |

### 2. The secrets

Create the `secrets/` folder at the root of the repo (next to `srcs/`):

```bash
mkdir -p secrets
printf '%s' 'root_password_here' > secrets/db_root_password.txt
printf '%s' 'db_password_here'   > secrets/db_password.txt
printf 'WP_ADMIN_PASSWORD=%s\nWP_USER_PASSWORD=%s\n' 'admin_pw' 'user_pw' > secrets/credentials.txt
```

- `db_root_password.txt` and `db_password.txt` contain only the password.
  Use two different passwords.
- `credentials.txt` uses one `KEY=value` per line. The value can contain `=`.

`secrets/` is in `.gitignore`. Check it with `git status`: nothing from this
folder must appear.

Who gets which secret (in `docker-compose.yml`):

| Service | Secrets | Mounted as |
|---|---|---|
| mariadb | `db_root_password`, `db_password` | `/run/secrets/db_root_password`, `/run/secrets/db_password` |
| wordpress | `db_password`, `credentials` | `/run/secrets/db_password`, `/run/secrets/credentials` |
| nginx | none | — |

Inside the container the file is named after the secret, without `.txt`.

How a password reaches the program:

```
secrets/db_password.txt  (host)
   └─ Compose mounts it → /run/secrets/db_password  (container)
       └─ entrypoint.sh: MARIADB_PASSWORD=$(cat /run/secrets/db_password)
           └─ used for the init, then exec of the main process
```

The MariaDB health check runs in a new shell, so it reads
`/run/secrets/db_password` itself instead of using the variable.

### 3. The domain

```bash
sudo sh -c 'echo "127.0.0.1 dufama.42.fr" >> /etc/hosts'
```

`WP_URL`, `DOMAIN_NAME`, `server_name` in `nginx.conf` and `/etc/hosts` must
use the same domain.

## Build and launch

```bash
make
```

What it does:

1. sets `DATA_PATH` to `$(HOME)/data` and exports it for Compose
2. creates `~/data/mariadb` and `~/data/wordpress` (the volumes need them to exist)
3. runs `docker compose -f srcs/docker-compose.yml up -d --build`

Start order: mariadb starts first, wordpress waits until mariadb is
`healthy`, then nginx starts.

Always go through `make`. Running `docker compose` by hand without
`DATA_PATH` set will fail to mount the volumes.

## Managing containers and volumes

Makefile rules:

| Rule | Action |
|---|---|
| `make` / `make up` | build and start |
| `make build` | build the images only |
| `make down` | stop and remove the containers, keep the data |
| `make re` | `down` then `up` |
| `make ps` | state of the containers |
| `make logs` | follow the logs |
| `make clean` | same as `down` |
| `make fclean` | remove containers, images, volumes **and** the data folders |

Useful Docker commands:

```bash
docker exec -it mariadb sh                    # shell in a container
docker logs wordpress                         # logs of one service
docker exec wordpress ls /run/secrets         # check the mounted secrets
docker volume ls                              # list volumes
docker volume inspect srcs_db_data            # see where a volume points
docker network inspect srcs_inception         # containers on the network
```

Connect to the database:

```bash
docker exec -it mariadb sh -c 'mariadb -uroot -p"$(cat /run/secrets/db_root_password)"'
```

After changing an entrypoint or a Dockerfile, rebuild with `make` (it uses
`--build`). After changing a secret or a password, `make fclean` is needed,
because the init only runs when the data folder is empty.

## Where the data is stored

Two named volumes, bound to folders on the host:

| Volume | Host folder | Container path |
|---|---|---|
| `db_data` | `~/data/mariadb` | `/var/lib/mysql` (mariadb) |
| `wp_files` | `~/data/wordpress` | `/var/www/html` (wordpress, and nginx in read-only) |

```
volume "srcs_db_data" ──points to──> ~/data/mariadb <──bind──> /var/lib/mysql
```

The volume is only a reference: the real files are in `~/data`. So:

- `make down` + `make`: everything is kept. The entrypoints see that
  `/var/lib/mysql/mysql` and `wp-config.php` exist and skip the init.
- `docker compose down --volumes`: removes the volume references, **not** the
  files.
- `make fclean`: also runs `rm -rf` on the two folders, so the next `make`
  does a full new install.

On a Linux VM, the files in `~/data` belong to the users of the containers
(`mysql`, `www-data`), so `rm -rf` can fail with `Permission denied`. Check
that `~/data/mariadb` is really empty after `make fclean`, or use `sudo`.
