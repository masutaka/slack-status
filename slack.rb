#!/usr/bin/env ruby

require 'net/http'
require 'json'

command = ARGV[0]
if command.nil?
  puts 'Usage: slack.rb { start | lunch | finish | jobcan_touch }'
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

SLACK_API_ROOT = "#{slack_url}/api"
SLACK_SET_PROFILE_URL = "#{SLACK_API_ROOT}/users.profile.set?token=#{token}"
SLACK_SET_DND_URL = "#{SLACK_API_ROOT}/dnd.setSnooze?token=#{token}"

# Undocumented API
# See https://github.com/slack-ruby/slack-api-ref/blob/master/methods/undocumented/chat/chat.command.json
SLACK_CHAT_COMMAND_URL = "#{SLACK_API_ROOT}/chat.command?token=#{token}"

def slack_set_status(profile)
  Net::HTTP.post_form(URI.parse(SLACK_SET_PROFILE_URL), profile: profile.to_json)
end

# Get slack status_expiration
#
# @param now [Time]
# @param minutes [Number] 0 means clear
def slack_status_expiration(now, minutes)
  m = minutes.to_i
  m == 0 ? 0 : (now + m*60).to_i
end

# Set DND until AM9:00 on tomorrow
#
# @param now [Time]
def slack_set_dnd(now)
  target = (now.to_date + 1).to_time + 9*60*60 # AM9:00 on tomorrow
  num_minutes = ((target - now) / 60).to_i     # sub minutes
  Net::HTTP.post_form(URI.parse(SLACK_SET_DND_URL), num_minutes: num_minutes)
end

def jobcan_touch
  Net::HTTP.post_form(
    URI.parse(SLACK_CHAT_COMMAND_URL),
    channel: JOBCAN_CHANNEL_ID, # It's NOT channel name.
    command: '/jobcan_touch',
    as_user: true,
  )
end

now = Time.now

case ARGV[0]
when 'start'
  slack_set_status(
    status_emoji: SLACK_START_EMOJI,
    status_text: SLACK_START_TEXT,
    status_expiration: slack_status_expiration(now, SLACK_START_EXPIRE_MINUTES),
  )
  jobcan_touch
when 'lunch'
  slack_set_status(
    status_emoji: SLACK_LUNCH_EMOJI,
    status_text: SLACK_LUNCH_TEXT,
    status_expiration: slack_status_expiration(now, SLACK_LUNCH_EXPIRE_MINUTES),
  )
when 'finish'
  slack_set_status(
    status_emoji: SLACK_FINISH_EMOJI,
    status_text: SLACK_FINISH_TEXT,
    status_expiration: slack_status_expiration(now, SLACK_FINISH_EXPIRE_MINUTES),
  )
  slack_set_dnd(now)
  jobcan_touch
when 'jobcan_touch'
  jobcan_touch
else
  puts 'Usage: slack.rb { start | lunch | finish | jobcan_touch }'
  exit 1
end
