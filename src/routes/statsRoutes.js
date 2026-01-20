const { Router } = require('express');
const router = Router();
const statsCtrl = require('../controllers/statsController');

// Reportes Financieros
router.get('/stats/presupuestos', statsCtrl.getPresupuestos);
router.get('/stats/gastos-detalle', statsCtrl.getGastosDetallados);

// Reportes de Inventario
router.get('/stats/inventario-general', statsCtrl.getInventario);
router.get('/stats/inventario-equipos', statsCtrl.getInventarioPorEquipo);

module.exports = router;