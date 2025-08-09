class ReceiptProcessor
  attr_reader :receipt_image, :extracted_data, :family

  def initialize(receipt_image, family: nil)
    @receipt_image = receipt_image
    @extracted_data = {}
    @family = family
  end

  def process
    return unless receipt_image.attached?

    text = extract_text_from_image
    return if text.blank?

    @extracted_data = parse_receipt_text(text)
    extracted_data
  end

  private

    def extract_text_from_image
      # Use family's preferred OCR engine if family is provided, otherwise fallback to default order
      if family&.ocr_engine.present?
        text = extract_with_preferred_engine(family.ocr_engine)
      else
        # Fallback to trying different OCR services in order of preference
        text = try_google_vision_ocr || try_tesseract_ocr || try_aws_textract_ocr
      end
      
      Rails.logger.info "OCR extracted text: #{text&.truncate(200)}"
      text
    end

    def extract_with_preferred_engine(engine)
      Rails.logger.info "🔍 OCR Engine: Using #{engine.humanize}"
      
      case engine
      when "google_vision"
        try_google_vision_ocr_with_api_key
      when "aws_textract"
        try_aws_textract_ocr_with_api_key
      when "gemini"
        try_gemini_ocr_with_api_key
      when "tesseract"
        try_tesseract_ocr
      else
        # Unknown engine, fallback to tesseract
        Rails.logger.info "🔍 OCR Engine: Unknown engine '#{engine}', falling back to Tesseract"
        try_tesseract_ocr
      end
    end

    def try_google_vision_ocr
      return unless google_vision_configured?
      
      GoogleVisionOcrService.new(receipt_image).extract_text
    rescue => e
      Rails.logger.warn "Google Vision OCR failed: #{e.message}"
      nil
    end

    def try_tesseract_ocr
      return unless tesseract_available?
      
      TesseractOcrService.new(receipt_image).extract_text
    rescue => e
      Rails.logger.warn "Tesseract OCR failed: #{e.message}"
      nil
    end

    def try_aws_textract_ocr
      return unless aws_textract_configured?
      
      AwsTextractService.new(receipt_image).extract_text
    rescue => e
      Rails.logger.warn "AWS Textract failed: #{e.message}"
      nil
    end

    def try_google_vision_ocr_with_api_key
      api_key = family&.google_vision_api_key
      return unless api_key.present?
      
      GoogleVisionOcrService.new(receipt_image, api_key: api_key).extract_text
    rescue => e
      Rails.logger.warn "Google Vision OCR with API key failed: #{e.message}"
      nil
    end

    def try_aws_textract_ocr_with_api_key
      api_key = family&.aws_textract_api_key
      return unless api_key.present?
      
      AwsTextractService.new(receipt_image, api_key: api_key).extract_text
    rescue => e
      Rails.logger.warn "AWS Textract OCR with API key failed: #{e.message}"
      nil
    end

    def try_gemini_ocr_with_api_key
      api_key = family&.gemini_api_key
      return unless api_key.present?
      
      GeminiOcrService.new(receipt_image, api_key: api_key).extract_text
    rescue => e
      Rails.logger.warn "Gemini OCR failed: #{e.message}"
      nil
    end

    def parse_receipt_text(text)
      parser = ReceiptTextParser.new(text)
      parser.extract_data
    end

    def google_vision_configured?
      ENV['GOOGLE_VISION_API_KEY'].present? || ENV['GOOGLE_APPLICATION_CREDENTIALS'].present?
    end

    def tesseract_available?
      system('which tesseract > /dev/null 2>&1')
    end

    def aws_textract_configured?
      ENV['AWS_ACCESS_KEY_ID'].present? && ENV['AWS_SECRET_ACCESS_KEY'].present?
    end
end
