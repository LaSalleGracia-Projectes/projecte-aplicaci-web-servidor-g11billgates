const express = require('express');
const router = express.Router();
const usuarioController = require('../controllers/usuarioController');

// Rutas de verificación por email
router.post('/send-verification', usuarioController.sendVerificationEmail);
router.post('/verify-code', usuarioController.verifyCode);

module.exports = router; 