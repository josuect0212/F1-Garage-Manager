const mongoose = require("mongoose");

const UserSchema = new mongoose.Schema({
  nombre: {
    type: String,
    required: true
  },
  email: {
    type: String,
    required: true,
    unique: true
  },
  password: {
    type: String,
    required: true
  },
  rol: {
    type: String,
    enum: ["Admin", "Engineer", "Driver"],
    required: true
  }
});

module.exports = mongoose.model("User", UserSchema);
