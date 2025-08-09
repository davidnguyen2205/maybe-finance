class TesseractOcrService
  def initialize(image_attachment)
    @image_attachment = image_attachment
  end

  def extract_text
    return "" unless tesseract_available?

    with_temp_image do |temp_path|
      command = "tesseract '#{temp_path}' stdout -l eng"
      result = `#{command} 2>/dev/null`
      
      if $?.success?
        result.strip
      else
        Rails.logger.error "Tesseract OCR failed for image"
        ""
      end
    end
  end

  private

    attr_reader :image_attachment

    def tesseract_available?
      @tesseract_available ||= system('which tesseract > /dev/null 2>&1')
    end

    def with_temp_image
      temp_file = nil
      begin
        # Download the image to a temporary file
        temp_file = Tempfile.new(['receipt', file_extension])
        temp_file.binmode
        
        image_attachment.download do |chunk|
          temp_file.write(chunk)
        end
        temp_file.close
        
        yield temp_file.path
      ensure
        temp_file&.unlink
      end
    end

    def file_extension
      content_type = image_attachment.content_type
      case content_type
      when 'image/jpeg', 'image/jpg'
        '.jpg'
      when 'image/png'
        '.png'
      when 'image/gif'
        '.gif'
      when 'image/webp'
        '.webp'
      else
        '.jpg' # default
      end
    end
end
