const axios = require('axios');
require('dotenv').config();

async function testGoogleAuth() {
    try {
        // Este es un token de ejemplo. En una aplicación real, obtendrías este token del cliente
        const testToken = 'TU_TOKEN_DE_GOOGLE_AQUI';
        
        const response = await axios.post('http://localhost:3000/api/test/verify-google-token', {
            token: testToken
        });
        
        console.log('Respuesta del servidor:', response.data);
    } catch (error) {
        console.error('Error en la prueba:', error.response ? error.response.data : error.message);
    }
}

testGoogleAuth(); 