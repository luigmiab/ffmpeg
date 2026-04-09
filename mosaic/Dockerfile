FROM jrottenberg/ffmpeg:8.0-alpine320

RUN apk add --no-cache nginx bash

RUN mkdir -p /output/mosaic && mkdir -p /var/lib/nginx/tmp && mkdir -p /run/nginx

COPY nginx.conf /etc/nginx/nginx.conf
COPY mosaic.sh /mosaic.sh
COPY start.sh /start.sh
RUN chmod +x /mosaic.sh /start.sh

EXPOSE 8080

ENTRYPOINT ["/start.sh"]
