// Indefinitely invokes calls to the vote and result applications

const request = require('request');

const INTERVAL = 10000; // poll each service once every INTERVAL milliseconds


// Each of the URLS hashes can have multiple entries
// Example:
// { 'GCP': 'http://ip.address:port', 'AZURE': 'http://ip.address:port' }
const RESULT_URLS = {
  "google": "http://google.com"
};
const VOTE_URLS = {};

console.log("Starting up...")

function loadResults() {
  for (const [cloud, url] of Object.entries(RESULT_URLS)) {
    getResults(cloud, url);
  }
}

function getResults(cloud, url) {
 request(url, { }, (err, res, body) => {
  if (err) { return console.log(err); }
  console.log('Loaded results for ' + cloud + '!');
 });
}

function sendVote() {
  for (const [cloud, url] of Object.entries(VOTE_URLS)) {
    postVote(cloud, url);
  }
}

function postVote(cloud, url){
 const randomNum = Math.floor(Math.random() * 10) + 1;
 const vote = (randomNum % 2 == 0) ? 'a' : 'b';
 const formData = { vote: vote };

 request.post({url: url, formData: formData}, function callback(err, httpResponse, body) {
  if (err) {
    return console.error('Vote POST failed for ' + cloud + ': ', err);
  }
  console.log('Successfully voted on ' + cloud + ' for ' + vote);
 });
}

setInterval(() => {
    loadResults();
}, INTERVAL);

setInterval(() => {
    sendVote();
}, INTERVAL);