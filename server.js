
var http = require('http'),
    httpProxy = require('http-proxy');

//
// Create a proxy server and set the target in the options.
// Kibana will eventually come up on port 9000
//
var proxy = httpProxy.createProxyServer({
    target:'http://localhost:9000'
  }).listen(process.env.PORT || 8080);

// Handle it if kibana isn't up yet.  This is so that the
// healthcheck won't be sad even though kibana takes so long
// to launch.
proxy.on('error', function (err, req, res) {
  res.writeHead(204, {
    'Content-Type': 'text/plain'
  });

  res.end('Kibana is not up yet.');
});

