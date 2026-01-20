const { getConnection, sql } = require('../database/connection');

/**
 * Procedimiento: Comprar parte con validaciones de presupuesto y stock.
 * Ejecuta el SP 'sp_ComprarParteConValidacion'.
 */
const comprarParte = async (req, res) => {
  const { idParte, tipo, p, a, m, equipo, idItem, usuario, chasis } = req.body;
  try {
    const pool = await getConnection();
    const result = await pool.request()
      .input('ID_Parte', sql.Int, idParte)
      .input('Tipo_Parte', sql.VarChar(50), tipo)
      .input('p_stat', sql.Int, p)
      .input('a_stat', sql.Int, a)
      .input('m_stat', sql.Int, m)
      .input('Nombre_Equipo', sql.VarChar(100), equipo)
      .input('ID_Item', sql.Int, idItem)
      .input('Usuario_Ejecutor', sql.VarChar(100), usuario)
      .input('No_Chasis', sql.VarChar(50), chasis || null)
      .output('Resultado', sql.VarChar(500))
      .execute('sp_ComprarParteConValidacion');

    res.json({ message: result.output.Resultado });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

/**
 * Procedimiento: Revertir una compra y devolver dinero/stock.
 * Ejecuta el SP 'sp_DeshacerCompraSegura'.
 */
const deshacerCompra = async (req, res) => {
  const { idParte, usuario } = req.body;
  try {
    const pool = await getConnection();
    const result = await pool.request()
      .input('ID_Parte', sql.Int, idParte)
      .input('Usuario_Ejecutor', sql.VarChar(100), usuario)
      .output('Resultado', sql.VarChar(500))
      .execute('sp_DeshacerCompraSegura');

    res.json({ message: result.output.Resultado });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

/**
 * Vista: Historial detallado de compras.
 * Consulta la vista 'vw_HistorialComprasDetallado'.
 */
const getHistorialCompras = async (req, res) => {
  try {
    const pool = await getConnection();
    if (!pool) return res.status(500).json({ message: "Error de conexión" });

    const result = await pool.request()
      .query("SELECT * FROM vw_HistorialComprasDetallado ORDER BY Fecha_Compra DESC");

    res.json(result.recordset);
  } catch (error) {
    res.status(500).json({
      message: "Error al obtener el historial",
      error: error.message
    });
  }
};

module.exports = {
  comprarParte,
  deshacerCompra,
  getHistorialCompras
};