const express = require('express');
const app = express();
const bodyParser = require('body-parser');
const axios = require("axios").default;
const { HTTP, CloudEvent } = require("cloudevents");

const BROKER_URL = process.env.ADHERENCE_BROKER_URL

// TODO: switch to fastify from express

let lastMessage = '';

app.use(bodyParser());

app.get('/', (req, res) => {
  console.log('Hello world received a request.');

  const target = lastMessage || process.env.TARGET || "World";
  res.send(`Hello ${target}!\n`);
});

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

app.get('/inbound', (req, res) => {
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
});

app.post('/inbound', (req, res) => {
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
});

const port = process.env.PORT || 8080;
app.listen(port, () => {
  console.log('Hello world listening on port', port);
});