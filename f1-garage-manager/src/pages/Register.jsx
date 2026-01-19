import { useState } from "react";
import { register } from "../api/auth";

export default function Register({ goLogin }) {
  const [form, setForm] = useState({
    nombre: "",
    email: "",
    password: "",
    rol: "Engineer"
  });

  const handleSubmit = async e => {
    e.preventDefault();
    await register(form);
    goLogin();
  };

  return (
    <div style={styles.container}>
      <form onSubmit={handleSubmit} style={styles.card}>
        <h2>Register</h2>

        <input placeholder="Nombre"
          onChange={e => setForm({ ...form, nombre: e.target.value })}
        />

        <input placeholder="Email"
          onChange={e => setForm({ ...form, email: e.target.value })}
        />

        <input type="password" placeholder="Password"
          onChange={e => setForm({ ...form, password: e.target.value })}
        />

        <select
          onChange={e => setForm({ ...form, rol: e.target.value })}
        >
          <option value="Engineer">Engineer</option>
          <option value="Driver">Driver</option>
          <option value="Admin">Admin</option>
        </select>

        <button>Registrar</button>
      </form>
    </div>
  );
}

const styles = {
  container: {
    height: "100vh",
    display: "flex",
    justifyContent: "center",
    alignItems: "center",
    background: "linear-gradient(120deg,#232526,#414345)"
  },
  card: {
    background: "#fff",
    padding: 30,
    borderRadius: 8,
    display: "flex",
    flexDirection: "column",
    gap: 10,
    width: 300
  }
};
