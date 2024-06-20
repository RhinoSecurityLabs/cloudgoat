FROM php:7.4-cli-alpine

RUN apk --no-cache update \
    && apk --no-cache add \
    curl-dev libcurl \
    groff \
    less \
    python3 \
    py3-pip \
    && docker-php-ext-install curl \
    && pip3 install --upgrade pip \
    && pip3 install awscli

COPY . /usr/src/myapp

WORKDIR /usr/src/myapp

CMD [ "php", "-S", "0.0.0.0:80", "-t", "." ]
