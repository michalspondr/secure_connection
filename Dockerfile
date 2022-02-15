FROM debian
RUN apt-get update && apt-get install -y --no-install-recommends nginx ca-certificates && apt-get clean
COPY ca/michalCA.pem /usr/local/share/ca-certificates/
RUN update-ca-certificates
EXPOSE 443
STOPSIGNAL SIGTERM
CMD ["nginx", "-g", "daemon off;"]
