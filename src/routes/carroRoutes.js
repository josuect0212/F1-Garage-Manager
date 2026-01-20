const { Router } = require('express');
const router = Router();
const carroCtrl = require('../controllers/carroController');

// Acciones Técnicas (POST)
router.post('/carros/instalar', carroCtrl.instalarParte);
router.post('/carros/reemplazar', carroCtrl.reemplazarParte);

// Consultas de Estado (GET)
router.get('/carros/estado-general', carroCtrl.getEstadoCarros);
router.get('/carros/detalle-piezas', carroCtrl.getPartesPorCarro);
router.get('/carros/faltantes', carroCtrl.getPartesFaltantes);
router.get('/carros/disponibles-almacen', carroCtrl.getPartesSinInstalar);

module.exports = router;