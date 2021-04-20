require File.dirname(__FILE__) + '/../config/environment'

include ApplicationHelper
include ActionView::Helpers::TextHelper
def helper
  @helper_proxy ||= Object.new
end
helper.extend ApplicationHelper
helper.extend ActionView::Helpers::TextHelper

# This is to make logger redirect to the console
logger                                         = Logger.new(STDOUT)
logger.level                                   = Logger::DEBUG
RAILS_DEFAULT_LOGGER                           = logger
ActiveRecord::Base.logger                      = logger
ActionController::Base.logger                  = logger
#ActiveSupport::Cache::MemCacheStore.logger     = logger
ApplicationController.allow_forgery_protection = false
#reload!

logger.info("cron_helper")

@logger = logger