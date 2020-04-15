#!/usr/bin/env ruby

require 'net/http'
require 'json'

command = ARGV[0]
if command.nil?
  puts 'Usage: slack.rb {start | lunch | finish }'
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

SLACK_API_ROOT="#{slack_url}/api"

SET_PROFILE_URL = "#{SLACK_API_ROOT}/users.profile.set?token=#{token}"
AWAY_URL = "#{SLACK_API_ROOT}/users.setPresence?presence=away&token=#{token}"
BACK_URL = "#{SLACK_API_ROOT}/users.setPresence?presence=auto&token=#{token}"

def set_status(profile)
  Net::HTTP.post_form(URI.parse(SET_PROFILE_URL), profile: profile.to_json)
end

def set_status_back
  Net::HTTP.post_form(URI.parse(BACK_URL), {})
end

def set_status_away
  Net::HTTP.post_form(URI.parse(AWAY_URL), {})
end

case ARGV[0]
when 'start'
  set_status(
    status_emoji: '',
    status_text: '',
    status_expiration: 0, # clear
  )
  set_status_back
when 'lunch'
  set_status(
    status_emoji: ':lunch:',
    status_text: '',
    status_expiration: (Time.now + 1*60*60).to_i, # add 1 hour
  )
when 'finish'
  set_status(
    status_emoji: ':taisya:',
    status_text: '準備中',
    status_expiration: 0, # clear
  )
  set_status_away
else
  puts 'Usage: slack.rb {start | lunch | finish }'
  exit 1
end
