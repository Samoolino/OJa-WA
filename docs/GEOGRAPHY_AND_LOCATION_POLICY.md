# Geography and Location Policy

## Coordinate model

OJa-WA stores a vendor store's physical point as WGS84 decimal latitude/longitude:
- latitude: -90 to 90
- longitude: -180 to 180
- seven decimal places in the database

Coordinates identify a point; they do not by themselves establish legal address, jurisdiction, eligibility, or proof that a person was physically present.

## Geographic classification

A store can additionally carry normalized classification:
- country_code: ISO 3166-1 alpha-2
- admin_area_1_code: first-level administrative area
- admin_area_2_code: second-level administrative area
- locality: city/town/locality
- postal_code
- timezone

The classification is kept separate from raw coordinates so policy can be expressed as country, state/province, district, locality, or a combination.

## Geocoding provenance

When coordinates are converted into an address/classification, OJa-WA should retain:
- geocoding_source
- geocoding_accuracy
- geocoded_at

A geocoder result is classification evidence, not cryptographic proof.

## Geofencing

geo_fence is a policy boundary. It may later contain a versioned polygon or multipolygon and policy metadata. Point-in-polygon evaluation belongs in a spatial policy service/PostGIS layer rather than application string comparison.

Recommended decision inputs:
- store coordinates
- transaction coordinates, when available
- normalized geographic classification
- fence version
- evaluation timestamp
- source/provenance
- accuracy/uncertainty

## GPS and transaction location

GPS is policy telemetry. A device-reported location must not be treated as automatically authoritative. Where location affects allocation authorization, the decision record should retain the evaluated location source, timestamp, accuracy and policy/fence version.

## Privacy boundary

Do not place precise beneficiary GPS, NIN, BVN, or other sensitive identity data in QR codes, allocation codes, URLs, or public identifiers. Store only the minimum location and identity assertions required for the policy decision.

## Lagos example

A Lagos store could be classified at multiple levels, for example:
NG -> LA -> <local government area> -> <locality>

The exact administrative code should come from the selected authoritative geocoding/address source; it should not be inferred from latitude/longitude alone inside checkout code.

## Checkout use

Checkout should ask:
Does this basket satisfy the allocation's geographic policy at this store and evaluation time?

It should not ask:
Does this GPS coordinate prove the beneficiary is in the store?

This distinction keeps location eligibility separate from identity verification and financial authorization.
