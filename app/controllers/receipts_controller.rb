class ReceiptsController < ApplicationController
  # Skip CSRF protection for this API-like endpoint
  skip_before_action :verify_authenticity_token, only: [:upload]

  def upload
    uploaded_file = params[:receipt] && params[:receipt][:image]
    return render_error("No receipt file provided") unless uploaded_file
    
    begin
      # Create a temporary transaction to attach the receipt for processing
      temp_transaction = Transaction.new
      temp_transaction.receipt.attach(uploaded_file)
      
      # Save the transaction to persist the attachment
      temp_transaction.save!
      
      # Process the receipt with OCR
      processor = ReceiptProcessor.new(temp_transaction.receipt, family: Current.family)
      processor.process
      extracted_data = processor.extracted_data
      
      # Clean up the temporary transaction and attachment
      temp_transaction.receipt.purge
      temp_transaction.destroy
      
      render json: { 
        success: true, 
        extracted_data: extracted_data.merge(
          ocr_engine: Current.family&.ocr_engine || 'tesseract'
        )
      }
      
    rescue => e
      Rails.logger.error "Receipt processing error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      
      render_error("Failed to process receipt: #{e.message}")
    end
  end

  private

    def receipt_file
      params[:receipt][:image] if params[:receipt]
    end

    def render_error(message)
      render json: { 
        success: false, 
        error: message 
      }, status: :unprocessable_entity
    end
end
