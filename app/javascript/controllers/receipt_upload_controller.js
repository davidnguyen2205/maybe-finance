import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "fileInput", "dropZone", "uploadPrompt", "preview", "previewImage", 
    "fileName", "processing", "nameField", "merchantField", "amountField", "currencyField", "categoryField", "dateField", "notesField"
  ]

  connect() {
    console.log("Receipt upload controller connected")
  }

  triggerFileSelect(event) {
    event.preventDefault()
    this.fileInputTarget.click()
  }

  handleFileSelect(event) {
    const file = event.target.files[0]
    if (file) {
      this.processFile(file)
    }
  }

  handleDragOver(event) {
    event.preventDefault()
    event.stopPropagation()
    this.dropZoneTarget.classList.add('border-blue-400', 'bg-blue-50')
  }

  handleDrop(event) {
    event.preventDefault()
    event.stopPropagation()
    this.dropZoneTarget.classList.remove('border-blue-400', 'bg-blue-50')
    
    const files = event.dataTransfer.files
    if (files.length > 0) {
      this.processFile(files[0])
    }
  }

  removeFile(event) {
    event.preventDefault()
    this.fileInputTarget.value = ''
    this.showUploadPrompt()
  }

  async processFile(file) {
    // Validate file type
    if (!file.type.startsWith('image/')) {
      alert('Please select an image file')
      return
    }

    // Validate file size (10MB limit)
    if (file.size > 10 * 1024 * 1024) {
      alert('File size must be less than 10MB')
      return
    }

    // Show preview
    this.showPreview(file)
    
    // Start OCR processing
    this.showProcessing()
    
    try {
      const extractedData = await this.performOCR(file)
      this.fillFormFields(extractedData)
      this.hideProcessing()
    } catch (error) {
      console.error('OCR processing failed:', error)
      this.hideProcessing()
      // Still keep the image preview even if OCR fails
    }
  }

  showUploadPrompt() {
    this.uploadPromptTarget.classList.remove('hidden')
    this.previewTarget.classList.add('hidden')
    this.processingTarget.classList.add('hidden')
  }

  showPreview(file) {
    this.uploadPromptTarget.classList.add('hidden')
    this.processingTarget.classList.add('hidden')
    
    // Create preview image
    const reader = new FileReader()
    reader.onload = (e) => {
      this.previewImageTarget.src = e.target.result
    }
    reader.readAsDataURL(file)
    
    this.fileNameTarget.textContent = file.name
    this.previewTarget.classList.remove('hidden')
  }

  showProcessing() {
    this.processingTarget.classList.remove('hidden')
  }

  hideProcessing() {
    this.processingTarget.classList.add('hidden')
  }

  async performOCR(file) {
    const formData = new FormData()
    formData.append('receipt[image]', file)
    
    const response = await fetch('/receipts/process', {
      method: 'POST',
      body: formData,
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      }
    })

    if (!response.ok) {
      throw new Error('OCR processing failed')
    }

    const data = await response.json()
    return data.extracted_data || {}
  }

  fillFormFields(data) {
    console.log('Extracted data:', data)
    
    // Log OCR engine used
    if (data.ocr_engine) {
      console.log(`🔍 OCR Engine Used: ${data.ocr_engine}`)
    }
    
    // Fill description/name field
    if (data.description && this.hasNameFieldTarget) {
      this.nameFieldTarget.value = data.description
      this.nameFieldTarget.dispatchEvent(new Event('input', { bubbles: true }))
    }

    // Fill merchant field (now a combobox text input)
    if (data.merchant && this.hasMerchantFieldTarget) {
      // For hotwire_combobox, we need to find the actual input element
      const comboboxInput = this.merchantFieldTarget.querySelector('.hw-combobox__input') || this.merchantFieldTarget
      comboboxInput.value = data.merchant
      comboboxInput.dispatchEvent(new Event('input', { bubbles: true }))
    }

    // Fill amount field
    if (data.amount && this.hasAmountFieldTarget) {
      this.amountFieldTarget.value = data.amount.toFixed(2)
      this.amountFieldTarget.dispatchEvent(new Event('input', { bubbles: true }))
    }

    // Fill currency field
    if (data.currency && this.hasCurrencyFieldTarget) {
      // Set the currency select field value
      this.currencyFieldTarget.value = data.currency
      this.currencyFieldTarget.dispatchEvent(new Event('change', { bubbles: true }))
    }

    // Fill date field
    if (data.date && this.hasDateFieldTarget) {
      // Format date as YYYY-MM-DD for HTML date input
      const date = new Date(data.date)
      if (!isNaN(date.getTime())) {
        const formattedDate = date.toISOString().split('T')[0]
        this.dateFieldTarget.value = formattedDate
        this.dateFieldTarget.dispatchEvent(new Event('input', { bubbles: true }))
      }
    }

    // Fill category field
    if (data.category && this.hasCategoryFieldTarget) {
      // Try to find matching category option
      const categorySelect = this.categoryFieldTarget
      const options = Array.from(categorySelect.options)
      
      const matchingOption = options.find(option => 
        option.text.toLowerCase().includes(data.category.toLowerCase()) ||
        data.category.toLowerCase().includes(option.text.toLowerCase())
      )
      
      if (matchingOption) {
        categorySelect.value = matchingOption.value
        categorySelect.dispatchEvent(new Event('change', { bubbles: true }))
      }
    }

    // Fill notes field with structured data
    if (data.notes && this.hasNotesFieldTarget) {
      this.notesFieldTarget.value = data.notes
      this.notesFieldTarget.dispatchEvent(new Event('input', { bubbles: true }))
    }

    // Show success message
    this.showSuccessMessage(data)
  }

  showSuccessMessage(data) {
    // Create a temporary success message
    const message = document.createElement('div')
    message.className = 'bg-green-50 border border-green-200 text-green-800 px-4 py-3 rounded-md text-sm'
    
    const ocrEngineText = data.ocr_engine ? ` using ${data.ocr_engine.charAt(0).toUpperCase() + data.ocr_engine.slice(1).replace('_', ' ')}` : ''
    
    message.innerHTML = `
      <div class="flex items-center space-x-2">
        <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
          <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"></path>
        </svg>
        <span>Receipt processed successfully${ocrEngineText}! Please review the extracted information.</span>
      </div>
    `
    
    // Insert message above the form
    const form = this.element.closest('form')
    form.parentNode.insertBefore(message, form)
    
    // Remove message after 5 seconds
    setTimeout(() => {
      message.remove()
    }, 5000)
  }
}
