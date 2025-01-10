// Indefinitely invokes calls to the vote and result applications

var tiny = require('tiny-json-http')
const fs = require('fs');

const INTERVAL = 10000; // poll each service once every INTERVAL milliseconds


// Each of the URLS hashes can have multiple entries
// Example:
// { 'GCP': 'http://ip.address:port', 'AZURE': 'http://ip.address:port' }
const RESULT_URLS = loadJson('result_urls.json');
const VOTE_URLS = loadJson('vote_urls.json');

console.log("Starting up...")

function loadJson(file_name) {
  let raw_data = fs.readFileSync(file_name);
  let json_data = JSON.parse(raw_data);
  return json_data;
}

function loadResults() {
  for (const [cloud, url] of Object.entries(RESULT_URLS)) {
    getResults(cloud, url);
  }
}

function getResults(cloud, url) {
  tiny.get({url}, function _get(err, result) {
    if (err) {
      console.log(err)
    }
    else {
      console.log('Loaded results for ' + cloud + '!');
    }
  })
}

function sendVote() {
  for (const [cloud, url] of Object.entries(VOTE_URLS)) {
    postVote(cloud, url);
  }
}

function postVote(cloud, url){
 const randomNum = Math.floor(Math.random() * 10) + 1;
 const vote = (randomNum % 2 == 0) ? 'a' : 'b';
 const data = {"vote":vote};
 const headers = { 'content-type': 'application/x-www-form-urlencoded' }


 tiny.post({url, data, headers}, function __posted(err, result) {
    if (err) {
      return console.error('Vote POST failed for ' + cloud + ': ', err);
    }
    else {
      console.log('Successfully voted on ' + cloud + ' for ' + vote);
    }
  })
}

setInterval(() => {
    loadResults();
}, INTERVAL);

setInterval(() => {
    sendVote();
}, INTERVAL);