const { getConnection, sql } = require('../database/connection');

/**
 * Autenticación de usuarios (Login)
 */
const loginUsuario = async (req, res) => {
  const { correo, contrasena } = req.body;
  if (!correo || !contrasena) {
    return res.status(400).json({ message: "Correo y contraseña son requeridos" });
  }
  try {
    const pool = await getConnection();
    const result = await pool.request()
      .input('correo', sql.VarChar, correo)
      .input('pass', sql.VarChar, contrasena)
      .query("SELECT Rol, Nombre_Completo, Habilidad FROM Usuario WHERE Correo = @correo AND Contrasena = @pass");

    if (result.recordset.length > 0) {
      res.json({
        message: "Login exitoso",
        ...result.recordset[0]
      });
    } else {
      res.status(401).json({ message: "Correo o contraseña incorrectos" });
    }
  } catch (error) {
    res.status(500).json({ message: "Error en el servidor", error: error.message });
  }
};

/**
 * Obtener lista básica (Para administración rápida)
 */
const getUsuarios = async (req, res) => {
  try {
    const pool = await getConnection();
    const result = await pool.request().query("SELECT Correo, Rol, Habilidad FROM Usuario");
    res.json(result.recordset);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

/**
 * Reporte Detallado: Usuarios + Equipos (Vista SQL)
 */
const getUsuariosDetalleFull = async (req, res) => {
  try {
    const pool = await getConnection();
    const result = await pool.request().query("SELECT * FROM vw_UsuariosConEquipos");
    res.json(result.recordset);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

/**
 * Registro de nuevo usuario (Sign Up)
 */
const crearUsuario = async (req, res) => {
  const { correo, contrasena, nombre, rol, habilidad } = req.body;
  try {
    const pool = await getConnection();
    await pool.request()
      .input('correo', sql.VarChar, correo)
      .input('pass', sql.VarChar, contrasena)
      .input('nombre', sql.VarChar, nombre)
      .input('rol', sql.VarChar, rol)
      .input('habilidad', sql.Int, habilidad)
      .query("INSERT INTO Usuario (Correo, Contrasena, Nombre_Completo, Rol, Habilidad) VALUES (@correo, @pass, @nombre, @rol, @habilidad)");

    res.status(201).json({ message: "Usuario creado correctamente" });
  } catch (error) {
    res.status(400).json({ message: "Error al crear usuario", error: error.message });
  }
};

module.exports = {
  loginUsuario,
  getUsuarios,
  getUsuariosDetalleFull,
  crearUsuario
};