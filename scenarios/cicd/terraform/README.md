## Intro

FooCorp is a company exposing a public-facing API. Customers of FooCorp submit sensitive data to the API every minute to the following API endpoint:

```
POST {apiUrl}/prod/hello
Host: {apiHost}
Content-Type: text/html

superSecretData=...
```

The goal of the attack is to retrieve the sensitive data submitted by customers.

Notes:
- The API is implemented as a Lambda function, exposed through an API Gateway. 
- FooCorp implements DevOps, and as such has a CD pipeline automatically deploying new versions of their Lambda function from source code
- Simulated user activity is taking place. This is implemented through a CodeBuild project running every minute and simulating customers requests to the API. This project is out of scope.