class AddPlacekeyTo<%= @model_table_name.camelize %> < ActiveRecord::Migration[<%= Rails.version.to_f %>]
  def change
    add_column :<%= @model_table_name %>, :placekey, :string
    add_index :<%= @model_table_name %>, :placekey
  end
end