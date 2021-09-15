# Load generation with Heroku

This loadgen project is designed to drive traffic over the 'voteapp' that is deployed onto a K8 cluster.

## Create a free heroku account

Go to Heroku and create a free account!

https://www.heroku.com/free

## Add URLs to drive traffic over

Open the 'loadgen.js' file in an text editor and update the 'RESULT_URLS' and 'VOTE_URLS'.

Example:
    const RESULT_URLS = {
      "google": "http://google.com"
    };

## Setup git for pushing to Heroku

    git init
    git add .
    git commit -m "First commit"

## Deploy this project to Heroku

If this is the first time you have used Heroku you will be prompted to authenticate.  Copy the link provided into a browser and login Heroku.

    heroku create load-driver --remote load-driver
    git push --set-upstream load-driver main
    heroku ps:scale web=0 worker=1 --remote load-driver

## View the Heroku log to make sure it is working

   heroku logs --remote load-driver -t

