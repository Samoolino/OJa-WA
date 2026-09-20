module Spree
  class GeoPolicyEvidenceCommand
    def self.call(allocation:, store:, geo_context:, correlation_id:)
      policy = allocation.metadata.fetch("geo_policy", {})
      result = Spree::GeoPolicyEngine.evaluate(policy:, geo_context: geo_context.merge("store_id" => store.id.to_s))
      {
        allowed: result.allowed,
        reason: result.reason,
        classification: result.classification,
        evidence: result.evidence.merge(
          "store_coordinates" => { "latitude" => store.latitude, "longitude" => store.longitude }.compact,
          "geocoding" => {
            "source" => store.geocoding_source,
            "accuracy" => store.geocoding_accuracy,
            "geocoded_at" => store.geocoded_at&.iso8601
          }.compact,
          "correlation_id" => correlation_id
        )
      }
    end
  end
end
