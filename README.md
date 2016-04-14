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
user1>> hubot tfs build list SpidersFromMars
hubot>>
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
user1>> hubot tfs build list SpidersFromMars from MyCollection
...
```
