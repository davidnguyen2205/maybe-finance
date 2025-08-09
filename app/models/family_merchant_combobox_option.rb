class FamilyMerchantComboboxOption
  include ActiveModel::Model

  attr_accessor :name, :id

  def display
    name
  end

  def value
    name
  end

  def to_combobox_display
    name
  end

  def data
    { merchant_id: id }
  end
end
