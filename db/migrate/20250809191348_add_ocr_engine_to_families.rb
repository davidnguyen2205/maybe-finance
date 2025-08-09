class AddOcrEngineToFamilies < ActiveRecord::Migration[7.2]
  def change
    add_column :families, :ocr_engine, :string, default: "tesseract"
  end
end
