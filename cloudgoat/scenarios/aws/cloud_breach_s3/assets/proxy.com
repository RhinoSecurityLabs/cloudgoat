server {
        listen 80 default_server;
        if ($host != "169.254.169.254") {
          return 400 "<h1>This server is configured to proxy requests to the EC2 metadata service. Please modify your request's 'host' header and try again.</h1>";
        }
        location / {
                proxy_pass  http://$host;
        }
}