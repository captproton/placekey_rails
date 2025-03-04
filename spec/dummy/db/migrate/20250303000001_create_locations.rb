class CreateLocations < ActiveRecord::Migration[6.1]
  def change
    create_table :locations do |t|
      t.string :name
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      t.string :placekey
      t.string :street_address
      t.string :city
      t.string :region
      t.string :postal_code
      t.string :country, default: 'US'

      t.timestamps
    end

    add_index :locations, :placekey
    add_index :locations, [ :latitude, :longitude ]
  end
end
