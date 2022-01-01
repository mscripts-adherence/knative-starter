const express = require('express');
const app = express();
const bodyParser = require('body-parser')

let lastMessage = '';

app.use(bodyParser());

app.get('/', (req, res) => {
  console.log('Hello world received a request.');

  const target = lastMessage || process.env.TARGET || "World";
  res.send(`Hello ${target}!\n`);
});

app.get('/inbound', (req, res) => {
  lastMessage = JSON.stringify(req.body);
  const target = lastMessage || process.env.TARGET || "World";
  res.send(`Hello ${target}!\n`);
});

app.post('/inbound', (req, res) => {
  lastMessage = JSON.stringify(req.body);
  const target = lastMessage || process.env.TARGET || "World";
  res.send(`Hello ${target}!\n`);
});

const port = process.env.PORT || 8080;
app.listen(port, () => {
  console.log('Hello world listening on port', port);
});