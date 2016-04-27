# https://docs.docker.com/engine/security/https/
# http://crohr.me/journal/2014/generate-self-signed-ssl-certificate-without-prompt-noninteractive-mode.html

openssl genrsa -aes256 -passout pass:x -out ca-key.pass.pem 4096
openssl rsa -passin pass:x -in ca-key.pass.pem -out ca-key.pem
openssl req -new -key ca-key.pem -out server.csr -subj "/C=NL/ST=Zuid-Holland/L=Delft/O=TU Delft/OU=Devhub/CN=devhub.ewi.tudelft.nl"
openssl req -x509 -days 365 -in server.csr -key ca-key.pem -sha256 -out ca.pem

openssl genrsa -out server-key.pem 4096
openssl req -subj "/CN=localhost" -sha256 -new -key server-key.pem -out server.csr

echo subjectAltName = IP:10.10.10.20,IP:127.0.0.1 > extfile.cnf
openssl x509 -req -days 365 -sha256 -in server.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out server-cert.pem -extfile extfile.cnf

openssl genrsa -out key.pem 4096
openssl req -subj '/CN=client' -new -key key.pem -out client.csr
echo extendedKeyUsage = clientAuth > extfile.cnf
openssl x509 -req -days 365 -sha256 -in client.csr -CA ca.pem -CAkey ca-key.pem  -CAcreateserial -out cert.pem -extfile extfile.cnf
