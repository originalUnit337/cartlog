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

Open the bot in Telegram and send `/start` for commands. `/list` shows active
cartridges, `/number 001` searches by number, and `/office 101` searches by
office. `/add` returns a copyable form; a new cartridge defaults to `ready`.
`/edit <id>` returns the current values in a copyable form. `/remove <id>`
archives the cartridge, hiding it from active lists/search while retaining its
record and history. Searches return all exact matches.

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
