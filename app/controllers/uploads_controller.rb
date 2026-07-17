# Receives inline image/file uploads from the Trix editor (trix-attachment-add)
# and returns the stored URL as JSON. Files go under public/images/data/trix/
# — public/images/data is a Capistrano linked_dir, so uploads persist across
# deploys. Replaces the old CKEditor filebrowser + Ckeditor::Picture engine.
class UploadsController < ApplicationController
  before_action :authenticate_participant!

  MAX_BYTES = 10.megabytes
  ALLOWED = %w[.jpg .jpeg .png .gif .webp .svg].freeze

  def create
    file = params[:file]
    return render(json: { error: "no file" }, status: :unprocessable_entity) if file.blank?

    ext = File.extname(file.original_filename.to_s).downcase
    return render(json: { error: "type not allowed" }, status: :unprocessable_entity) unless ALLOWED.include?(ext)
    return render(json: { error: "too large" }, status: :unprocessable_entity) if file.size.to_i > MAX_BYTES

    subdir  = File.join("trix", Time.now.strftime("%Y/%m"))
    dir     = Rails.root.join("public", "images", "data", subdir)
    FileUtils.mkdir_p(dir)
    name    = "#{SecureRandom.hex(12)}#{ext}"
    File.binwrite(dir.join(name), file.read)

    url = "https://#{BASEDOMAIN}/images/data/#{subdir}/#{name}"
    render json: { url: url, href: url }
  end
end
