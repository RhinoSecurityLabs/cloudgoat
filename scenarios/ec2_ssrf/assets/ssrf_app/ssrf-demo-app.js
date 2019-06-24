//////////////////////////////////////////
// SSRF Demo App
// Node.js Application Vulnerable to SSRF
// Written by Seth Art <sethsec@gmail.com>
// MIT Licensed
//////////////////////////////////////////

var http = require('http');
var needle = require('needle');
var express = require('express');
var app = express();
var commandLineArgs = require('command-line-args');

// Currently this app is also vulnerable to reflective XSS as well. Kind of an easter egg :)

var cli = [
  { name: 'port', alias: 'p', type: Number, defaultOption:80 }
]
var options = commandLineArgs(cli)

app.get('/', function(request, response){
    var params = request.params;
    var url = request.query['url'];
    if (request.query['mime'] == 'plain'){
	var mime = 'plain';
    } else {
	var mime = 'html';
    };

    console.log('New request: '+request.url);

    needle.get(url, { timeout: 3000 }, function(error, response1) {
      if (!error && response1.statusCode == 200) {
        response.writeHead(200, {'Content-Type': 'text/'+mime});
        response.write('<h1>Welcome to sethsec\'s SSRF demo.</h1>\n\n');
        response.write('<h2>I am an application. I want to be useful, so I requested: <font color="red">'+url+'</font> for you\n</h2><br><br>\n\n\n');
        console.log(response1.body);
        response.write(response1.body);
        response.end();
      } else {
        response.writeHead(404, {'Content-Type': 'text/'+mime});
        response.write('<h1>Welcome to sethsec\'s SSRF demo.</h1>\n\n');
        response.write('<h2>I wanted to be useful, but I could not find: <font color="red">'+url+'</font> for you\n</h2><br><br>\n\n\n');
        response.end();
        console.log('error')

      }
    });
})
if (options.port) {
	var port = options.port
} else {
	var port = 80
}

app.listen(port);
console.log('\n##################################################')
console.log('#\n#  Server listening for connections on port:'+port);
console.log('#  Connect to server using the following url: \n#  -- http://[server]:'+port+'/?url=[SSRF URL]')
console.log('#\n##################################################')
