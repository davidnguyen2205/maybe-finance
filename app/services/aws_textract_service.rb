class AwsTextractService
  def initialize(image_attachment, api_key: nil)
    @image_attachment = image_attachment
    @api_key = api_key
  end

  def extract_text
    return "" unless api_key_available?

    begin
      require 'aws-sdk-textract'
      
      image_data = ""
      image_attachment.download { |chunk| image_data += chunk }
      
      aws_config = get_aws_config
      client = Aws::Textract::Client.new(aws_config)

      response = client.detect_document_text({
        document: {
          bytes: image_data
        }
      })

      extract_lines(response.blocks)
    rescue => e
      Rails.logger.error "AWS Textract error: #{e.message}"
      ""
    end
  end

  private

    attr_reader :image_attachment

    def api_key_available?
      (@api_key.present? && valid_json?(@api_key)) || 
      (ENV['AWS_ACCESS_KEY_ID'].present? && ENV['AWS_SECRET_ACCESS_KEY'].present?)
    end

    def get_aws_config
      if @api_key.present? && valid_json?(@api_key)
        # Parse API key JSON
        credentials = JSON.parse(@api_key)
        {
          access_key_id: credentials['accessKeyId'],
          secret_access_key: credentials['secretAccessKey'],
          region: credentials['region'] || 'us-east-1'
        }
      else
        # Use environment variables
        {
          access_key_id: ENV['AWS_ACCESS_KEY_ID'],
          secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
          region: ENV['AWS_REGION'] || 'us-east-1'
        }
      end
    end

    def valid_json?(string)
      JSON.parse(string)
      true
    rescue JSON::ParserError
      false
    end

    def extract_lines(blocks)
      lines = blocks
        .select { |block| block.block_type == 'LINE' }
        .map { |block| block.text }
        .join("\n")
      
      lines
    end
end
