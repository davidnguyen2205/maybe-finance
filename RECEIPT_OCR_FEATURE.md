# 📸 Receipt OCR Feature

## Overview

The Receipt OCR feature allows users to upload receipt images when creating transactions. The system automatically extracts key information using Optical Character Recognition (OCR) and pre-fills the transaction form fields.

## Features

- **📱 Image Upload**: Drag & drop or click to upload receipt images
- **🔍 OCR Processing**: Automatically extract text from receipts 
- **🤖 Smart Parsing**: Extract merchant, amount, date, and category
- **✨ Auto-fill**: Populate transaction form fields automatically
- **🖼️ Preview**: See uploaded receipt image before processing
- **🔄 Multiple OCR Providers**: Support for Google Vision, AWS Textract, and Tesseract

## How It Works

### 1. Upload Receipt
- Users can drag & drop or click to select receipt images
- Supports PNG, JPG, WEBP formats up to 10MB
- Shows image preview after upload

### 2. OCR Processing
The system tries OCR providers in this order:
1. **Google Vision API** (if API key configured)
2. **AWS Textract** (if AWS credentials configured)  
3. **Tesseract OCR** (always available, included in dev container)

### 3. Text Parsing
The extracted text is parsed to identify:
- **Amount**: Total amount using various patterns
- **Merchant**: Business name from receipt header
- **Date**: Transaction date in multiple formats
- **Category**: Smart categorization based on keywords
- **Description**: Merchant name or first meaningful text line

### 4. Form Auto-fill
Extracted data automatically populates:
- Description field
- Amount field
- Date field
- Category field (if matching category found)

## OCR Provider Configuration

### Google Vision API (Recommended)
```bash
# Set in environment
GOOGLE_VISION_API_KEY=your_api_key_here
# OR
GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
```

### AWS Textract
```bash
# Set in environment  
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
AWS_REGION=us-east-1
```

### Tesseract OCR
- No configuration needed
- Included in dev container
- Works offline but less accurate

## Development

### Files Added/Modified

**Models:**
- `app/models/transaction.rb` - Added `has_one_attached :receipt`

**Services:**
- `app/services/receipt_processor.rb` - Main OCR orchestrator
- `app/services/receipt_text_parser.rb` - Text parsing logic
- `app/services/tesseract_ocr_service.rb` - Tesseract implementation
- `app/services/google_vision_ocr_service.rb` - Google Vision implementation  
- `app/services/aws_textract_service.rb` - AWS Textract implementation

**Controllers:**
- `app/controllers/receipts_controller.rb` - OCR processing endpoint
- `app/controllers/transactions_controller.rb` - Updated to handle receipt param

**Views:**
- `app/views/transactions/_form.html.erb` - Added receipt upload UI

**JavaScript:**
- `app/javascript/controllers/receipt_upload_controller.js` - Stimulus controller

**Configuration:**
- `.devcontainer/Dockerfile` - Added Tesseract OCR
- `config/routes.rb` - Added receipt processing route

### Testing the Feature

1. Start the dev container with the updated configuration
2. Navigate to create a new transaction
3. Upload a receipt image using the new upload area
4. Watch as the form fields are automatically populated
5. Review and adjust the extracted data as needed
6. Submit the transaction

### API Endpoint

**POST** `/receipts/process`

**Request:**
- `receipt`: Image file (multipart/form-data)

**Response:**
```json
{
  "success": true,
  "extracted_data": {
    "amount": 25.99,
    "merchant": "Starbucks",
    "date": "2024-01-15",
    "category": "Food",
    "description": "Starbucks Coffee"
  }
}
```

## Text Parsing Patterns

### Amount Detection
- `Total: $25.99`
- `Amount: 25.99`
- `$25.99`
- `25.99 USD`

### Date Detection  
- `01/15/2024`
- `2024-01-15`
- `January 15, 2024`
- `15 Jan 2024`

### Merchant Detection
- First few lines of receipt
- Matches against known merchant keywords
- Business name patterns

### Category Classification
- **Food**: restaurant, cafe, grocery, market
- **Gas**: gas station, fuel, gasoline
- **Shopping**: walmart, target, store, retail
- **Healthcare**: doctor, hospital, pharmacy
- **Travel**: hotel, airline, taxi, uber

## Error Handling

- **File validation**: Type and size checks
- **OCR fallback**: Multiple providers ensure reliability
- **Graceful degradation**: Form still works if OCR fails
- **User feedback**: Clear messages for success/failure states

## Future Enhancements

- [ ] **Receipt storage**: Save receipt images with transactions
- [ ] **Machine learning**: Improve parsing accuracy over time
- [ ] **Multi-language**: Support for non-English receipts  
- [ ] **Batch processing**: Upload multiple receipts at once
- [ ] **Mobile optimization**: Better mobile camera integration
- [ ] **Receipt templates**: Custom parsing for specific merchants

## Performance Considerations

- **Async processing**: OCR runs in background via AJAX
- **File size limits**: 10MB maximum to prevent performance issues
- **Caching**: Results could be cached to avoid re-processing
- **Rate limiting**: Consider API rate limits for cloud providers

---

This feature significantly improves the user experience by reducing manual data entry and making expense tracking more convenient! 🎉
