FROM golang:1.16.4-alpine

RUN apk add --update docker openrc curl python3
RUN rc-update add docker boot



# # Set necessary environmet variables needed for our image
ENV GO111MODULE=on \
    CGO_ENABLED=0 \
    GOOS=linux \
    GOARCH=amd64

# # Move to working directory /build
WORKDIR /build

# # Copy and download dependency using go mod
COPY go.mod .
COPY go.sum .
RUN go mod download

# # Copy the code into the container
COPY ./ .

# # Build the applicatio
RUN go build -o main .

# # Export necessary port
EXPOSE 80

# # Command to run when starting the container
CMD ["./main"]