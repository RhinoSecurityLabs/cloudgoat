FROM python:3.12-alpine

LABEL maintainer="Rhino Assessment Team <cloudgoat@rhinosecuritylabs.com>"
LABEL cloudgoat.version="2.0.0"

RUN apk add --no-cache --update bash bash-completion docker-bash-completion openssh curl

# Install Terraform and AWS CLI
RUN wget -O terraform.zip 'https://releases.hashicorp.com/terraform/1.10.0/terraform_1.10.0_linux_arm64.zip' \
    && unzip terraform.zip \
    && rm terraform.zip \
    && mv ./terraform /usr/bin/ \
    && pip3 install awscli --upgrade

# Install CloudGoat
WORKDIR /usr/src/cloudgoat/
COPY ./ ./
RUN pip3 install .

ENTRYPOINT ["/bin/bash"]
