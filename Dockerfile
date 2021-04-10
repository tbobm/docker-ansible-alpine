FROM alpine:3.13 as builder

ARG ANSIBLE_VERSION=3.10
ARG PYTHON_VERSION=3.8

LABEL maintainer="Theo Bob Massard <tbobm+github@protonmail.com>"

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
    PYTHONPATH="${PYTHONPATH}/app/lib/python${PYTHON_VERSION}"

RUN pip install --upgrade --no-cache-dir pip wheel \
    && pip install --prefix /app --no-cache-dir --upgrade cffi \
    && pip install --prefix /app --no-cache-dir ansible

FROM alpine:3.13 as release

RUN apk update && apk add --no-cache git \
        openssh-client openssl rsync sshpass \
        which gettext python3-dev py3-pip

RUN mkdir /app && addgroup -S ansible && adduser -S ansible -G ansible -h /app
COPY --from=builder /app /app/

USER ansible
WORKDIR /app
ARG PYTHON_VERSION=3.8
ENV PATH="/app/bin:${PATH}" \
    PYTHONPATH="${PYTHONPATH}/app/lib/python${PYTHON_VERSION}/site-packages"

