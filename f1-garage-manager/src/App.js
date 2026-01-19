import { useState } from "react";
import Login from "./pages/Login";
import Register from "./pages/Register";
import AdminView from "./views/AdminView";
import EngineerView from "./views/EngineerView";
import DriverView from "./views/DriverView";

function App() {
  const [user, setUser] = useState(null);
  const [showRegister, setShowRegister] = useState(false);

  if (!user) {
    return showRegister ? (
      <Register goLogin={() => setShowRegister(false)} />
    ) : (
      <Login
        setUser={setUser}
        goRegister={() => setShowRegister(true)}
      />
    );
  }

  if (user.rol === "Admin") return <AdminView user={user} />;
  if (user.rol === "Engineer") return <EngineerView user={user} />;
  if (user.rol === "Driver") return <DriverView user={user} />;
}

export default App;
