class Create<%= @model_table_name.camelize %> < ActiveRecord::Migration[<%= Rails.version.to_f %>]
  def change
    create_table :<%= @model_table_name %> do |t|
      t.string :name
      t.text :description
      t.string :street_address
      t.string :city
      t.string :region
      t.string :postal_code
      t.string :iso_country_code
      t.float :latitude
      t.float :longitude
      t.string :placekey
      t.boolean :featured, default: false

      t.timestamps
    end
    
    add_index :<%= @model_table_name %>, :placekey
    add_index :<%= @model_table_name %>, [:latitude, :longitude]
  end
end