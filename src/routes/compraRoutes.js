const { Router } = require('express');
const router = Router();
const {
  comprarParte,
  deshacerCompra,
  getHistorialCompras
} = require('../controllers/compraController');

router.post('/compras/ejecutar', comprarParte);
router.post('/compras/revertir', deshacerCompra);
router.get('/compras/historial', getHistorialCompras);

module.exports = router;