require 'net/http'
require 'json'
require 'base64'

class GeminiOcrService
  API_ENDPOINT = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"
  
  attr_reader :receipt_image, :api_key
  
  def initialize(receipt_image, api_key: nil)
    @receipt_image = receipt_image
    @api_key = api_key
  end
  
  def extract_text
    return nil unless api_key.present?
    return nil unless receipt_image&.attached?
    
    # Download the image and convert to base64
    image_data = receipt_image.download
    base64_image = Base64.strict_encode64(image_data)
    
    # Determine MIME type
    mime_type = receipt_image.content_type || 'image/jpeg'
    
    # Prepare the request payload
    payload = {
      contents: [
        {
          parts: [
            {
              inline_data: {
                mime_type: mime_type,
                data: base64_image
              }
            },
            {
              text: build_ocr_prompt
            }
          ]
        }
      ],
      generation_config: {
        temperature: 0.1, # Low temperature for more consistent OCR results
        max_output_tokens: 2048
      }
    }
    
    # Make the API request
    response = make_api_request(payload)
    
    if response && response['candidates'] && response['candidates'].first
      candidate = response['candidates'].first
      if candidate['content'] && candidate['content']['parts']
        text = candidate['content']['parts'].first['text']
        Rails.logger.info "Gemini OCR extracted text length: #{text&.length}"
        return text
      end
    end
    
    Rails.logger.warn "Gemini OCR: No valid response received"
    nil
  rescue => e
    Rails.logger.error "Gemini OCR error: #{e.message}"
    nil
  end
  
  private
  
  def build_ocr_prompt
    <<~PROMPT
      Please extract all text from this receipt or invoice image. 
      
      Instructions:
      - Return the text exactly as it appears on the image
      - Preserve the original formatting and line breaks
      - Include all numbers, dates, amounts, and text
      - Do not add any commentary or explanations
      - If you cannot read certain text, indicate it as [UNCLEAR]
      
      Extract the text:
    PROMPT
  end
  
  def make_api_request(payload)
    uri = URI("#{API_ENDPOINT}?key=#{api_key}")
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 30
    
    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request.body = payload.to_json
    
    response = http.request(request)
    
    if response.code == '200'
      JSON.parse(response.body)
    else
      Rails.logger.error "Gemini API error: #{response.code} - #{response.body}"
      nil
    end
  end
end
