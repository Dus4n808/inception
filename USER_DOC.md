# User documentation

This page explains how to use the Inception stack once it is installed.
To install it from scratch, see [DEV_DOC.md](DEV_DOC.md).

## What the stack provides

- **A WordPress website**, available in HTTPS.
- **A web server (nginx)**, the only entry point, on port 443.
- **A database (MariaDB)** that stores the content of the site.

Only the website is reachable from outside. The database and PHP are hidden
inside a private Docker network.

## Start and stop

Run these commands from the root of the repository:

```bash
make          # start everything
make down     # stop everything, data is kept
make re       # restart
```

`make down` does not delete anything: posts, users and settings are still
there at the next `make`.

`make fclean` deletes **everything**, including the website and the database.
Use it only if you want to start over.

## Access the website

- Website: **https://dufama.42.fr**
- Admin panel: **https://dufama.42.fr/wp-admin**

The browser will show a warning ("your connection is not private"). This is
normal: the certificate is self-signed. The connection is still encrypted.
Click on "Advanced" then "Continue" to reach the site.

If the page does not load at all, check that the domain is in `/etc/hosts`:

```bash
grep dufama /etc/hosts
```

## Credentials

User names are in `srcs/.env`. Passwords are in the `secrets/` folder:

| File | Content |
|---|---|
| `secrets/credentials.txt` | passwords of the two WordPress accounts (admin and normal user) |
| `secrets/db_password.txt` | password used by WordPress to talk to the database |
| `secrets/db_root_password.txt` | password of the database administrator (root) |

To log in to the admin panel, use `WP_ADMIN_USER` from `srcs/.env` and
`WP_ADMIN_PASSWORD` from `secrets/credentials.txt`.

These files are never pushed to Git. Do not share them.

**Changing a password:** editing these files has no effect on a site that is
already installed. The passwords are only used during the first start. To
change a WordPress password, use the admin panel (Users > Profile). To apply
new files, the stack has to be reset with `make fclean` then `make`
(this deletes all data).

## Check that everything works

```bash
make ps
```

The three containers `nginx`, `wordpress` and `mariadb` must be `Up`, and
`mariadb` must be `(healthy)`.

```bash
make logs
```

On the first start you should see `[mariadb] Init terminé` then
`[wordpress] Init terminé`. On the next starts: `db trouvé -> démarrage` and
`installation trouvé -> démarrage`. Press `Ctrl+C` to leave the logs.

Finally, open the website in the browser and log in to the admin panel.

## Common problems

| Problem | What to check |
|---|---|
| Page does not load | the domain in `/etc/hosts`, and `make ps` |
| `wordpress` keeps restarting | `make logs`, usually a missing value in `.env` or `secrets/` |
| `mariadb` stays `unhealthy` | the password in `secrets/db_password.txt` does not match the one used at the first start: run `make fclean` then `make` |
