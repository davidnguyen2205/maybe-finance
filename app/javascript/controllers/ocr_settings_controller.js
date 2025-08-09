import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["googleVisionFields", "awsTextractFields", "geminiFields"]

  connect() {
    this.showApiKeyField()
  }

  showApiKeyField() {
    // Hide all API key fields first
    this.hideAllFields()
    
    // Get the selected OCR engine
    const ocrEngineSelect = this.element.querySelector('select[name*="ocr_engine"]')
    if (!ocrEngineSelect) return
    
    const selectedEngine = ocrEngineSelect.value
    
    // Show the appropriate API key field
    switch (selectedEngine) {
      case "google_vision":
        if (this.hasGoogleVisionFieldsTarget) {
          this.googleVisionFieldsTarget.classList.remove("hidden")
        }
        break
      case "aws_textract":
        if (this.hasAwsTextractFieldsTarget) {
          this.awsTextractFieldsTarget.classList.remove("hidden")
        }
        break
      case "gemini":
        if (this.hasGeminiFieldsTarget) {
          this.geminiFieldsTarget.classList.remove("hidden")
        }
        break
      case "tesseract":
      default:
        // No API key needed for Tesseract
        break
    }
  }

  hideAllFields() {
    if (this.hasGoogleVisionFieldsTarget) {
      this.googleVisionFieldsTarget.classList.add("hidden")
    }
    if (this.hasAwsTextractFieldsTarget) {
      this.awsTextractFieldsTarget.classList.add("hidden")
    }
    if (this.hasGeminiFieldsTarget) {
      this.geminiFieldsTarget.classList.add("hidden")
    }
  }
}
