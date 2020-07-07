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

SLACK_START_EMOJI = ENV['SLACK_START_EMOJI']
SLACK_START_TEXT = ENV['SLACK_START_TEXT']
SLACK_START_EXPIRE_MINUTES = ENV['SLACK_START_EXPIRE_MINUTES']
SLACK_LUNCH_EMOJI = ENV['SLACK_LUNCH_EMOJI']
SLACK_LUNCH_TEXT = ENV['SLACK_LUNCH_TEXT']
SLACK_LUNCH_EXPIRE_MINUTES = ENV['SLACK_LUNCH_EXPIRE_MINUTES']
SLACK_FINISH_EMOJI = ENV['SLACK_FINISH_EMOJI']
SLACK_FINISH_TEXT = ENV['SLACK_FINISH_TEXT']
SLACK_FINISH_EXPIRE_MINUTES = ENV['SLACK_FINISH_EXPIRE_MINUTES']

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

# Get slack status_expiration
#
# @param minutes [Number] 0 means clear
def slack_status_expiration(minutes)
  m = minutes.to_i
  m == 0 ? 0 : (Time.now + m*60).to_i
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
    status_emoji: SLACK_START_EMOJI,
    status_text: SLACK_START_TEXT,
    status_expiration: slack_status_expiration(SLACK_START_EXPIRE_MINUTES),
  )
  # set_status_back
  jobcan_touch
when 'lunch'
  set_status(
    status_emoji: SLACK_LUNCH_EMOJI,
    status_text: SLACK_LUNCH_TEXT,
    status_expiration: slack_status_expiration(SLACK_LUNCH_EXPIRE_MINUTES),
  )
when 'finish'
  set_status(
    status_emoji: SLACK_FINISH_EMOJI,
    status_text: SLACK_FINISH_TEXT,
    status_expiration: slack_status_expiration(SLACK_FINISH_EXPIRE_MINUTES),
  )
  # set_status_away
  jobcan_touch
else
  puts 'Usage: slack.rb { start | lunch | finish }'
  exit 1
end
