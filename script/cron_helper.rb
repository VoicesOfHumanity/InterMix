require File.dirname(__FILE__) + '/../config/environment'

include ApplicationHelper
include ActionView::Helpers::TextHelper
def helper
  @helper_proxy ||= Object.new
end
helper.extend ApplicationHelper
helper.extend ActionView::Helpers::TextHelper