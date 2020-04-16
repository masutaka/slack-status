#!/usr/bin/env ruby

require 'net/http'
require 'json'

command = ARGV[0]
if command.nil?
  puts 'Usage: slack.rb { start | lunch | finish }'
  exit 1
end

slack_url = ENV['SLACK_URL']
if slack_url.nil?
  puts 'SLACK_URL must be defined in the environment'
  exit 1
end

token = ENV['SLACK_TOKEN']
if token.nil?
  puts 'SLACK_TOKEN must be defined in the environment'
  exit 1
end

SLACK_FINISH_TEXT = ENV['SLACK_FINISH_TEXT']

JOBCAN_CHANNEL_ID = ENV['JOBCAN_CHANNEL_ID']
if JOBCAN_CHANNEL_ID.nil?
  puts 'JOBCAN_CHANNEL_ID must be defined in the environment'
  exit 1
end

SLACK_API_ROOT="#{slack_url}/api"

SET_PROFILE_URL = "#{SLACK_API_ROOT}/users.profile.set?token=#{token}"
AWAY_URL = "#{SLACK_API_ROOT}/users.setPresence?presence=away&token=#{token}"
BACK_URL = "#{SLACK_API_ROOT}/users.setPresence?presence=auto&token=#{token}"

# Undocumented API
# See https://github.com/slack-ruby/slack-api-ref/blob/master/methods/undocumented/chat/chat.command.json
CHAT_COMMAND_URL = "#{SLACK_API_ROOT}/chat.command?token=#{token}"

def set_status(profile)
  Net::HTTP.post_form(URI.parse(SET_PROFILE_URL), profile: profile.to_json)
end

def set_status_back
  Net::HTTP.post_form(URI.parse(BACK_URL), {})
end

def set_status_away
  Net::HTTP.post_form(URI.parse(AWAY_URL), {})
end

def jobcan_touch
  Net::HTTP.post_form(
    URI.parse(CHAT_COMMAND_URL),
    channel: JOBCAN_CHANNEL_ID, # It's NOT channel name.
    command: '/jobcan_touch',
    as_user: true,
  )
end

case ARGV[0]
when 'start'
  set_status(
    status_emoji: '',
    status_text: '',
    status_expiration: 0, # clear
  )
  # set_status_back
  jobcan_touch
when 'lunch'
  set_status(
    status_emoji: ':lunch:',
    status_text: '',
    status_expiration: (Time.now + 1*60*60).to_i, # add 1 hour
  )
when 'finish'
  set_status(
    status_emoji: ':taisya:',
    status_text: SLACK_FINISH_TEXT,
    status_expiration: 0, # clear
  )
  # set_status_away
  jobcan_touch
else
  puts 'Usage: slack.rb { start | lunch | finish }'
  exit 1
end
