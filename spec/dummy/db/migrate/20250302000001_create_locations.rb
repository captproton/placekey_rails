class CreateLocations < ActiveRecord::Migration[8.0]
  def change
    create_table :locations do |t|
      t.string :name
      t.float :latitude
      t.float :longitude
      t.string :placekey
      t.string :street_address
      t.string :city
      t.string :region
      t.string :postal_code
      t.string :country
      
      t.timestamps
    end
    
    add_index :locations, :placekey
  end
end