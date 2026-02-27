FROM kirillsaidov/dlang:dmd-latest AS builder

WORKDIR /app

COPY dub.json dub.selections.json ./
COPY source/ source/
COPY views/ views/
COPY public/ public/
RUN dub build

FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends clang-format && \
    rm -rf /var/lib/apt/lists/*

RUN useradd -r -s /bin/false cppformat

WORKDIR /app
COPY --from=builder /app/cppformat .
COPY public/ public/

USER cppformat
EXPOSE 8080
CMD ["./cppformat"]
