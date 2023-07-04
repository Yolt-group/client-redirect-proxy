FROM nginx:1.23 as build-env
RUN apt update
RUN apt -y install build-essential
WORKDIR /app
COPY prometheus-exporter.c .
RUN cc -o prometheus-exporter prometheus-exporter.c

FROM nginx:1.23
WORKDIR /home/yolt
COPY --from=build-env /app/prometheus-exporter .
COPY nginx-with-prometheus.sh .
COPY stderr-wrapper.sh .
RUN chown -R 100:1000 /home/yolt

COPY client-redirect.html /usr/share/nginx/html/
COPY nginx.conf /etc/nginx/nginx.conf
CMD ["/bin/bash", "/home/yolt/nginx-with-prometheus.sh"]
