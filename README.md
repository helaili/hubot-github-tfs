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
