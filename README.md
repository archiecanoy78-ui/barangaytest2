# Barangay Putho-Tuntungin Boundary Map

This is a plain HTML + JavaScript + Leaflet.js app. It serves a web map that is restricted to Barangay Putho-Tuntungin, Los Baños, Laguna, Philippines.

## What is included

- A static OSM-derived GeoJSON at `data/putho-tuntungin.geojson`
- A Leaflet map locked to the barangay boundary with a red-and-white dashed border
- A dark outside mask so everything beyond the barangay is dimmed
- A reset view button and optional base-layer toggle
- Turf.js point-in-polygon checks to reject clicks or markers outside the barangay

## Boundary source

The official polygon was fetched from Nominatim using the official boundary GeoJSON output for:

`Putho-Tuntungin, Los Baños, Laguna, Philippines`

The result was saved locally to `data/putho-tuntungin.geojson`, so the app does not query Nominatim or Overpass at runtime.

## Local setup

1. Install dependencies:
  `npm install`
2. Start the app:
  `node server.js`
3. Open:
  `http://localhost:3000/`

## Notes

- The default tiles are standard OpenStreetMap tiles with the required attribution: `© OpenStreetMap contributors`.
- The optional Esri satellite layer is included for reference and matches the map style in the screenshot.
- For production traffic, use a proper tile provider or a commercial mapping plan that complies with usage policies; avoid bulk scraping or unlicensed tile use.
- **Logcat Filtering Note**: Google ML Kit inside Google Play Services outputs harmless `ThickFaceDetector` debug/info logs on Android. To filter out these lines in Android Studio Logcat, use the filter expression: `level:info -tag:ThickFaceDetector`.
