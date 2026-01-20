const { getConnection } = require('../database/connection');

/**
 * Vista: Presupuesto disponible por equipo.
 * Consulta 'vw_PresupuestoEquipos'.
 */
const getPresupuestos = async (req, res) => {
  try {
    const pool = await getConnection();
    const result = await pool.request().query("SELECT * FROM vw_PresupuestoEquipos");
    res.json(result.recordset);
  } catch (error) { res.status(500).json({ error: error.message }); }
};

/**
 * Vista: Inventario general (Stock total e ítems).
 * Consulta 'vw_InventarioConUso'.
 */
const getInventario = async (req, res) => {
  try {
    const pool = await getConnection();
    const result = await pool.request().query("SELECT * FROM vw_InventarioConUso");
    res.json(result.recordset);
  } catch (error) { res.status(500).json({ error: error.message }); }
};

/**
 * Vista: Desglose de gastos financieros por equipo y categoría.
 * Consulta 'vw_GastosPorEquipoCategoria'.
 */
const getGastosDetallados = async (req, res) => {
  try {
    const pool = await getConnection();
    const result = await pool.request().query("SELECT * FROM vw_GastosPorEquipoCategoria");
    res.json(result.recordset);
  } catch (error) { res.status(500).json({ error: error.message }); }
};

/**
 * Vista: Inventario específico filtrado por equipo.
 * Consulta 'vw_InventarioPorEquipo'.
 */
const getInventarioPorEquipo = async (req, res) => {
  try {
    const pool = await getConnection();
    const result = await pool.request().query("SELECT * FROM vw_InventarioPorEquipo");
    res.json(result.recordset);
  } catch (error) { res.status(500).json({ error: error.message }); }
};

module.exports = {
  getPresupuestos,
  getInventario,
  getGastosDetallados,
  getInventarioPorEquipo
};