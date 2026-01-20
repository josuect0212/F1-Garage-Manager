const { getConnection, sql } = require('../database/connection');

/**
 * Procedimiento: Instala una parte específica en un chasis.
 * Ejecuta 'sp_InstalarParteEnCarro'.
 */
const instalarParte = async (req, res) => {
  const { idParte, noChasis, usuario } = req.body;
  try {
    const pool = await getConnection();
    const result = await pool.request()
      .input('ID_Parte', sql.Int, idParte)
      .input('No_Chasis', sql.VarChar(50), noChasis)
      .input('Usuario_Ejecutor', sql.VarChar(100), usuario)
      .output('Resultado', sql.VarChar(500))
      .execute('sp_InstalarParteEnCarro');
    res.json({ message: result.output.Resultado });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

/**
 * Procedimiento: Reemplaza una parte existente por una nueva en el chasis.
 * Ejecuta 'sp_ReemplazarParte'.
 */
const reemplazarParte = async (req, res) => {
  const { idParteNueva, noChasis, usuario } = req.body;
  try {
    const pool = await getConnection();
    const result = await pool.request()
      .input('ID_Parte_Nueva', sql.Int, idParteNueva)
      .input('No_Chasis', sql.VarChar(50), noChasis)
      .input('Usuario_Ejecutor', sql.VarChar(100), usuario)
      .output('Resultado', sql.VarChar(500))
      .execute('sp_ReemplazarParte');
    res.json({ message: result.output.Resultado });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

/**
 * Vista: Estado general del carro (Stats totales y progreso).
 * Consulta 'vw_EstadoCompletoCarro'.
 */
const getEstadoCarros = async (req, res) => {
  try {
    const pool = await getConnection();
    const result = await pool.request().query("SELECT * FROM vw_EstadoCompletoCarro");
    res.json(result.recordset);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

/**
 * Vista: Lista detallada de piezas instaladas por cada carro.
 * Consulta 'vw_PartesInstaladasPorCarro'.
 */
const getPartesPorCarro = async (req, res) => {
  try {
    const pool = await getConnection();
    const result = await pool.request().query("SELECT * FROM vw_PartesInstaladasPorCarro");
    res.json(result.recordset);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

/**
 * Vista: Reporte de categorías que faltan para completar el monoplaza.
 * Consulta 'vw_PartesFaltantesPorCarro'.
 */
const getPartesFaltantes = async (req, res) => {
  try {
    const pool = await getConnection();
    const result = await pool.request().query("SELECT * FROM vw_PartesFaltantesPorCarro");
    res.json(result.recordset);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

/**
 * Vista: Partes compradas que aún no han sido instaladas en ningún chasis.
 * Consulta 'vw_PartesDisponiblesSinInstalar'.
 */
const getPartesSinInstalar = async (req, res) => {
  try {
    const pool = await getConnection();
    const result = await pool.request().query("SELECT * FROM vw_PartesDisponiblesSinInstalar");
    res.json(result.recordset);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

module.exports = {
  instalarParte,
  reemplazarParte,
  getEstadoCarros,
  getPartesPorCarro,
  getPartesFaltantes,
  getPartesSinInstalar
};