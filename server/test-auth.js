const axios = require('axios');
require('dotenv').config();

async function testAuth() {
    try {
        // 1. Probar Google Auth
        console.log('Testing Google Auth...');
        const googleResponse = await axios.post('http://localhost:3001/api/auth/google', {
            token: process.env.TEST_GOOGLE_TOKEN
        });
        console.log('Google Auth Response:', googleResponse.data);

        // 2. Verificar estado de autenticación
        console.log('\nTesting Auth Status...');
        const statusResponse = await axios.get('http://localhost:3001/api/auth/status', {
            headers: {
                'Authorization': `Bearer ${googleResponse.data.token}`
            }
        });
        console.log('Auth Status Response:', statusResponse.data);

        // 3. Probar logout
        console.log('\nTesting Logout...');
        const logoutResponse = await axios.post('http://localhost:3001/api/auth/logout', {}, {
            headers: {
                'Authorization': `Bearer ${googleResponse.data.token}`
            }
        });
        console.log('Logout Response:', logoutResponse.data);

    } catch (error) {
        console.error('Test Error:', error.response ? error.response.data : error.message);
    }
}

// Verificar que las variables de entorno necesarias estén configuradas
const requiredEnvVars = ['GOOGLE_CLIENT_ID', 'JWT_SECRET', 'TEST_GOOGLE_TOKEN'];
const missingVars = requiredEnvVars.filter(varName => !process.env[varName]);

if (missingVars.length > 0) {
    console.error('Error: Faltan las siguientes variables de entorno:');
    missingVars.forEach(varName => console.error(`- ${varName}`));
    console.error('\nPor favor, configura estas variables en tu archivo .env');
    process.exit(1);
}

testAuth(); 
testGoogleAuth(); 