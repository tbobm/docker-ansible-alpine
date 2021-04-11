FROM alpine:3.13 as builder

LABEL maintainer="Theo Bob Massard <tbobm+github@protonmail.com>"

ENV PIP_DISABLE_PIP_VERSION_CHECK=1
ENV PIP_NO_CACHE_DIR=1

ARG ANSIBLE_VERSION=3.10
ARG PYTHON_VERSION=3.8

# Install build dependencies
RUN apk update && apk add --no-cache git \
        openssh-client openssl rsync sshpass \
        which gettext gcc musl-dev libffi-dev \
        openssl-dev cargo \
    && apk add --update --no-cache --virtual \
        builddeps libffi-dev \
        openssl-dev build-base \
    && apk add --no-cache python3-dev~=${PYTHON_VERSION} \
        py3-pip

ENV PATH="/app/bin:${PATH}" \
    PYTHONPATH="${PYTHONPATH}:/app/lib/python${PYTHON_VERSION}/site-packages"

# Install python packages
RUN pip install --upgrade pip wheel \
    && pip install --prefix /app --upgrade cffi \
    && pip install --prefix /app ansible

# Ensure ansible setup is valid
COPY examples /tests
WORKDIR /tests
RUN ansible --version \
    && ansible-galaxy install -r /tests/requirements.yml \
    && ansible-playbook -i /tests/inventory/ /tests/playbook.yml

# Runtime image
FROM alpine:3.13 as release

ARG PYTHON_VERSION=3.8

ENV PATH="/app/bin:${PATH}" \
    PYTHONPATH="${PYTHONPATH}:/app/lib/python${PYTHON_VERSION}/site-packages"

# Repeat required ansible dependencies
RUN apk update && apk add --no-cache git openssh-client openssl \
        rsync sshpass which gettext python3-dev~=${PYTHON_VERSION} py3-pip

RUN mkdir /app && addgroup -S ansible && adduser -S ansible -G ansible -h /app

COPY --from=builder --chown=ansible:ansible /app /app/

USER ansible
WORKDIR /app

