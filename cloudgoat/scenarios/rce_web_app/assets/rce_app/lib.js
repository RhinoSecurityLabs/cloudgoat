function parseQueryString(queryString) {
  const params = {};
  // Split into key/value pairs
  const queries = (queryString || '').split('&');
  // Convert the array of strings into an object
  for (let i = 0; i < queries.length; i++) {
    const temp = queries[i].split('=');
    params[temp[0]] = temp[1]; // eslint-disable-line prefer-destructuring
  }
  return params;
}


function readBody(req) {
  return new Promise((resolve) => {
    if (req.method === 'POST') {
      let body = '';
      req.on('data', (chunk) => {
        body += chunk.toString(); // convert Buffer to string
      });
      req.on('end', () => {
        resolve(parseQueryString(decodeURIComponent(body.replace(/\+/g, '%20'))));
      });
    }
  });
}

module.exports = {
  readBody,
};
