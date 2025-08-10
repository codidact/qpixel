require 'mime/types'

module UploadsHelper
  def upload_remote_url(blob)
    bucket = Rails.cache.fetch 'active_storage/s3/bucket' do
      ActiveStorage::Blob.service.bucket.name
    end
    "https://s3.amazonaws.com/#{bucket}/#{blob.is_a?(String) ? blob : blob.key}"
  end

  # Gets a list of MIME types allowed to be uploaded
  # @return [Array<String>]
  def allowed_upload_mime_types
    fallback_types = Rails.application.config.active_storage.web_image_content_types
    SiteSetting['AllowedUploadTypes'].presence || fallback_types
  end

  # Gets a list of file extensions allowed to be uploaded
  # @return [Array<String>]
  def allowed_upload_extensions
    allowed_upload_mime_types.map { |mime| MIME::Types[mime].first.preferred_extension }
  end

  # Is a given file a valid upload by content type?
  # @param io [File] file to check
  # @return [Boolean]
  def valid_upload?(io)
    allowed_upload_mime_types.include?(io.content_type)
  end
end
