const { Router } = require('express');
const router = Router();
const userCtrl = require('../controllers/usuarioController');

// Autenticación
router.post('/usuarios/login', userCtrl.loginUsuario);

// Registro
router.post('/usuarios/registro', userCtrl.crearUsuario);

// Consultas
router.get('/usuarios', userCtrl.getUsuarios);
router.get('/usuarios/detalle', userCtrl.getUsuariosDetalleFull);

module.exports = router;