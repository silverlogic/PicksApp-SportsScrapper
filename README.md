# PicksApp-SportsScrapper
[![Build Status](https://travis-ci.org/silverlogic/PicksApp-SportsScrapper.svg?branch=master)](https://travis-ci.org/silverlogic/PicksApp-SportsScrapper)

A Server Side Swift app powered by Kitura for scraping different sport leagues

## Accessing the API.
The base url of the scraper is `https://picksapp-sportsscrapper.mybluemix.net`.
There are three routes that are available:

* `/live-schedule/:leagueType/:year/:week`
* `/historical-schedule/:leagueType/:year/:week`
* `/current/:leagueType`

The `live-schedule` and `historical-schedule` routes return similiar data. Support will come for more granular data in the `live-schedule` route in the feature.

Let's explain what each path parameter means:

* `leagueType`: Represents the desired sports league. Currently only supports the NFL. For this, pass `0`.
* `year`: Represents the season in `leagueType`. When using `live-schedule`, the minimum value that can be passed is `2001`. When using `historical-schedule`, the minimum value that can be passed is `1970`.
* `week`: Represents the week in `year`. For the NFL, the value provided should be `1` to `16`.

## Requirements For Installing Locally

* Xcode 8.3.*
* Swift 3.1.*
* Swift Package Manager
* Docker

## Installation

### Docker
If you would like to run the API in a Linux environment, we recommend using Docker for running containers. Setting up Docker is simple

1. Download the Docker Community Edition For Mac at https://store.docker.com/search?type=edition&offering=community.
1. In a terminal, Install IBM's Swift Docker image by doing `$ docker pull ibmcom/swift-ubuntu:latest`.
1. Then, install the CouchBD Docker image with admin support by doing `$ docker pull couchdb`.

### Setup
Now that Docker has been setup, we can now begin setting up the repo on our local machine.

1. In a terminal, do `$ git clone git@github.com:silverlogic/PicksApp-SportsScrapper.git`.
1. Go to the root of the clone repo by doing `$ cd PicksApp-SportsScrapper`.
1. Now we need to build the dependencies by doing `$ swift build`.
1. To generate the `xcodeproj` file to open the project in Xcode, do `$ swift package generate-xcodeproj`.
1. To open the project in Xcode, do `$ open SportsScraper.xcodeproj`.

## Running The Server On Your Machine.

* When running the server locally, the base url will be `http://localhost:8080`.
* The database admin can be accessed at `http://localhost:5984/_utils`.

### Running The Server In OSX
When running the server on your local machine using OSX, you first need to start up the database. You can do that in a terminal by doing `$ docker run --name couchdb -p 5984:5984 -e COUCHDB_USER="admin" -e COUCHDB_PASSWORD="password" couchdb` when running the database for the very first time. This will start CouchDB. By default, an admin user will be set for you. If you then want to run the database again, you would do `$ docker start couchdb`. Then to stop it, do `$ docker stop couchdb`. To start the database and enabling logging, do `$ docker start couchdb -a`. Once the database is running, in Xcode, switch the scheme to `SportsScraperServer`. Then do command r to run the server.

### Running The Server In Linux
When implementing new features, you want to make sure that the implementation also works in a Linux environment, since the Foundation APIs that you would use in a Cloud Foundary application aren't fully avaliable. To test in Linux locally on your machine, access your terminal and do `$ docker-compose up`. This will start CouchDB as well as the server.

## Running Tests

### Running Tests In OSX

1. First, run the database. Refer to section `Running The Server in OSX` in the README on how to do that.
1. Then in Xcode, on the keyboard do command u.

### Running Tests In Linux

1. To run in Linux locally in your machine, access your terminal and do `$ docker-compose -f docker-test.yml up`. This will start CouchDB as well as start running tests.

## Roadmap
Here is a roadmap of features that we will like to implement overtime:

- [x] Add granualar data to `live-schedule` route
- [x] Caching of all past schedules
- [x] Travis CI setup
- [x] Implement a test suite with database interactions once caching is implemented
- [ ] Require authentication for accessing routes
