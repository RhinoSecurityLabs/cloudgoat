//////////////////////////////////////////
// SSRF Demo App
// Node.js Application Vulnerable to SSRF
// Written by Seth Art <sethsec@gmail.com>
// MIT Licensed
//////////////////////////////////////////

var needle = require('needle');
var express = require('express');

// Currently this app is also vulnerable to reflective XSS as well. Kind of an easter egg :)

var app = express();
var port = 80

app.get('/', function (request, response) {
  var url = request.query['url'];
  if (request.query['mime'] == 'plain') {
    var mime = 'plain';
  } else {
    var mime = 'html';
  };

  console.log('New request: ' + request.url);

  // If the URL is not set, then we will just return the default page.
  if (url == undefined) {
    response.writeHead(200, { 'Content-Type': 'text/' + mime });
    response.write('<h1>Welcome to sethsec\'s SSRF demo.</h1>\n\n');
    response.write('<h2>I am an application. I want to be useful, so give me a URL to requested for you\n</h2><br><br>\n\n\n');
    response.end();
  } else { // If the URL is set, then we will try to request it.
    needle.get(url, { timeout: 3000 }, function (error, response1) {
      // If the request is successful, then we will return the response to the user.
      if (!error && response1.statusCode == 200) {
        response.writeHead(200, { 'Content-Type': 'text/' + mime });
        response.write('<h1>Welcome to sethsec\'s SSRF demo.</h1>\n\n');
        response.write('<h2>I am an application. I want to be useful, so I requested: <font color="red">' + url + '</font> for you\n</h2><br><br>\n\n\n');
        console.log(response1.body);
        response.write(response1.body);
        response.end();
      } else { // If the request is not successful, then we will return an error to the user.
        response.writeHead(404, { 'Content-Type': 'text/' + mime });
        response.write('<h1>Welcome to sethsec\'s SSRF demo.</h1>\n\n');
        response.write('<h2>I wanted to be useful, but I could not find: <font color="red">' + url + '</font> for you\n</h2><br><br>\n\n\n');
        response.end();
        console.log(error)
      }
    });
  }
})

app.listen(port);

console.log('\n##################################################')
console.log('#\n#  Server listening for connections on port:' + port);
console.log('#  Connect to server using the following url: \n#  -- http://[server]:' + port + '/?url=[SSRF URL]')
console.log('#\n##################################################')
