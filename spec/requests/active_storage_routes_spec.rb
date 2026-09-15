# The app does not use Active Storage (uploads go through Paperclip and our own
# POST /uploads), but rails/all loads the engine, which drew its routes anyway.
# Scanners probe POST /rails/active_storage/direct_uploads, and every probe mailed
# an InvalidAuthenticityToken (production, 2026-09). config.active_storage.draw_routes
# is now false, so those paths don't exist at all.
#
# show_exceptions is :none in test, so an unmatched route raises RoutingError here;
# in production the same request is a 404, which exception_notification ignores.
require 'rails_helper'

RSpec.describe 'Active Storage routes', type: :request do
  it 'does not route the direct upload endpoint scanners probe' do
    expect {
      post '/rails/active_storage/direct_uploads',
           params: { blob: { filename: 'p0.png', byte_size: 1251,
                             checksum: 'HICKUupFmYQK1x0/kWrkEw==', content_type: 'image/png' } }
    }.to raise_error(ActionController::RoutingError)
  end

  it 'does not route the disk service upload endpoint' do
    expect { put '/rails/active_storage/disk/sometoken' }.to raise_error(ActionController::RoutingError)
  end

  it 'draws none of the Active Storage routes' do
    as_routes = Rails.application.routes.routes.map { |r| r.path.spec.to_s }
                                             .grep(%r{\A/rails/active_storage})
    expect(as_routes).to be_empty
  end

  it 'still routes the Trix upload endpoint' do
    expect(Rails.application.routes.recognize_path('/uploads', method: :post))
      .to include(controller: 'uploads', action: 'create')
  end
end
