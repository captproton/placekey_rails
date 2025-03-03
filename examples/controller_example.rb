# Example LocationsController using Placekey functionality
class LocationsController < ApplicationController
  before_action :set_location, only: [ :show, :edit, :update, :destroy, :nearby ]

  # GET /locations
  def index
    @locations = Location.all
  end

  # GET /locations/1
  def show
    # No special placekey logic needed
  end

  # GET /locations/new
  def new
    @location = Location.new
  end

  # GET /locations/1/edit
  def edit
    # No special placekey logic needed
  end

  # POST /locations
  def create
    @location = Location.new(location_params)

    if @location.save
      redirect_to @location, notice: 'Location was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /locations/1
  def update
    if @location.update(location_params)
      redirect_to @location, notice: 'Location was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /locations/1
  def destroy
    @location.destroy
    redirect_to locations_url, notice: 'Location was successfully destroyed.'
  end

  # GET /locations/1/nearby
  # Find locations near this one
  def nearby
    distance = params[:distance].to_i
    distance = 1000 if distance <= 0 # Default to 1000 meters

    @nearby_locations = Location.within_distance(@location.placekey, distance)

    respond_to do |format|
      format.html
      format.json { render json: @nearby_locations }
    end
  end

  # GET /locations/search
  # Search locations by address
  def search
    @results = []

    if params[:address].present?
      # Look up a placekey for the address
      result = PlacekeyRails.lookup_placekey(
        street_address: params[:address],
        city: params[:city],
        region: params[:region],
        postal_code: params[:postal_code]
      )

      if result && result["placekey"].present?
        # Find locations with this placekey
        exact_match = Location.find_by(placekey: result["placekey"])
        @results << exact_match if exact_match

        # If no exact match, find nearby locations
        if @results.empty?
          @results = Location.within_distance(result["placekey"], 500)
        end
      end
    end

    respond_to do |format|
      format.html
      format.json { render json: @results }
    end
  end

  # GET /locations/map
  # Show locations on a map
  def map
    # Get locations based on bounds or other criteria
    @locations = if params[:bounds].present?
                   # Parse bounds as [south, west, north, east]
                   bounds = params[:bounds].split(',').map(&:to_f)
                   bounding_box_wkt = "POLYGON((#{bounds[1]} #{bounds[0]}, #{bounds[3]} #{bounds[0]}, #{bounds[3]} #{bounds[2]}, #{bounds[1]} #{bounds[2]}, #{bounds[1]} #{bounds[0]}))"
                   Location.within_wkt(bounding_box_wkt)
    else
                   Location.with_placekey.limit(100)
    end

    # Prepare GeoJSON for the map
    @geojson = {
      type: "FeatureCollection",
      features: @locations.map(&:to_geojson).compact
    }

    respond_to do |format|
      format.html
      format.json { render json: @geojson }
    end
  end

  # POST /locations/bulk_geocode
  # Admin action to geocode locations without placekeys
  def bulk_geocode
    authorize! :admin, Location # Using CanCanCan or similar for authorization

    count = params[:count].to_i
    count = 100 if count <= 0 # Default to 100 records

    result = Location.batch_geocode_addresses(batch_size: count) do |processed, successful|
      logger.info "Geocoded #{processed} locations (#{successful} successful)"
    end

    redirect_to locations_path, notice: "Processed #{result[:processed]} locations (#{result[:successful]} successfully geocoded)"
  end

  private
    def set_location
      @location = Location.find(params[:id])
    end

    def location_params
      params.require(:location).permit(
        :name, :description,
        :street_address, :city, :region, :postal_code, :country_code,
        :latitude, :longitude, :placekey,
        :tags
      )
    end
end
