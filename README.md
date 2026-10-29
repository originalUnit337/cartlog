# Cartlog

A Telegram bot for tracking printer cartridges. The project is being built in
small steps with Clean Architecture boundaries:

- `domain/` contains cartridge entities and repository contracts.
- `application/` contains use cases and business rules.
- `infrastructure/` contains PostgreSQL and configuration adapters.
- `bin/` is the composition root.

## PostgreSQL setup

For local development with Docker, start PostgreSQL with a persistent volume.
Port `5434` is used on the host to avoid clashing with a local PostgreSQL
server; PostgreSQL listens on `5432` inside the container.

```sh
docker run --name cartlog-postgres \
  -e POSTGRES_USER=cartlog \
  -e POSTGRES_PASSWORD=change-me \
  -e POSTGRES_DB=cartlog \
  -p 5434:5432 \
  -v cartlog-postgres-data:/var/lib/postgresql/data \
  -d postgres:17
```

Copy `.env.example` to `.env`, set `DATABASE_PORT=5434`, and provide the token
you received from Telegram's `@BotFather` as `TELEGRAM_BOT_TOKEN`. The remaining
database example credentials match the Docker command above.

Apply the initial schema:

```sh
docker exec -i cartlog-postgres \
  psql -U cartlog -d cartlog -v ON_ERROR_STOP=1 \
  < database/migrations/001_initial_schema.sql

docker exec -i cartlog-postgres \
  psql -U cartlog -d cartlog -v ON_ERROR_STOP=1 \
  < database/migrations/002_archive_cartridges.sql
```

Start the bot:

```sh
dart run bin/main.dart
```

## Deploy to Debian with Docker Compose

The repository includes a Dockerfile and Compose setup for the bot plus a new
PostgreSQL 17 database. On Debian, verify Docker Compose is available, then clone
the `dev` branch and configure the server environment:

```sh
git clone -b dev https://github.com/originalUnit337/cartlog.git
cd cartlog
cp .env.example .env
nano .env
```

Set a strong `DATABASE_PASSWORD` and your real `TELEGRAM_BOT_TOKEN`. For Compose,
the bot connects to the database service at `db:5432`; the Compose file sets
these values internally. Start the services with:

```sh
docker compose config --quiet
docker compose up -d --build
docker compose ps
docker compose logs -f bot
```

The bot uses long polling and requires outbound access to Telegram, so no
inbound bot port or public PostgreSQL port is published. Compose stores database
files in the `postgres_data` named volume. The SQL files in
`database/migrations/` run automatically only when that volume is first
initialized. `docker compose down` preserves the volume; `docker compose down -v`
deletes the database.

To deploy later code changes, pull `dev` and rebuild the bot:

```sh
git pull origin dev
docker compose up -d --build bot
```

New SQL migrations are not rerun on an existing volume; apply each new migration
once before restarting the bot.

Open the bot in Telegram and send `/start` to show the persistent button menu.
Use **Картриджи**, **Поиск**, **Добавить**, or **Импорт CSV** to navigate.
Cartridge lists and search results are paginated; select a result to open its
detail card and use the status, edit, history, and archive buttons. Slash
commands remain available as fallbacks: `/list`, `/number 001`, `/office 101`,
`/add`, `/edit <id>`, `/remove <id>`, and `/import`. Add/edit use copyable forms;
new cartridges default to `ready`. Remove archives the record, hiding it from
active lists and searches while retaining its history.

Number searches match the exact cartridge number; office searches match an
office prefix, so searching `504` also finds `504-1` and `504-2`.

CSV import accepts semicolon-separated exports encoded as UTF-8 or Windows-1251.
It previews invalid rows and possible duplicate numbers before confirmation.
Duplicates are always imported as new records; existing cartridges are never
updated or deleted. For the supplied Russian export, `принят` maps to `ready`,
blank status defaults to `ready`, and blank offices map to `-`.

Environment variables set in the process take precedence over values in
`.env`. Never commit the local `.env` file.

## Tests

Run unit tests with:

```sh
dart test
```

To run PostgreSQL repository integration tests against the configured database:

```sh
RUN_DATABASE_TESTS=true dart test test/infrastructure/database/postgres_repositories_integration_test.dart
```
