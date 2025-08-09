# Gemini OCR Integration

This document describes the implementation of Google Gemini as an OCR option for receipt processing in the Expenso application.

## Overview

Google Gemini is integrated as a fourth OCR engine option alongside Tesseract, Google Vision API, and AWS Textract. Based on the [Gemini Image Understanding documentation](https://ai.google.dev/gemini-api/docs/image-understanding), Gemini provides excellent multimodal capabilities for image processing and computer vision tasks.

## Features

### ✅ Implemented Features

1. **GeminiOcrService**: A dedicated service for Gemini API image processing
2. **API Key Management**: User-configurable API keys for all OCR services
3. **Settings UI**: Enhanced settings page with OCR engine selection and API key inputs
4. **Dynamic UI**: JavaScript controller to show/hide relevant API key fields
5. **Fallback Support**: Graceful fallback to environment variables when no API key is provided

### 🔧 Technical Implementation

**New Files Created:**
- `app/services/gemini_ocr_service.rb` - Gemini OCR implementation
- `app/javascript/controllers/ocr_settings_controller.js` - Dynamic UI controller
- `db/migrate/*_add_ocr_api_keys_to_families.rb` - Database migration for API keys

**Enhanced Files:**
- `app/models/family.rb` - Added Gemini to OCR_ENGINES constant
- `app/views/settings/preferences/show.html.erb` - Enhanced UI with API key inputs
- `app/services/receipt_processor.rb` - Added Gemini support and API key handling
- `app/services/google_vision_ocr_service.rb` - Added API key parameter support
- `app/services/aws_textract_service.rb` - Added JSON API key support
- `app/controllers/users_controller.rb` - Added API key parameters

## API Key Configuration

### Gemini API Key
- **Source**: [Google AI Studio](https://makersuite.google.com/app/apikey)
- **Format**: String API key (e.g., `AIzaSyB...`)
- **Storage**: `families.gemini_api_key` (encrypted text field)

### Google Vision API Key
- **Source**: [Google Cloud Console](https://console.cloud.google.com/apis/credentials)
- **Format**: String API key
- **Storage**: `families.google_vision_api_key` (encrypted text field)

### AWS Textract Credentials
- **Source**: [AWS IAM Console](https://console.aws.amazon.com/iam/)
- **Format**: JSON object containing credentials
- **Example**:
  ```json
  {
    "accessKeyId": "AKIAIOSFODNN7EXAMPLE",
    "secretAccessKey": "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
    "region": "us-east-1"
  }
  ```
- **Storage**: `families.aws_textract_api_key` (encrypted text field)

## Gemini OCR Implementation Details

### Model Configuration
- **Model**: `gemini-2.5-flash` (optimized for speed and cost)
- **API Endpoint**: `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent`
- **Temperature**: 0.1 (low for consistent OCR results)
- **Max Output Tokens**: 2048

### Prompt Engineering
The service uses a specialized prompt for OCR tasks:

```
Please extract all text from this receipt or invoice image. 

Instructions:
- Return the text exactly as it appears on the image
- Preserve the original formatting and line breaks
- Include all numbers, dates, amounts, and text
- Do not add any commentary or explanations
- If you cannot read certain text, indicate it as [UNCLEAR]

Extract the text:
```

### Image Processing
- **Supported Formats**: JPEG, PNG, WEBP, HEIC, HEIF (via Gemini API)
- **Input Method**: Base64 encoded image data with MIME type detection
- **Size Limits**: Follows Gemini API limits (max 20MB per request)

## Settings UI Enhancement

### Dynamic Interface
The settings page now includes:

1. **OCR Engine Dropdown**: All four options (Tesseract, Google Vision, AWS Textract, Gemini)
2. **Conditional API Key Fields**: Shown/hidden based on selected engine
3. **Helpful Links**: Direct links to get API keys from respective providers
4. **Current Engine Display**: Shows which engine is currently selected

### JavaScript Controller
`ocr_settings_controller.js` manages:
- Showing/hiding API key fields based on engine selection
- Real-time updates without page refresh
- Maintaining form state across interactions

## Usage Instructions

### For Users

1. **Access Settings**: Go to `http://localhost:3000/settings/preferences`
2. **Select OCR Engine**: Choose "Gemini" from the OCR Engine dropdown
3. **Enter API Key**: Input your Gemini API key in the revealed field
4. **Automatic Save**: Changes are saved automatically via auto-submit

### For Developers

**Testing the Integration:**
```bash
# Test OCR with curl (using session cookies)
curl -X POST http://localhost:3000/receipts/process \
  -H "Cookie: your-session-cookies" \
  -F "receipt[image]=@test-receipt.jpg"
```

**Engine Selection Logic:**
```ruby
# In ReceiptProcessor
case family.ocr_engine
when "gemini"
  GeminiOcrService.new(receipt_image, api_key: family.gemini_api_key).extract_text
when "google_vision"
  GoogleVisionOcrService.new(receipt_image, api_key: family.google_vision_api_key).extract_text
# ... other engines
end
```

## Security Considerations

- **API Key Storage**: All API keys are stored in encrypted text fields in the database
- **Input Type**: API key fields use `type="password"` to prevent shoulder surfing
- **Error Handling**: API keys are not logged in error messages
- **Fallback**: Environment variables are still supported as fallback

## Performance & Cost Optimization

### Gemini Advantages
- **Speed**: `gemini-2.5-flash` is optimized for fast responses
- **Cost**: Generally more cost-effective than other cloud OCR services
- **Accuracy**: Excellent performance on complex documents and invoices
- **Multimodal**: Native support for both text and image understanding

### Best Practices
- Use low temperature (0.1) for consistent OCR results
- Implement proper error handling and retries
- Monitor API usage and costs through Google AI Studio
- Consider implementing rate limiting for high-volume usage

## Troubleshooting

### Common Issues

1. **"No API key provided"**: Ensure API key is saved in family settings
2. **"Invalid API key"**: Verify key is correct and has proper permissions
3. **"Request failed"**: Check internet connectivity and API quotas
4. **Empty extraction**: Verify image format is supported and readable

### Debug Mode
Enable Rails logging to see OCR processing details:
```ruby
Rails.logger.info "Gemini OCR extracted text length: #{text&.length}"
```

## Future Enhancements

### Potential Improvements
- **Vision-Specific Prompts**: Optimize prompts for different document types
- **Batch Processing**: Support for multiple images in one request
- **Confidence Scores**: Include OCR confidence levels in responses
- **Advanced Features**: Leverage Gemini's object detection and segmentation capabilities
- **Cost Monitoring**: Track API usage and costs per family

### Integration Opportunities
- **Document Understanding**: Use Gemini for structured data extraction
- **Image Enhancement**: Pre-process images for better OCR results
- **Multi-language Support**: Leverage Gemini's multilingual capabilities

## References

- [Gemini Image Understanding Documentation](https://ai.google.dev/gemini-api/docs/image-understanding)
- [Google AI Studio](https://makersuite.google.com/app/apikey)
- [Gemini API Pricing](https://ai.google.dev/pricing)
- [Gemini Model Capabilities](https://ai.google.dev/gemini-api/docs/models/gemini)
