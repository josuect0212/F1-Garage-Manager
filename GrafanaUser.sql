USE F1_Garage_Manager;
GO

-- 1. Crear el Login (Credenciales para entrar al servidor)
CREATE LOGIN GrafanaUser WITH PASSWORD = 'F1Password123!';
GO

-- 2. Crear el Usuario vinculado a la base de datos
CREATE USER GrafanaUser FOR LOGIN GrafanaUser;
GO

-- 3. Darle permisos SOLO de lectura (SELECT)
ALTER ROLE db_datareader ADD MEMBER GrafanaUser;
GO