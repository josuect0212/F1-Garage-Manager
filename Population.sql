USE F1_Garage_Manager;
GO


--- EQUIPOS ---

INSERT INTO Equipo (Nombre_Equipo) VALUES
('Mercedes'),
('Ferrari'),
('Red Bull');
GO


--- CIRCUITOS ---

INSERT INTO Circuito 
(Nombre_Circuito, Distancia_KM, Curvas, Nombre_Equipo_FK) VALUES
('Monza', 5.79, 11, 'Ferrari'),
('Silverstone', 5.89, 18, 'Mercedes'),
('Spa-Francorchamps', 7.00, 20, 'Red Bull');
GO


--- USUARIOS ---
--- Admin, Drivers y Engineers ---

INSERT INTO Usuario (Correo, Contrasena, Nombre_Completo, Rol, Habilidad) VALUES
--- ADMIN ---
('admin@f1.com', 'admin123', 'Administrador General', 'Admin', NULL),

--- DRIVERS ---
('hamilton@mercedes.com', '1234', 'Lewis Hamilton', 'Driver', '95'),
('verstappen@redbull.com', '1234', 'Max Verstappen', 'Driver', '97'),
('leclerc@ferrari.com', '1234', 'Charles Leclerc', 'Driver', '93'),

--- ENGINEERS ---
('eng1@mercedes.com', '1234', 'Engineer Mercedes', 'Engineer', NULL),
('eng2@ferrari.com', '1234', 'Engineer Ferrari', 'Engineer', NULL),
('eng3@redbull.com', '1234', 'Engineer Red Bull', 'Engineer', NULL);
GO


--- RELACION USUARIO - EQUIPO ---

INSERT INTO Usuario_Equipo (Correo_Usuario_FK, Nombre_Equipo_FK, Rol_En_Equipo) VALUES
('hamilton@mercedes.com', 'Mercedes', 'Driver'),
('verstappen@redbull.com', 'Red Bull', 'Driver'),
('leclerc@ferrari.com', 'Ferrari', 'Driver'),

('eng1@mercedes.com', 'Mercedes', 'Engineer'),
('eng2@ferrari.com', 'Ferrari', 'Engineer'),
('eng3@redbull.com', 'Red Bull', 'Engineer');
GO


--- CARROS ---

INSERT INTO Carro 
(No_Chasis, Nombre_Equipo_FK, PU, Aerodinamica, Neumaticos, Suspension, Caja_Cambios) VALUES
('W14',  'Mercedes', 'PU1', 'Alta',  'Soft',   'Media', 'Auto'),
('RB19', 'Red Bull', 'PU2', 'Alta',  'Soft',   'Media', 'Auto'),
('SF23', 'Ferrari', 'PU3', 'Media', 'Medium', 'Media', 'Manual');
GO


--- ASIGNAR PILOTOS A CARROS ---

INSERT INTO Usuario_Carro (Correo_Usuario_FK, No_Chasis_FK) VALUES
('hamilton@mercedes.com', 'W14'),
('verstappen@redbull.com', 'RB19'),
('leclerc@ferrari.com', 'SF23');
GO


--- INVENTARIO GENERAL ---

INSERT INTO Inventario_General (ID_Item, Categoria, Precio, Stock) VALUES
(1, 'Motor',        500000.00, 10),
(2, 'Aleron',        150000.00, 10),
(3, 'Suspension',    120000.00, 10),
(4, 'Caja',          300000.00, 10),
(5, 'Neumaticos',     80000.00, 10);
GO


--- PARTES (5 por carro) ---
--- MERCEDES ---
INSERT INTO Parte VALUES
(1, 'Motor',      8, 2, 3, 'Mercedes', 'W14', 1),
(2, 'Aleron',     4, 7, 2, 'Mercedes', 'W14', 2),
(3, 'Suspension', 5, 4, 6, 'Mercedes', 'W14', 3),
(4, 'Caja',       6, 3, 5, 'Mercedes', 'W14', 4),
(5, 'Neumaticos', 3, 2, 8, 'Mercedes', 'W14', 5);

--- RED BULL ---
INSERT INTO Parte VALUES
(6,  'Motor',      9, 2, 3, 'Red Bull', 'RB19', 1),
(7,  'Aleron',     5, 8, 2, 'Red Bull', 'RB19', 2),
(8,  'Suspension', 6, 4, 7, 'Red Bull', 'RB19', 3),
(9,  'Caja',       7, 3, 5, 'Red Bull', 'RB19', 4),
(10, 'Neumaticos', 4, 3, 8, 'Red Bull', 'RB19', 5);

--- FERRARI ---
INSERT INTO Parte VALUES
(11, 'Motor',      7, 3, 4, 'Ferrari', 'SF23', 1),
(12, 'Aleron',     4, 6, 3, 'Ferrari', 'SF23', 2),
(13, 'Suspension', 5, 5, 6, 'Ferrari', 'SF23', 3),
(14, 'Caja',       6, 4, 5, 'Ferrari', 'SF23', 4),
(15, 'Neumaticos', 3, 3, 7, 'Ferrari', 'SF23', 5);
GO


--- INSTALACIONES ---

INSERT INTO Instalacion 
(ID_Instalacion, PU_Nivel, Aerodinamica_Nivel, Neumaticos_Nivel, Suspension_Nivel, Caja_Cambios_Nivel, No_Chasis_FK) VALUES
(1, 90, 85, 70, 80, 88, 'W14'),
(2, 95, 90, 75, 85, 92, 'RB19'),
(3, 85, 80, 72, 78, 82, 'SF23');
GO


--- PATROCINADORES ---

INSERT INTO Patrocinadores 
(ID_Patrocinador, Nombre_Patrocinador, Nombre_Equipo_FK) VALUES
(1, 'Petronas', 'Mercedes'),
(2, 'Oracle',   'Red Bull'),
(3, 'Shell',    'Ferrari');
GO


--- APORTES ---

INSERT INTO Aporte 
(ID_Aporte, Fecha_Aporte, Monto_Aporte, Descripcion, ID_Patrocinador_FK) VALUES
(1, '2025-01-01', 3000000.00, 'Contrato anual', 1),
(2, '2025-01-05', 3500000.00, 'Contrato principal', 2),
(3, '2025-01-10', 2800000.00, 'Contrato histórico', 3);
GO
