class ReceiptTextParser
  AMOUNT_PATTERNS = [
    # Look for "TOTALS" section first (for invoices) - most specific
    /(?:totals?|grand\s*total|final\s*total)\s*:?\s*\$?(\d{1,4}[,.]?\d{2})/i,
    # Standard total patterns
    /(?:total|amount|subtotal|sum)\s*:?\s*\$?(\d{1,4}[,.]?\d{2})/i,
    # Money with dollar sign at line end (common in receipts)
    /\$(\d{1,4}[,.]?\d{2})(?:\s*$)/,
    # Money with currency notation
    /(\d{1,4}[,.]?\d{2})\s*(?:USD|usd)/i
  ].freeze

  DATE_PATTERNS = [
    /(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})/,
    /(\d{4}[\/\-\.]\d{1,2}[\/\-\.]\d{1,2})/,
    /((?:jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\w*\s+\d{1,2},?\s+\d{2,4})/i,
    /(\d{1,2}\s+(?:jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\w*\s+\d{2,4})/i
  ].freeze

  MERCHANT_KEYWORDS = %w[
    store shop market restaurant cafe coffee bar grill pub
    walmart target amazon costco kroger safeway cvs walgreens
    mcdonalds subway starbucks chipotle panera kfc taco
    gas station shell exxon bp chevron mobil
    hotel motel inn resort spa
    pharmacy drugstore
  ].freeze

  CATEGORY_KEYWORDS = {
    'Food' => %w[restaurant cafe coffee food grocery market deli bakery pizza burger],
    'Gas' => %w[gas station fuel gasoline diesel],
    'Shopping' => %w[walmart target costco store shop retail clothing],
    'Pharmacy' => %w[pharmacy drugstore cvs walgreens medicine],
    'Entertainment' => %w[movie theater cinema bar pub entertainment],
    'Travel' => %w[hotel motel inn resort airline taxi uber lyft],
    'Utilities' => %w[electric power water gas utility bill],
    'Healthcare' => %w[doctor hospital medical clinic dental],
    'Professional Services' => %w[design architecture consulting legal accounting invoice professional service],
    'Office Supplies' => %w[furniture office supplies equipment software]
  }.freeze

  # Currency detection patterns
  CURRENCY_PATTERNS = [
    # Currency symbols with amounts
    /\$[\d,\.]+/,                           # Dollar sign ($123.45)
    /€[\d,\.]+/,                            # Euro sign (€123.45)
    /£[\d,\.]+/,                            # Pound sign (£123.45)
    /¥[\d,\.]+/,                            # Yen sign (¥123)
    /₹[\d,\.]+/,                            # Rupee sign (₹123.45)
    
    # Currency codes near amounts
    /[\d,\.]+\s*(?:USD|usd|US\$)/i,         # USD
    /[\d,\.]+\s*(?:EUR|eur|€)/i,            # EUR
    /[\d,\.]+\s*(?:GBP|gbp|£)/i,            # GBP
    /[\d,\.]+\s*(?:JPY|jpy|¥)/i,            # JPY
    /[\d,\.]+\s*(?:CAD|cad|C\$)/i,          # CAD
    /[\d,\.]+\s*(?:AUD|aud|A\$)/i,          # AUD
    /[\d,\.]+\s*(?:INR|inr|₹)/i,            # INR
    
    # Standalone currency mentions
    /(?:currency|paid\s+in|total\s+in):\s*([A-Z]{3})/i
  ].freeze

  # Currency code mapping
  CURRENCY_MAPPING = {
    '$' => 'USD',
    'US$' => 'USD', 
    'USD' => 'USD',
    '€' => 'EUR',
    'EUR' => 'EUR',
    '£' => 'GBP',
    'GBP' => 'GBP',
    '¥' => 'JPY',
    'JPY' => 'JPY',
    'C$' => 'CAD',
    'CAD' => 'CAD',
    'A$' => 'AUD',
    'AUD' => 'AUD',
    '₹' => 'INR',
    'INR' => 'INR'
  }.freeze

  def initialize(text)
    @text = text.to_s.strip
    @lines = @text.split(/\n+/).map(&:strip).reject(&:blank?)
  end

  def extract_data
    {
      amount: extract_amount,
      merchant: extract_merchant,
      date: extract_date,
      category: extract_category,
      description: extract_description,
      currency: extract_currency,
      notes: extract_structured_notes
    }.compact
  end

  private

    attr_reader :text, :lines

    def extract_structured_notes
      notes_data = {
        vendor_info: extract_vendor_info,
        customer_info: extract_customer_info,
        line_items: extract_line_items,
        totals: extract_totals_breakdown,
        payment_info: extract_payment_info,
        receipt_details: extract_receipt_details
      }

      format_structured_notes(notes_data)
    end

    def extract_vendor_info
      vendor_info = {}
      
      # Extract business name, address, phone, etc.
      text.scan(/(?:company|business|corp|inc|llc)[\s\S]*?(?=\n|$)/i).each do |match|
        vendor_info[:business_name] = match.strip if match.length < 100
      end
      
      # Extract address
      address_patterns = [
        /\d+\s+[A-Za-z\s]+(?:street|st|avenue|ave|road|rd|lane|ln|blvd|boulevard)\s*,?\s*[A-Za-z\s]*\d{5}/i,
        /[A-Za-z\s]+,\s*[A-Z]{2}\s+\d{5}/i
      ]
      
      address_patterns.each do |pattern|
        if match = text.match(pattern)
          vendor_info[:address] = match[0].strip
          break
        end
      end
      
      # Extract phone
      if phone_match = text.match(/(?:phone|tel|call)[:\s]*(\(?[\d\s\-\(\)\.]{10,})/i)
        vendor_info[:phone] = phone_match[1].strip
      end
      
      # Extract email
      if email_match = text.match(/([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})/i)
        vendor_info[:email] = email_match[1]
      end
      
      # Extract website
      if website_match = text.match(/(www\.[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}|[a-zA-Z0-9.-]+\.com)/i)
        vendor_info[:website] = website_match[1]
      end
      
      vendor_info
    end

    def extract_customer_info
      customer_info = {}
      
      # Look for "BILL TO:" or "Customer:" sections
      if bill_to_match = text.match(/(?:bill\s+to|customer|client)[:]*\s*\n?(.*?)(?=\n\n|\n[A-Z]|$)/im)
        customer_lines = bill_to_match[1].split(/\n/).map(&:strip).reject(&:blank?)
        customer_info[:bill_to] = customer_lines.join(", ") if customer_lines.any?
      end
      
      customer_info
    end

    def extract_line_items
      items = []
      
      # Pattern 1: Itemized receipts with qty, description, price
      items_section = text.match(/(?:item|description|qty|quantity)[\s\S]*?(?:total|subtotal|tax)/i)
      
      if items_section
        item_lines = items_section[0].split(/\n/).map(&:strip).reject(&:blank?)
        
        item_lines.each do |line|
          # Skip header lines
          next if line.match?(/^(?:item|description|qty|quantity|price|amount)/i)
          next if line.match?(/^[-=\s]+$/)
          
          # Pattern: Qty Description Price or Description Qty Price or Qty x Description Price
          if item_match = line.match(/^(\d+(?:\.\d+)?)\s*x?\s*(.+?)\s+(\$?[\d,]+\.?\d*)$/) ||
                         line.match(/^(.+?)\s+(\d+(?:\.\d+)?)\s*x?\s*(\$?[\d,]+\.?\d*)$/) ||
                         line.match(/^(\d+(?:\.\d+)?)\s+(.+?)\s+-\s+(\$?[\d,]+\.?\d*)$/)
            
            qty = item_match[1].to_s.gsub(/[^\d\.]/, '')
            desc = item_match[2].strip
            price = item_match[3]
            
            items << {
              quantity: qty.present? && qty.match?(/^\d/) ? qty : nil,
              description: desc,
              price: price
            }.compact
          elsif line.match?(/\$?[\d,]+\.?\d*/) && !line.match?(/total|tax|subtotal/i)
            # Simple item with price
            price_match = line.match(/(\$?[\d,]+\.?\d*)/)
            description = line.gsub(price_match[0], '').strip
            
            items << {
              description: description,
              price: price_match[0]
            } if description.length > 2
          end
        end
      end
      
      # Pattern 2: Service invoices with line items
      if items.empty?
        lines.each do |line|
          # Look for lines that have both description and price
          if line.match?(/\$[\d,]+\.?\d*/) && 
             !line.match?(/total|subtotal|tax|amount\s+due|balance/i) &&
             line.length > 10
            
            price_match = line.match(/(\$[\d,]+\.?\d*)/)
            description = line.gsub(price_match[0], '').strip
            
            items << {
              description: description,
              price: price_match[0]
            } if description.length > 3
          end
        end
      end
      
      items
    end

    def extract_totals_breakdown
      totals = {}
      
      # Extract subtotal
      if subtotal_match = text.match(/(?:sub\s*total|subtotal)[\s:]*(\$?[\d,]+\.?\d*)/i)
        totals[:subtotal] = subtotal_match[1]
      end
      
      # Extract tax
      if tax_match = text.match(/(?:tax|vat|gst)[\s:]*(\$?[\d,]+\.?\d*)/i)
        totals[:tax] = tax_match[1]
      end
      
      # Extract tip
      if tip_match = text.match(/(?:tip|gratuity)[\s:]*(\$?[\d,]+\.?\d*)/i)
        totals[:tip] = tip_match[1]
      end
      
      # Extract discount
      if discount_match = text.match(/(?:discount|coupon|savings)[\s:]*(\$?[\d,]+\.?\d*)/i)
        totals[:discount] = discount_match[1]
      end
      
      # Extract total (already extracted in main method, but include for completeness)
      if total_match = text.match(/(?:total|grand\s*total|amount\s*due)[\s:]*(\$?[\d,]+\.?\d*)/i)
        totals[:total] = total_match[1]
      end
      
      totals
    end

    def extract_payment_info
      payment_info = {}
      
      # Extract payment method
      payment_methods = ['cash', 'credit', 'debit', 'visa', 'mastercard', 'amex', 'discover', 'check', 'paypal']
      payment_methods.each do |method|
        if text.match?(/\b#{method}\b/i)
          payment_info[:method] = method.capitalize
          break
        end
      end
      
      # Extract card last 4 digits
      if card_match = text.match(/(?:card|account).*?(\d{4})/i)
        payment_info[:card_last_four] = card_match[1]
      end
      
      # Extract transaction ID
      if trans_match = text.match(/(?:transaction|trans|ref|reference)[\s#:]*([a-zA-Z0-9]+)/i)
        payment_info[:transaction_id] = trans_match[1]
      end
      
      payment_info
    end

    def extract_receipt_details
      details = {}
      
      # Extract receipt/invoice number
      if receipt_match = text.match(/(?:receipt|invoice|order)[\s#:]*([a-zA-Z0-9\-]+)/i)
        details[:receipt_number] = receipt_match[1]
      end
      
      # Extract cashier/server
      if cashier_match = text.match(/(?:cashier|server|clerk)[\s:]*([a-zA-Z\s]+)/i)
        details[:cashier] = cashier_match[1].strip
      end
      
      # Extract store number
      if store_match = text.match(/(?:store|location)[\s#:]*(\d+)/i)
        details[:store_number] = store_match[1]
      end
      
      # Extract time
      if time_match = text.match(/(\d{1,2}:\d{2}(?::\d{2})?\s*(?:AM|PM)?)/i)
        details[:time] = time_match[1]
      end
      
      details
    end

    def format_structured_notes(data)
      notes = []
      
      # Vendor Information
      if data[:vendor_info].any?
        notes << "**VENDOR INFORMATION**"
        data[:vendor_info].each do |key, value|
          formatted_key = key.to_s.gsub('_', ' ').titleize
          notes << "#{formatted_key}: #{value}"
        end
        notes << ""
      end
      
      # Customer Information
      if data[:customer_info].any?
        notes << "**CUSTOMER INFORMATION**"
        data[:customer_info].each do |key, value|
          formatted_key = key.to_s.gsub('_', ' ').titleize
          notes << "#{formatted_key}: #{value}"
        end
        notes << ""
      end
      
      # Line Items
      if data[:line_items].any?
        notes << "**ITEMS/SERVICES**"
        data[:line_items].each_with_index do |item, index|
          line = "#{index + 1}. #{item[:description]}"
          line += " (Qty: #{item[:quantity]})" if item[:quantity]
          line += " - #{item[:price]}"
          notes << line
        end
        notes << ""
      end
      
      # Totals Breakdown
      if data[:totals].any?
        notes << "**TOTALS BREAKDOWN**"
        data[:totals].each do |key, value|
          formatted_key = key.to_s.gsub('_', ' ').titleize
          notes << "#{formatted_key}: #{value}"
        end
        notes << ""
      end
      
      # Payment Information
      if data[:payment_info].any?
        notes << "**PAYMENT INFORMATION**"
        data[:payment_info].each do |key, value|
          formatted_key = key.to_s.gsub('_', ' ').titleize
          notes << "#{formatted_key}: #{value}"
        end
        notes << ""
      end
      
      # Receipt Details
      if data[:receipt_details].any?
        notes << "**RECEIPT DETAILS**"
        data[:receipt_details].each do |key, value|
          formatted_key = key.to_s.gsub('_', ' ').titleize
          notes << "#{formatted_key}: #{value}"
        end
      end
      
      notes.join("\n")
    end

    def extract_amount
      amounts = []
      
      AMOUNT_PATTERNS.each do |pattern|
        text.scan(pattern) do |match|
          amount_str = match.is_a?(Array) ? match.first : match
          amount = parse_amount(amount_str)
          # Skip amounts that look like account numbers, phone numbers, or dates
          next if amount_str.match?(/\d{4}\s+\d{4}\s+\d{4}/) # Account numbers
          next if amount_str.match?(/\d{3}-\d{3}-\d{4}/) # Phone numbers
          next if amount && amount > 50000 # Unreasonably large amounts
          amounts << amount if amount && amount > 0
        end
      end

      # Return the largest reasonable amount (likely the total)
      amounts.select { |a| a < 10000 && a > 0.01 }.max
    end

    def extract_merchant
      # Look for business names (usually in first few lines)
      candidate_lines = lines.first(6)
      
      # Find lines that look like business names
      merchant_candidates = candidate_lines.select do |line|
        line.length > 3 && 
        line.length < 50 && 
        !line.match?(/\d+[\/\-\.]\d+[\/\-\.]\d+/) && # Not a date line
        !line.match?(/\d+[\.,]\d{2}/) && # Not a price line
        !line.match?(/^(?:invoice|bill|receipt)/i) && # Not header words
        !line.match?(/^\d+$/) && # Not just numbers
        line.match?(/[a-zA-Z]/) # Contains letters
      end

      # For invoices, look for "BILL TO:" section and take the name after it
      bill_to_index = lines.find_index { |line| line.match?(/bill\s+to\s*:?/i) }
      if bill_to_index && bill_to_index < lines.length - 1
        # Get the name(s) after "BILL TO:"
        potential_names = lines[(bill_to_index + 1)..(bill_to_index + 3)].select do |line|
          line.match?(/^[A-Za-z\s]+$/) && line.length > 2 && line.length < 50
        end
        if potential_names.any?
          return clean_merchant_name(potential_names.join(' '))
        end
      end

      # Check against known merchant keywords
      merchant_candidates.each do |candidate|
        MERCHANT_KEYWORDS.each do |keyword|
          return clean_merchant_name(candidate) if candidate.downcase.include?(keyword)
        end
      end

      # Return first reasonable candidate if no keyword match
      merchant_candidates.first&.then { |name| clean_merchant_name(name) }
    end

    def extract_date
      DATE_PATTERNS.each do |pattern|
        text.scan(pattern) do |match|
          date_str = match.is_a?(Array) ? match.first : match
          parsed_date = parse_date(date_str)
          return parsed_date if parsed_date
        end
      end
      nil
    end

    def extract_category
      text_lower = text.downcase
      
      # Score each category by keyword matches
      category_scores = {}
      
      CATEGORY_KEYWORDS.each do |category, keywords|
        score = 0
        keywords.each do |keyword|
          # Count occurrences of each keyword
          score += text_lower.scan(keyword).length
        end
        category_scores[category] = score if score > 0
      end
      
      # Return the category with the highest score
      return nil if category_scores.empty?
      category_scores.max_by { |category, score| score }&.first
    end

    def extract_description
      merchant = extract_merchant
      return merchant if merchant.present?
      
      # Fallback to first meaningful line
      lines.find { |line| line.length > 5 && line.match?(/[a-zA-Z]/) }
    end

    def parse_amount(amount_str)
      return nil if amount_str.blank?
      
      # Clean the amount string
      cleaned = amount_str.gsub(/[$,]/, '')
      
      # Replace comma with dot for decimal separator if it's being used as decimal
      if cleaned.count('.') == 0 && cleaned.count(',') == 1 && cleaned.match?(/,\d{2}$/)
        cleaned = cleaned.gsub(',', '.')
      elsif cleaned.count(',') > 0 && cleaned.count('.') == 0
        # Remove thousands separators (commas)
        cleaned = cleaned.gsub(',', '')
      elsif cleaned.count(',') > 0 && cleaned.count('.') == 1
        # Remove comma thousands separators, keep dot as decimal
        cleaned = cleaned.gsub(',', '')
      end
      
      Float(cleaned)
    rescue ArgumentError
      nil
    end

    def parse_date(date_str)
      return nil if date_str.blank?
      
      # Try different date formats
      [
        '%m/%d/%Y', '%m-%d-%Y', '%m.%d.%Y',
        '%d/%m/%Y', '%d-%m-%Y', '%d.%m.%Y',
        '%Y/%m/%d', '%Y-%m-%d', '%Y.%m.%d',
        '%B %d, %Y', '%b %d, %Y',
        '%d %B %Y', '%d %b %Y'
      ].each do |format|
        begin
          parsed = Date.strptime(date_str, format)
          return parsed if parsed <= Date.current && parsed >= 5.years.ago
        rescue ArgumentError
          next
        end
      end
      
      nil
    end

    def clean_merchant_name(name)
      # Remove common receipt artifacts
      cleaned = name.gsub(/[#*]+/, '').strip
      cleaned = cleaned.gsub(/\s+/, ' ')
      
      # Capitalize properly
      cleaned.split.map(&:capitalize).join(' ')
    end

    def extract_currency
      # Check for currency patterns in the text
      CURRENCY_PATTERNS.each do |pattern|
        matches = text.scan(pattern)
        next if matches.empty?
        
        # Extract currency symbol or code from the match
        matches.each do |match|
          currency_text = match.is_a?(Array) ? match.first : match
          
          # Extract currency symbol/code from the match
          currency_symbol = currency_text.match(/[$€£¥₹]|[A-Z]{3}/)&.to_s
          next unless currency_symbol
          
          # Map to standard currency code
          mapped_currency = CURRENCY_MAPPING[currency_symbol.upcase]
          return mapped_currency if mapped_currency
        end
      end
      
      # Default to USD if no currency found
      'USD'
    end
end
