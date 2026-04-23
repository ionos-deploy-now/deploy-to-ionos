FROM alpine:3.23

COPY pkg/*.gem /tmp/

RUN set -x \
	&& apk add --no-cache ruby rsync openssh-client sshpass \
	&& apk add --no-cache --virtual=build-dependencies build-base ruby-dev \
  && gem install --no-document /tmp/*.gem \
  && apk del build-dependencies \
  && rm -rf /tmp/* /var/tmp/* /usr/lib/ruby/gems/*/cache/*.gem

ENTRYPOINT ["/usr/bin/deploy-to-ionos"]
