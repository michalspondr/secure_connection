# secure_connection
This is a test project for learning how to set up a secure communication. It runs a web server as Docker service.

# Prerequisites
- Linux
- openssl
- docker and docker-compose

# Steps
## Create Certificate Authority
Inspired by (https://deliciousbrains.com/ssl-certificate-authority-for-local-https-development/)

Create directory for certificates:
```
mkdir ca
cd ca
```

Generate private key to become local CA. Prompted for password.
```
openssl genrsa -des3 -out michalCA.key 2048
```
michalCA.key file (PEM RSA private key) is generated.

Now generate root certificate itself.
```
openssl req -x509 -new -nodes -key michalCA.key -sha256 -days 1825 -out michalCA.pem

```
PEM certificate michalCA.pem has been created.

This certificate has to be installed on *all devices* where you need the secure communication. For that install ca-certificates:
```
sudo apt-get install -y ca-certificates
```
and copy the CA to /usr/local/share/ca-certificates/ with .crt suffix.
```
sudo cp michalCA.pem /usr/local/share/ca-certificates/michalCA.crt
```
then update certificates
```
sudo update-ca-certificates
```
You should see something like _Adding debian:michalCA.pem_ in the output.

## Webserver with own certificates
Now I want to create web server (based on nginx) that can be accessed via HTTPS only. For that I need CA-signed certificate.
```
mkdir ../certs
cd ../certs
openssl genrsa -out site.key 2048
```
Create a web servers certificate request
```
openssl req -new -key site.key -out site.csr
```
site.csr file is created.

Finally, create an X509 V3 certificate extension config file, which is used to define the [Subject Alternative Name (SAN)](https://www.digicert.com/faq/subject-alternative-name.htm) for the certificate. Content of such file is in _site.ext_.

Then create the certificate using our certificate request (CSR), certificate authority (CA), CA private key and the config file:
```
openssl x509 -req -in site.csr -CA ../ca/michalCA.pem -CAkey ../ca/michalCA.key -CAcreateserial -out site.crt -days 825 -sha256 -extfile site.ext
```

After that we have 3 files:
1. site.key -- a private key
2. site.csr -- a certificate signing request
3. site.crt -- the signed certificate

Now we can configure local web server to use HTTPS with the private key and the signed certificate.

## nginx web with HTTPS
### nginx.conf
These lines in http.server section enable SSL connection:
```
        listen 443 ssl default_server;
        listen [::]:443 ssl default_server;
        ssl_certificate /etc/nginx/certs/site.crt;
        ssl_certificate_key /etc/nginx/certs/site.key;
```
### Dockerfile
Dockerfile contains Debian and nginx installation (of course you can use nginx Docker image, but I haven tested it). It also installs ca-certificates and adds custom CA.
### docker-compose.yml
Simply runs the web server by typing:
```
docker-compose up
```
or rebuild the image by typing:
```
docker-compose build
```
To stop the service you need to type:
```
docker-compose down
```

## Result
To visit the page you'll need to find IP address of your Docker container (see _ip addr show_ and look for docker0 interface.
```
LC_ALL=C wget https://172.17.0.1
--2022-02-15 15:43:43--  https://172.17.0.1/
Connecting to 172.17.0.1:443... connected.
    ERROR: certificate common name 'site' doesn't match requested host name '172.17.0.1'.
To connect to 172.17.0.1 insecurely, use `--no-check-certificate'.
```
or
```
curl https://172.17.0.1
curl: (60) SSL: no alternative certificate subject name matches target host name '172.17.0.1'
More details here: https://curl.haxx.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.
```
Firefox stops with SEC\_ERROR\_UNKNOWN\_ISSUER warning.

# TODO
- How to avoid SEC\_ERROR\_UNKNOWN\_ISSUER?

