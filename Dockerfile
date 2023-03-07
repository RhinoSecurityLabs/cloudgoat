FROM python:3.8-alpine

LABEL maintainer="Rhino Assessment Team <cloudgoat@rhinosecuritylabs.com>"
LABEL cloudgoat.version="2.0.0"

RUN apk add --no-cache --update bash bash-completion docker-bash-completion openssh curl

# Install Terraform and AWS CLI
RUN wget -O terraform.zip 'https://releases.hashicorp.com/terraform/1.3.9/terraform_1.3.9_linux_arm64.zip' \
    && unzip terraform.zip \
    && rm terraform.zip \
    && mv ./terraform /usr/bin/ \
    && pip3 install awscli --upgrade

# Install CloudGoat
WORKDIR /usr/src/cloudgoat/core/python
COPY ./requirements.txt ./
RUN pip3 install -r ./requirements.txt

WORKDIR /usr/src/cloudgoat/
COPY ./ ./

ENTRYPOINT ["/bin/bash"]
