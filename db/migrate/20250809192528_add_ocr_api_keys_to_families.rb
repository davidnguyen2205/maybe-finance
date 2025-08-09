class AddOcrApiKeysToFamilies < ActiveRecord::Migration[7.2]
  def change
    add_column :families, :google_vision_api_key, :text
    add_column :families, :aws_textract_api_key, :text
    add_column :families, :gemini_api_key, :text
  end
end
