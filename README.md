# H2 Database Server

Unofficial Docker image of the [H2 database](https://h2database.com) server, available for every H2 2.x release.
It is small (about 51 MB compressed), supports `linux/amd64` and `linux/arm64`, and keeps the full H2 functionality.

## Quick start

```sh
docker run -d --name h2 -p 9092:9092 -p 8082:8082 -v h2data:/data wakamiti/h2:latest
```

- JDBC URL: `jdbc:h2:tcp://localhost:9092/mydb` (user `sa`, empty password)
- Web console: http://localhost:8082

## Tags

- `latest`: the newest H2 release.
- `2.5.252`, `2.5.250`, `2.4.240`, …: one tag per H2 2.x release, from `2.0.202`.

## Configuration

| | |
|---|---|
| Ports | `9092` TCP (JDBC), `8082` web console, `5435` PostgreSQL protocol |
| Volume | `/data`: where the databases are stored |
| `H2_OPTS` | H2 server options. Default: `-tcp -tcpAllowOthers -web -webAllowOthers -pg -pgAllowOthers -ifNotExists -baseDir /data` |
| `JAVA_OPTS` | JVM options, e.g. `-Xmx256m` |
| `H2_URL` | JDBC URL used by default by the [command line](#command-line) scripts. Default: `jdbc:h2:tcp://localhost:9092/mydb` |
| `H2_USER` | User used by default by the command line scripts. Default: `sa` |
| `H2_PASSWORD` | Password used by default by the command line scripts. Default: empty |

- **`H2_URL`, `H2_USER` and `H2_PASSWORD` only configure the CLI scripts.** They do not create users on the server: H2 sets a database's admin user and password from the first connection that creates it, so use the same credentials afterwards.
- **Security:** by default the servers accept connections from any address and clients can create new databases (`-ifNotExists`). Publish only the ports you need, don't expose them to untrusted networks, and remove `-ifNotExists` from `H2_OPTS` if clients must not create databases.
- **Ports:** if you change a port in `H2_OPTS`, the healthcheck (which checks `9092`) will report the container as unhealthy, and the command line scripts need a matching `H2_URL`.
- **Permissions:** the container runs as a non-root user (uid `100`, gid `101`). A host directory mounted on `/data` must be writable by it, e.g. `chown 100:101 ./data`.

### docker compose

```yaml
services:
  h2:
    image: wakamiti/h2:latest
    ports: ["9092:9092", "8082:8082"]
    volumes: ["h2data:/data"]
    environment:
      JAVA_OPTS: -Xmx256m
volumes:
  h2data:
```

## Command line

The image includes two scripts already connected to the local server:

```sh
# Interactive SQL shell
docker exec -it h2 h2-shell

# Run a statement and exit
docker exec h2 h2-shell -sql "select * from t"

# Run a SQL file from your machine
docker exec -i h2 h2-runscript < script.sql
```

Use `-url`, `-user` and `-password` to connect to another database or with other credentials, for example
`docker exec -it h2 h2-shell -url jdbc:h2:tcp://localhost:9092/other -user alice -password secret`.
With the PostgreSQL port (`5435`) published you can also use `psql -h localhost -p 5435 -U sa mydb`.

## Notes

- Includes everything H2 needs, such as Java source in `CREATE ALIAS`, locales and charsets. Only the Swing desktop window is left out, because it needs a display; the web console works normally.
- Database files created with H2 1.x are not compatible with 2.x.
- Server logs go to the container output (`docker logs`).

## Source

How the image is built: https://github.com/wakamiti/h2-docker
