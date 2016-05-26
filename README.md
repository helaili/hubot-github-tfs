[![Build Status](https://travis-ci.org/helaili/hubot-github-tfs.svg?branch=master)](https://travis-ci.org/helaili/hubot-github-tfs)

# hubot-github-tfs

A Hubot script to integrate GitHub and Microsoft Team Foundation Server (TFS)

See [`src/github-tfs.coffee`](src/github-tfs.coffee) for full documentation.

## Installation

In hubot project repo, run:

`npm install hubot-github-tfs --save`

Then add **hubot-github-tfs** to your `external-scripts.json`:

```json
[
  "hubot-github-tfs"
]
```

## Environment Variables

| Variable | Required/Optional | Comments |
|----------|---------|----------|
| HUBOT_TFS_SERVER|required|Ip or DNS name of the TFS server|
|HUBOT_TFS_USERNAME|required||
|HUBOT_TFS_PASSWORD|required||
|HUBOT_TFS_PROTOCOL|optional|default to `https`|
|HUBOT_TFS_PORT|optional|default to `80` for `http` and `443` for `https`|
|HUBOT_TFS_URL_PREFIX|optional|default to `/`|
|HUBOT_TFS_WORKSTATION|optional|default to `hubot`|
|HUBOT_TFS_DOMAIN|optional|default to blank|
|HUBOT_TFS_DEFAULT_COLLECTION|optional|default to `defaultcollection`|

## Sample Interaction

```
**user1**>> hubot tfs-build help
**hubot**>>Here's what I can do with TFS builds :
tfs-build list builds for <project>
tfs-build list builds for <project> from <collection>
tfs-build queue <project> with def=<definition id>
tfs-build queue <project> from <collection> with def=<definition id> branch=<branch name>
tfs-build list definitions for <project>
tfs-build list definitions for <project> from <collection>
tfs-build rem all
tfs-build rem about <org>/<repo>
tfs-build rem <org>/<repo> builds with <project>/<definition id>
tfs-build rem <org>/<repo> builds with <project>/<definition id> from <collection>



**user1**>> hubot tfs-build list SpidersFromMars
**hubot**>>
----------------------------------------------------------------------------------------
| Build       | Status   | Result  | Branch             | Definition                   |
----------------------------------------------------------------------------------------
|20160407.2   |completed |succeeded|master              |SpidersFromMars on github.com |
|20160407.1   |completed |failed   |master              |SpidersFromMars on github.com |
|20160331.19  |completed |succeeded|master              |SpidersFromMars on Octodemo   |
|20160331.18  |completed |failed   |master              |SpidersFromMars on Octodemo   |
|20160331.17  |completed |succeeded|syntaxerror         |SpidersFromMars on Octodemo   |
|20160331.16  |completed |failed   |synataxerror        |SpidersFromMars on Octodemo   |
----------------------------------------------------------------------------------------
**user1**>> hubot tfs-build list SpidersFromMars from MyCollection
...
```

