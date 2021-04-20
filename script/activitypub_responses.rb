# Send back responses to some things that are automatic, like follow requests

require File.dirname(__FILE__)+'/cron_helper'

include ActivityPub

respond_to_follow