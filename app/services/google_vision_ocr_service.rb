class GoogleVisionOcrService
  def initialize(image_attachment, api_key: nil)
    @image_attachment = image_attachment
    @api_key = api_key
  end

  def extract_text
    return "" unless api_key_available?

    begin
      require 'net/http'
      require 'json'
      require 'base64'

      image_data = encode_image
      response = make_vision_request(image_data)
      parse_response(response)
    rescue => e
      Rails.logger.error "Google Vision OCR error: #{e.message}"
      ""
    end
  end

  private

    attr_reader :image_attachment

    def api_key_available?
      @api_key.present? || ENV['GOOGLE_VISION_API_KEY'].present?
    end

    def get_api_key
      @api_key || ENV['GOOGLE_VISION_API_KEY']
    end

    def encode_image
      image_data = ""
      image_attachment.download { |chunk| image_data += chunk }
      Base64.strict_encode64(image_data)
    end

    def make_vision_request(image_data)
      uri = URI("https://vision.googleapis.com/v1/images:annotate?key=#{get_api_key}")
      
      request_body = {
        requests: [{
          image: { content: image_data },
          features: [{ type: "TEXT_DETECTION", maxResults: 1 }]
        }]
      }

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      
      request = Net::HTTP::Post.new(uri)
      request['Content-Type'] = 'application/json'
      request.body = request_body.to_json
      
      response = http.request(request)
      JSON.parse(response.body)
    end

    def parse_response(response)
      return "" unless response['responses']&.any?

      text_annotations = response['responses'][0]['textAnnotations']
      return "" unless text_annotations&.any?

      # The first annotation contains all detected text
      text_annotations[0]['description'] || ""
    end
end
