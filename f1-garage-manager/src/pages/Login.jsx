import { useState } from "react";
import { login } from "../api/auth";

export default function Login({ setUser, goRegister }) {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");

  const handleSubmit = async e => {
    e.preventDefault();
    try {
      const user = await login({ email, password });
      setUser(user);
    } catch {
      setError("Credenciales incorrectas");
    }
  };

  return (
    <div style={styles.container}>
      <form onSubmit={handleSubmit} style={styles.card}>
        <h2>Login</h2>

        <input
          placeholder="Email"
          value={email}
          onChange={e => setEmail(e.target.value)}
        />

        <input
          type="password"
          placeholder="Password"
          value={password}
          onChange={e => setPassword(e.target.value)}
        />

        <button>Ingresar</button>

        {error && <p style={{ color: "red" }}>{error}</p>}

        <p onClick={goRegister} style={{ cursor: "pointer" }}>
          ¿No tenés cuenta? Registrate
        </p>
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
    background: "linear-gradient(120deg,#1e3c72,#2a5298)"
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
