const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
require('dotenv').config();

const usuarioRoutes = require('./src/routes/usuarioRoutes');
const compraRoutes = require('./src/routes/compraRoutes');
const carroRoutes = require('./src/routes/carroRoutes');
const statsRoutes = require('./src/routes/statsRoutes');

const app = express();

// Middlewares
app.use(cors());
app.use(morgan('dev'));
app.use(express.json());

app.use('/api', usuarioRoutes);
app.use('/api', compraRoutes);
app.use('/api', carroRoutes);
app.use('/api', statsRoutes);

const PORT = process.env.PORT;

app.listen(PORT, () => {
    console.log(`🚀 Servidor activo en http://localhost:${PORT}`);
});