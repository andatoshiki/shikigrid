FROM golang:alpine as builder

# ENV GO111MODULE=on

LABEL maintainer="Anda Toshiki <hello@toshiki.dev>"

RUN apk update && apk add --no-cache git

# download, cache and install deps
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download

# copy and compiled the app
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o shikigrid cmd/shikigrid/main.go

# start a new stage from scratch
FROM alpine:latest
RUN apk --no-cache add ca-certificates

WORKDIR /root/

# copy the prebuilt binary and .env from the builder stage
COPY --from=builder /app/shikigrid .
COPY --from=builder /app/.env .

EXPOSE 8666

CMD ["./shikigrid"]