FROM golang:1.24-alpine AS builder
WORKDIR /src
COPY . .
RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o app .

FROM scratch
COPY --from=builder /src/app /app
ENTRYPOINT [ "/app" ]
