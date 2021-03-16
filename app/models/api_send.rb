class ApiSend < ApplicationRecord
  serialize :request_headers
  serialize :request_object
end
