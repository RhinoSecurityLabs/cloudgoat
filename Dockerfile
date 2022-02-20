FROM hashicorp/terraform:0.15.1

LABEL maintainer="Rhino Assessment Team <cloudgoat@rhinosecuritylabs.com>"
LABEL cloudgoat.version="2.0.0"

RUN apk add --no-cache --update bash bash-completion docker-bash-completion openssh curl

# Install AWS CLI
RUN apk update && apk add python3 py3-pip && \
	pip3 install awscli --upgrade

# Install CloudGoat
WORKDIR /usr/src/cloudgoat/core/python
COPY ./core/python/requirements.txt ./
RUN pip3 install -r ./requirements.txt

WORKDIR /usr/src/cloudgoat/
COPY ./ ./

ENTRYPOINT ["/bin/bash", "-c"]
CMD ["bash", "-l"]
