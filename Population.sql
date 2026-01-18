USE F1_Garage_Manager;
GO


--- EQUIPOS ---

INSERT INTO Equipo (Nombre_Equipo) VALUES
('Mercedes'),
('Ferrari'),
('Red Bull');


--- CIRCUITOS ---

INSERT INTO Circuito 
(Nombre_Circuito, Distancia_KM, Curvas, Nombre_Equipo_FK) VALUES
('Monza', 5.79, 11, 'Ferrari'),
('Silverstone', 5.89, 18, 'Mercedes'),
('Spa-Francorchamps', 7.00, 20, 'Red Bull');


--- USUARIOS ---

INSERT INTO Usuario (Correo, Contrasena, Nombre_Completo, Rol, Habilidad) VALUES
('toto@mercedes.com', '1234', 'Toto Wolff', 'Manager', '95'),
('christian@redbull.com', '1234', 'Christian Horner', 'Manager', '92'),
('binotto@ferrari.com', '1234', 'Mattia Binotto', 'Manager', '85'),
('mec1@mercedes.com', '1234', 'Mecanico 1', 'Mecanico', '70'),
('mec2@ferrari.com', '1234', 'Mecanico 2', 'Mecanico', '73');


--- RELACION USUARIO - EQUIPO ---

INSERT INTO Usuario_Equipo (Correo_Usuario_FK, Nombre_Equipo_FK, Rol_En_Equipo) VALUES
('toto@mercedes.com', 'Mercedes', 'Manager'),
('christian@redbull.com', 'Red Bull', 'Manager'),
('binotto@ferrari.com', 'Ferrari', 'Manager'),
('mec1@mercedes.com', 'Mercedes', 'Mecanico'),
('mec2@ferrari.com', 'Ferrari', 'Mecanico');


--- CARROS ---

INSERT INTO Carro 
(No_Chasis, Nombre_Equipo_FK, PU, Aerodinamica, Neumaticos, Suspension, Caja_Cambios) VALUES
('W14', 'Mercedes', 'PU1', 'Alta', 'Soft', 'Media', 'Auto'),
('RB19', 'Red Bull', 'PU2', 'Alta', 'Soft', 'Media', 'Auto'),
('SF23', 'Ferrari', 'PU3', 'Media', 'Medium', 'Media', 'Manual');


--- RELACION USUARIO - CARRO ---

INSERT INTO Usuario_Carro (Correo_Usuario_FK, No_Chasis_FK) VALUES
('mec1@mercedes.com', 'W14'),
('mec2@ferrari.com', 'SF23');


--- INVENTARIO ---

INSERT INTO Inventario_General (ID_Item, Categoria, Precio, Stock) VALUES
(1, 'Motor', 500000.00, 5),
(2, 'Aleron', 150000.00, 10),
(3, 'Suspension', 120000.00, 8),
(4, 'Caja de Cambios', 300000.00, 6),
(5, 'Neumaticos', 80000.00, 30);


--- PARTES ---

INSERT INTO Parte 
(ID_Parte, Tipo_Parte, p_stat, a_stat, m_stat, Nombre_Equipo_FK, No_Chasis_FK, ID_Item_FK) VALUES
(1, 'Motor', 90, 10, 5, 'Mercedes', 'W14', 1),
(2, 'Aleron', 40, 80, 10, 'Red Bull', 'RB19', 2),
(3, 'Suspension', 60, 40, 20, 'Ferrari', 'SF23', 3),
(4, 'Caja', 70, 30, 25, 'Mercedes', 'W14', 4),
(5, 'Neumaticos', 20, 10, 60, 'Red Bull', 'RB19', 5);


--- INSTALACIONES ---

INSERT INTO Instalacion 
(ID_Instalacion, PU_Nivel, Aerodinamica_Nivel, Neumaticos_Nivel, Suspension_Nivel, Caja_Cambios_Nivel, No_Chasis_FK) VALUES
(1, 90, 85, 70, 80, 88, 'W14'),
(2, 95, 90, 75, 85, 92, 'RB19'),
(3, 85, 80, 72, 78, 82, 'SF23');


--- PATROCINADORES ---

INSERT INTO Patrocinadores 
(ID_Patrocinador, Nombre_Patrocinador, Nombre_Equipo_FK) VALUES
(1, 'Petronas', 'Mercedes'),
(2, 'Oracle', 'Red Bull'),
(3, 'Shell', 'Ferrari');


--- APORTES ---

INSERT INTO Aporte 
(ID_Aporte, Fecha_Aporte, Monto_Aporte, Descripcion, ID_Patrocinador_FK) VALUES
(1, '2025-01-01', 2000000.00, 'Contrato anual', 1),
(2, '2025-01-05', 2500000.00, 'Contrato principal', 2),
(3, '2025-01-10', 1800000.00, 'Contrato histórico', 3);


--- SIMULACIONES ---

INSERT INTO Simulacion 
(Fecha_Simulacion, Ranking_Posicion, Correo_Usuario_FK, Nombre_Circuito_FK) VALUES
('2025-02-01 10:00:00', 1, 'toto@mercedes.com', 'Silverstone'),
('2025-02-01 11:00:00', 2, 'christian@redbull.com', 'Spa-Francorchamps'),
('2025-02-01 12:00:00', 3, 'binotto@ferrari.com', 'Monza');


