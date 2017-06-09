# PicksApp-SportsScrapper
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

1. Download the Docker Community Edition For Mac at https://store.docker.com/search?type=edition&offering=community
1. In a terminal, Install IBM's Swift Docker image by doing `$ docker pull ibmcom/swift-ubuntu:latest`

### Setup
Now that Docker has been setup, we can now begin setting up the repo on our local machine.

1. In a terminal, do `$ git clone git@github.com:silverlogic/PicksApp-SportsScrapper.git`.
1. Go to the root of the clone repo by doing `$ cd PicksApp-SportsScrapper`.
1. Now we need to build the dependencies by doing `$ swift build`.
1. To generate the `xcodeproj` file to open the project in Xcode, do `$ swift package generate-xcodeproj`.
1. To open the project in Xcode, do `$ open SportsScraper.xcodeproj`.

## Running Locally.
When running locally, the base url will be `http://localhost:8080`.

### Xcode
Clicking on the play button in Xcode run the project.

### Docker
In the terminal, do `$ docker-compose up`.

## Roadmap
Here is a roadmap of features that we will like to implement overtime:

- [ ] Add granualar data to `live-schedule` route
- [ ] Caching of all past schedules
- [ ] Travis CI setup
- [ ] Implement a test suite with database interactions once caching is implemented
- [ ] Require authentication for accessing routes
