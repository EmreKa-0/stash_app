
const { onRequest } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');
const axios = require('axios');
const cors = require('cors')({ origin: true });

// Secret olarak API key tanımla
const googleMapsApiKey = defineSecret('GOOGLE_MAPS_API_KEY');

exports.api = onRequest(
  {
    secrets: [googleMapsApiKey],
    timeoutSeconds: 60,
    memory: '256MiB',
    cors: true
  },
  (req, res) => {
    return cors(req, res, async () => {
      // Sadece POST isteklerini kabul et
      if (req.method !== 'POST') {
        console.log('❌ Wrong method:', req.method);
        return res.status(405).json({ 
          success: false, 
          error: 'Method not allowed. Use POST.' 
        });
      }

      try {
        const { address, platform } = req.body;
        
        console.log('📡 Received request:', { address, platform });
        
        if (!address) {
          console.log('❌ Address missing');
          return res.status(400).json({ 
            success: false, 
            error: 'Address is required' 
          });
        }

        // API Key'i al (Secret Manager'dan)
        const apiKey = googleMapsApiKey.value();
        
        if (!apiKey) {
          console.error('❌ API Key not configured!');
          return res.status(500).json({ 
            success: false, 
            error: 'Server configuration error: API Key missing' 
          });
        }

        console.log('✅ API Key found, calling Google Maps Geocoding API...');

        // Google Maps Geocoding API'yi çağır
        const response = await axios.get(
          'https://maps.googleapis.com/maps/api/geocode/json',
          {
            params: {
              address: address,
              key: apiKey
            },
            timeout: 10000 // 10 saniye timeout
          }
        );

        console.log('📍 Google Maps API response status:', response.data.status);

        if (response.data.status === 'OK' && response.data.results.length > 0) {
          const location = response.data.results[0].geometry.location;
          const result = {
            success: true,
            lat: location.lat,
            lng: location.lng,
            formatted_address: response.data.results[0].formatted_address
          };
          
          console.log('✅ Geocoding success:', result);
          return res.status(200).json(result);
        } else if (response.data.status === 'ZERO_RESULTS') {
          console.log('❌ No results found for address:', address);
          return res.status(404).json({
            success: false,
            error: 'Address not found'
          });
        } else if (response.data.status === 'REQUEST_DENIED') {
          console.error('❌ Google Maps API request denied. Check API key restrictions.');
          console.error('Error message:', response.data.error_message);
          return res.status(403).json({
            success: false,
            error: 'API request denied. Check API key configuration.',
            details: response.data.error_message
          });
        } else {
          console.log('❌ Geocoding failed:', response.data.status);
          return res.status(400).json({
            success: false,
            error: `Geocoding failed: ${response.data.status}`
          });
        }
      } catch (error) {
        console.error('❌ Error:', error.message);
        if (error.response) {
          console.error('Error response:', error.response.data);
        }
        return res.status(500).json({
          success: false,
          error: error.message
        });
      }
    });
  }
);
