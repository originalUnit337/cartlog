FROM dart:stable AS build

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN dart pub get --enforce-lockfile

COPY bin/ ./bin/
COPY lib/ ./lib/

RUN dart compile exe bin/main.dart -o /app/cartlog

FROM dart:stable AS runtime

WORKDIR /app
COPY --from=build /app/cartlog ./cartlog

USER 65532:65532

ENTRYPOINT ["./cartlog"]
