class Vehicle
  include Ripple::Document

  property :license, String, presence: true, index: true
  property :region, String

  property :serial, String, presence: true, index: true
  property :name, String

  one :model, using: :stored_key # adds a model_key property

  # looks for vehicle_key if Option is a Document, or
  # adds an options collection if Option is an EmbeddedDocument
  many :options

  index :region_license, String do
    "#{region}-#{license}"
  end

  def self.find_by_region_and_license(region, license)
    index_key = "#{region}-#{license}"

    # find_by returns an array
    candidates = find_by :region_license, index_key
    return candidates.first
  end
end
