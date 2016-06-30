FROM ruby:2.1.8-alpine

ARG ARTIFACT

RUN apk update && apk add build-base

WORKDIR /vivareal

RUN apk -Uuv add groff less python py-pip && \
  pip install awscli && \
  apk --purge -v del py-pip && \
  rm /var/cache/apk/*

COPY $ARTIFACT cfndsl.tar.gz 
RUN tar -zxf cfndsl.tar.gz

WORKDIR /vivareal/cfndsl
RUN bundle install

VOLUME ["/project/deploy/variables"]
VOLUME ["/project/deploy/templates"]
VOLUME ["/project/deploy/output"]
