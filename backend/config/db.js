const mongoose = require("mongoose");

const connectDB = async () => {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log("MongoDB Atlas conectado");
  } catch (error) {
    console.error("Error MongoDB Atlas", error);
    process.exit(1);
  }
};

module.exports = connectDB;
