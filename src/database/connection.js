const sql = require('mssql');
require('dotenv').config();

const dbSettings = {
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    server: process.env.DB_SERVER,
    database: process.env.DB_NAME,
    // El puerto por defecto es 1433, pero lo hacemos explícito
    port: 1433,
    options: {
        encrypt: false, // Cambiado a false para conexiones locales
        trustServerCertificate: true,
        // Esto ayuda si usas una instancia con nombre como ERICK\SQLEXPRESS
        enableArithAbort: true
    },
    pool: {
        max: 10,
        min: 0,
        idleTimeoutMillis: 30000
    }
};

// Variable para guardar la conexión y no abrir una nueva cada vez
let poolPromise;

async function getConnection() {
    try {
        if (!poolPromise) {
            poolPromise = await sql.connect(dbSettings);
            console.log("✅ Conexión a SQL Server establecida con éxito");
        }
        return poolPromise;
    } catch (error) {
        console.error("❌ ERROR DETALLADO DE CONEXIÓN:");
        console.error("Mensaje:", error.message);
        console.error("Código de error:", error.code);

        // Limpiamos la promesa para que el siguiente intento trate de reconectar
        poolPromise = null;
        return null;
    }
}

module.exports = {
    getConnection,
    sql
};
