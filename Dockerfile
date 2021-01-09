FROM php:7.4.14-cli-alpine

RUN apk update && apk add curl && \
  curl -sS https://getcomposer.org/installer | php \
  && chmod +x composer.phar && mv composer.phar /usr/local/bin/composer

RUN set -eux; \
	\
	apk add --no-cache --virtual .build-deps \
		libzip-dev \
		libxml2-dev \
	; \
	\
	apk add --no-cache $PHPIZE_DEPS \
	; \
	\
	docker-php-ext-install -j "$(nproc)" \
		soap \
	; \
	\
	runDeps="$( \
		scanelf --needed --nobanner --format '%n#p' --recursive /usr/local \
			| tr ',' '\n' \
			| sort -u \
			| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
	)"; \
	apk add --virtual .drupal-phpexts-rundeps $runDeps; \
	apk del .build-deps $PHPIZE_DEPS

WORKDIR /app

COPY composer.json ./
RUN composer install --no-scripts --no-autoloader

CMD /bin/sh -c "composer install;cd /tmp;/app/vendor/bin/soap-client wizard"
