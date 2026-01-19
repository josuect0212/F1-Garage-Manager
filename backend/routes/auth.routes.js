const express = require("express");
const router = express.Router();
const User = require("../models/User");

// REGISTER
router.post("/register", async (req, res) => {
  const { nombre, email, password, rol } = req.body;

  try {
    const exists = await User.findOne({ email });
    if (exists) {
      return res.status(400).json({ error: "Usuario ya existe" });
    }

    const user = new User({
      nombre,
      email,
      password, // sin encriptar (Entregable 3)
      rol
    });

    await user.save();

    res.json({ message: "Usuario creado" });
  } catch (err) {
    res.status(500).json({ error: "Error al registrar" });
  }
});

// LOGIN
router.post("/login", async (req, res) => {
  const { email, password } = req.body;

  try {
    const user = await User.findOne({ email, password });

    if (!user) {
      return res.status(400).json({ error: "Credenciales inválidas" });
    }

    res.json({
      nombre: user.nombre,
      email: user.email,
      rol: user.rol
    });
  } catch (err) {
    res.status(500).json({ error: "Error login" });
  }
});

module.exports = router;
