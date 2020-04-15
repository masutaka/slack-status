# slack-status

A ruby script to set my slack status, including an optional "away" message.

I used https://github.com/rydama/slack-status as a great reference.

## Usage

```
$ ./slack.rb
Usage: slack.rb {start | lunch | finish }
```

## Installation

First, get your slack api token [here](https://api.slack.com/docs/oauth-test-tokens)

Example setup using [direnv](https://github.com/direnv/direnv):

```
$ cat .envrc
export SLACK_URL='https://example.slack.com/'
export SLACK_TOKEN='YOUR-SLACK-TOKEN'

# Add to ~/.zshrc
$ alias slack-status='direnv exec /path/to/slack-status /path/to/slack-status/slack.rb'

$ slack-status start
$ slack-status lunch
$ slack-status finish
```
