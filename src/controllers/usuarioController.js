const { getConnection, sql } = require('../database/connection');

/**
 * Autenticación de usuarios (Login)
 * Paso 1: Valida credenciales contra la tabla Usuario.
 * Paso 2: Busca detalles extendidos en la vista vw_UsuariosConEquipos.
 */
const loginUsuario = async (req, res) => {
  const { correo, contrasena } = req.body;

  if (!correo || !contrasena) {
    return res.status(400).json({ message: "Correo y contraseña son requeridos" });
  }

  try {
    const pool = await getConnection();

    // --- PASO 1: VALIDACIÓN DE CREDENCIALES ---
    const authResult = await pool.request()
      .input('correo', sql.VarChar, correo)
      .input('pass', sql.VarChar, contrasena)
      .query("SELECT Correo FROM Usuario WHERE Correo = @correo AND Contrasena = @pass");

    if (authResult.recordset.length === 0) {
      return res.status(401).json({ message: "Correo o contraseña incorrectos" });
    }

    // --- PASO 2: OBTENER DATOS DE LA VISTA ---
    // Como ya validamos la contraseña, ahora traemos los datos públicos/técnicos de la vista
    const detailResult = await pool.request()
      .input('correo', sql.VarChar, correo)
      .query(`
        SELECT 
          Correo, 
          Nombre_Completo, 
          Rol_Sistema AS Rol, 
          Equipo, 
          Habilidad 
        FROM vw_UsuariosConEquipos 
        WHERE Correo = @correo
      `);

    if (detailResult.recordset.length > 0) {
      res.json({
        message: "Login exitoso",
        ...detailResult.recordset[0]
      });
    } else {
      // Caso borde: Usuario existe en tabla pero no tiene entrada en la vista (ej. error de integridad)
      res.status(404).json({ message: "Usuario validado, pero no se encontró su perfil detallado" });
    }

  } catch (error) {
    console.error("Error en loginUsuario:", error);
    res.status(500).json({ message: "Error en el servidor", error: error.message });
  }
};

/**
 * Obtener lista básica de usuarios (Desde la tabla Usuario)
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
 * Reporte Detallado: Usuarios + Equipos (Desde la vista SQL)
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
 * Maneja las reglas: Admin sin equipo, Habilidad solo Conductor.
 */
const crearUsuario = async (req, res) => {
  // 1. Extraemos los datos (Asegúrate de que estos nombres coincidan con el Front)
  const { correo, contrasena, nombre, rol, habilidad, equipo } = req.body;
  console.log("Datos recibidos en el body:", req.body);

  if (!correo || !contrasena || !nombre || !rol) {
    // MODIFICA EL MENSAJE TEMPORALMENTE PARA SABER QUÉ FALTA
    return res.status(400).json({
      message: "Faltan datos obligatorios",
      recibido: { correo, contrasena, nombre, rol }
    });
  }

  try {
    const pool = await getConnection();
    const transaction = new sql.Transaction(pool);
    await transaction.begin();

    // REGLA: Solo Conductor tiene habilidad (0-100), los demás NULL
    const habilidadFinal = (rol === "Conductor") ? habilidad : null;

    // 2. Insertar en la tabla Usuario
    await transaction.request()
      .input('correo', sql.VarChar, correo)
      .input('pass', sql.VarChar, contrasena)
      .input('nombre', sql.VarChar, nombre)
      .input('rol', sql.VarChar, rol)
      .input('habilidad', sql.Int, habilidadFinal)
      .query(`INSERT INTO Usuario (Correo, Contrasena, Nombre_Completo, Rol, Habilidad) 
              VALUES (@correo, @pass, @nombre, @rol, @habilidad)`);

    // 3. Vincular con Equipo SOLO si NO es Admin
    if (rol !== "Admin" && equipo) {
      await transaction.request()
        .input('correo', sql.VarChar, correo)
        .input('equipo', sql.VarChar, equipo)
        .input('rol_eq', sql.VarChar, rol)
        .query(`INSERT INTO Usuario_Equipo (Correo_Usuario_FK, Nombre_Equipo_FK, Rol_En_Equipo) 
                VALUES (@correo, @equipo, @rol_eq)`);
    }

    await transaction.commit();
    res.status(201).json({ message: "Usuario creado correctamente" });

  } catch (error) {
    if (transaction) await transaction.rollback();
    res.status(500).json({ message: "Error al crear usuario", error: error.message });
  }
};

module.exports = {
  loginUsuario,
  getUsuarios,
  getUsuariosDetalleFull,
  crearUsuario
};