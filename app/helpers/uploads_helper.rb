module UploadsHelper
  def upload_remote_url(blob)
    bucket = Rails.cache.fetch 'active_storage/s3/bucket' do
      ActiveStorage::Blob.service.bucket.name
    end
    "https://s3.amazonaws.com/#{bucket}/#{blob.is_a?(String) ? blob : blob.key}"
  end

  def valid_image?(io)
    content_types = ActiveStorage::Variant::WEB_IMAGE_CONTENT_TYPES
    extensions = content_types.map { |ct| ct.gsub('image/', '') }
    submitted_extension = io.original_filename.split('.')[-1].downcase
    content_types.include?(io.content_type) && extensions.include?(submitted_extension) &&
      extensions.map(&:to_sym).include?(FastImage.type(io))
  end
end
