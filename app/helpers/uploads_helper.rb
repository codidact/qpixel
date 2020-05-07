module UploadsHelper
  def upload_remote_url(blob)
    bucket = Rails.cache.fetch 'active_storage/s3/bucket' do
      ActiveStorage::Blob.service.bucket.name
    end
    "https://s3.amazonaws.com/#{bucket}/#{blob.is_a?(String) ? blob : blob.key}"
  end
end
