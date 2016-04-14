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
hubot>> hello!
user1>> hubot tfs build list SpidersFromMars from MyCollection
hubot>> hello!
```
