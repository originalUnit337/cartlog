FROM dart:stable AS build

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN dart pub get --enforce-lockfile

COPY bin/ ./bin/
COPY lib/ ./lib/

RUN dart compile exe bin/main.dart -o /app/cartlog

FROM dart:stable AS runtime

RUN apt-get update \
    && apt-get install -y --no-install-recommends postgresql-client-17 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=build /app/cartlog ./cartlog

USER 65532:65532

ENTRYPOINT ["./cartlog"]
