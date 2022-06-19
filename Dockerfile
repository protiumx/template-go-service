FROM golang:1.18.3 AS build

RUN adduser \
  --disabled-password \
  --gecos "" \
  --home "/nonexistent" \
  --shell "/sbin/nologin" \
  --no-create-home \
  --uid "1000" \
  "appuser"

# TODO: chage this with your package name
WORKDIR $GOPATH/src/github.com/app

COPY go.mod .
COPY go.sum .

RUN go mod download
RUN go mod verify

ARG VERSION

COPY . .

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
  go build -a \
  -ldflags "-w -extldflags '-static' -X main.version=$VERSION" \
  -o /go/bin/app \
  cmd/main.go

FROM scratch

COPY --from=build /etc/passwd /etc/passwd
COPY --from=build /etc/group /etc/group
COPY --from=build /go/bin/app /go/bin/app

USER appuser

CMD ["/go/bin/app"]
