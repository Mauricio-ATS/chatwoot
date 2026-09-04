class InternalMessageAttachment < ApplicationRecord
  include Rails.application.routes.url_helpers
  include FileTypeHelper

  belongs_to :internal_message
  belongs_to :account

  has_one_attached :file

  before_save :set_extension
  before_save :set_file_type

  enum file_type: {
    image: 0,
    audio: 1,
    video: 2,
    file: 3
  }

  def push_event_data
    base_data.merge(file_metadata)
  end

  def file_url
    file.attached? ? url_for(file) : ''
  end

  def download_url
    ActiveStorage::Current.url_options =
      Rails.application.routes.default_url_options if ActiveStorage::Current.url_options.blank?

    file.attached? ? file.blob.url : ''
  end

  def thumb_url
    return '' unless file.attached? && image?

    begin
      url_for(file.representation(resize_to_fill: [250, nil]))
    rescue ActiveStorage::UnrepresentableError => e
      Rails.logger.warn(
        "Unrepresentable image attachment: #{id} (#{file.filename}) - #{e.message}"
      )
      ''
    end
  end

  def set_file_type
    return unless file.attached?

    self.file_type =
      if image_file?(file.content_type)
        :image
      elsif video_file?(file.content_type)
        :video
      elsif file.content_type&.start_with?('audio/')
        :audio
      else
        :file
      end
  end

  private

  def file_metadata
    {
      extension: extension,
      content_type: file.content_type,
      data_url: file_url,
      thumb_url: thumb_url,
      file_size: file.byte_size,
      width: file.metadata[:width],
      height: file.metadata[:height]
    }
  end

  def base_data
  {
    id: id,
    internal_message_id: internal_message_id,
    file_type: self[:file_type],
    account_id: account_id
  }
end

  def set_extension
    return unless file.attached?
    return if extension.present?

    self.extension =
      File.extname(file.filename.to_s).delete_prefix('.').presence
  end
end