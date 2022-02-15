FROM debian
RUN apt-get update && apt-get install -y --no-install-recommends nginx ca-certificates && apt-get clean
COPY ca/michalCA.pem /usr/local/share/ca-certificates/michalCA.crt
RUN chmod 644 /usr/local/share/ca-certificates/michalCA.crt && update-ca-certificates
EXPOSE 443
STOPSIGNAL SIGTERM
CMD ["nginx", "-g", "daemon off;"]
