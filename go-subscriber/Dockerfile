###########
# BUILDER #
###########
FROM golang:1.18-buster AS build

WORKDIR /app

COPY go.mod ./
COPY go.sum ./
RUN go mod download

COPY *.go ./

RUN go build -o /go-subscriber

#########
# FINAL #
#########
FROM gcr.io/distroless/base-debian11

WORKDIR /

COPY --from=build /go-subscriber /go-subscriber

USER nonroot:nonroot

CMD [ "./go-subscriber" ]