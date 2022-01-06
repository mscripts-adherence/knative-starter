const fastify = require('fastify')({ logger: true })
const axios = require("axios").default;
const { HTTP, CloudEvent } = require("cloudevents");

const BROKER_URL = process.env.ADHERENCE_BROKER_URL;

let lastMessage = '';

fastify.addContentTypeParser('application/json', { parseAs: 'string' }, function (req, body, done) {
  try {
    var json = JSON.parse(body)
    done(null, json)
  } catch (err) {
    err.statusCode = 400
    done(err, undefined)
  }
})

fastify.get('/', (req, res) => {
  const target = lastMessage || process.env.TARGET || "World";
  res.send(`Hello ${target}!\n`);
});

fastify.post('/inbound', {}, handleInbound);

async function handleInbound(req, res) {
  lastMessage = JSON.stringify(req.body) + " GET";
  const target = lastMessage || process.env.TARGET || "World";

  // without a broker, just stop processing here and respond
  if(!BROKER_URL) {
    res.send(`Hello ${target}!\n`);
    return;
  }

  // otherwise, send a cloud event
  sendCloudEvent(BROKER_URL, "ack", "/knative-starter", {payload: req.body}).then((result) => {
    res.send(`Hello ${target}!\n`);
  }).catch((err) => {
    res.status(500).send(`Hello ${target}!  I had an error ${err}\n`);
  });
}

function sendCloudEvent(url, type, source, data) {
  return new Promise((resolve, reject) => {
    const message = HTTP.binary(new CloudEvent({type: type, source: source, data: data}))
    axios({
      method: "post",
      url: url,
      data: message.body,
      headers: message.headers,
    }).then((result) => {
      resolve(result); // TODO: perhaps this checks the response code, etc, and rejects accordingly
    }).catch(reject);
  })
}

const port = process.env.PORT || 8080;
const start = async () => {
  try {
    console.log('KNative starter listening on port', port);
    await fastify.listen(port)
  } catch (err) {
    fastify.log.error(err)
    process.exit(1)
  }
}
start()