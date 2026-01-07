USE F1_Garage_Manager;
GO


INSERT INTO Equipo (Nombre) VALUES
('Mercedes'),
('Ferrari'),
('Red Bull');


INSERT INTO Circuito (Nombre, Distancia, Curvas, Nombre_Equipo) VALUES
('Monza', 5.79, 11, 'Ferrari'),
('Silverstone', 5.89, 18, 'Mercedes'),
('Spa-Francorchamps', 7.00, 20, 'Red Bull');



INSERT INTO Usuario (Correo, Contrasena, Rol, Habilidad, Nombre_Equipo) VALUES
('toto@mercedes.com', '1234', 'Manager', 95, 'Mercedes'),
('christian@redbull.com', '1234', 'Manager', 92, 'Red Bull'),
('binotto@ferrari.com', '1234', 'Manager', 85, 'Ferrari'),
('mec1@mercedes.com', '1234', 'Mecanico', 70, 'Mercedes'),
('mec2@ferrari.com', '1234', 'Mecanico', 73, 'Ferrari');


INSERT INTO Carro (N_Chasis, Nombre_Equipo, Correo) VALUES
('W14', 'Mercedes', 'toto@mercedes.com'),
('RB19', 'Red Bull', 'christian@redbull.com'),
('SF23', 'Ferrari', 'binotto@ferrari.com');


INSERT INTO Usuario_Carro (Correo, N_Chasis) VALUES
('mec1@mercedes.com', 'W14'),
('mec2@ferrari.com', 'SF23');


INSERT INTO Inventario_General (ID_Item, Categoria, Precio, Stock) VALUES
(1, 'Motor', 500000.00, 5),
(2, 'Aleron', 150000.00, 10),
(3, 'Suspension', 120000.00, 8),
(4, 'Caja de Cambios', 300000.00, 6),
(5, 'Neumaticos', 80000.00, 30);


INSERT INTO Parte (ID_Parte, Tipo, p, a, m, Nombre_Equipo, N_Chasis, ID_Item) VALUES
(1, 'Motor', 90, 10, 5, 'Mercedes', 'W14', 1),
(2, 'Aleron', 40, 80, 10, 'Red Bull', 'RB19', 2),
(3, 'Suspension', 60, 40, 20, 'Ferrari', 'SF23', 3),
(4, 'Caja', 70, 30, 25, 'Mercedes', 'W14', 4),
(5, 'Neumaticos', 20, 10, 60, 'Red Bull', 'RB19', 5);

INSERT INTO Instalacion (ID, PU, Aerodinamica, Neumaticos, Suspension, Caja_Cambios, N_Chasis) VALUES
(1, 90, 85, 70, 80, 88, 'W14'),
(2, 95, 90, 75, 85, 92, 'RB19'),
(3, 85, 80, 72, 78, 82, 'SF23');


INSERT INTO Patrocinadores (ID, Nombre, Nombre_Equipo) VALUES
(1, 'Petronas', 'Mercedes'),
(2, 'Oracle', 'Red Bull'),
(3, 'Shell', 'Ferrari');


INSERT INTO Aporte (ID_Aporte, Fecha, Monto, Descripcion, ID) VALUES
(1, '2025-01-01', 2000000.00, 'Contrato anual', 1),
(2, '2025-01-05', 2500000.00, 'Contrato principal', 2),
(3, '2025-01-10', 1800000.00, 'Contrato histórico', 3);


INSERT INTO Simulacion (ID_Simulacion, Correo, Nombre_Circuito) VALUES
(1, 'toto@mercedes.com', 'Silverstone'),
(2, 'christian@redbull.com', 'Spa-Francorchamps'),
(3, 'binotto@ferrari.com', 'Monza');


INSERT INTO Resultado ([Timestamp], Rankings, ID_Simulacion) VALUES
('2025-02-01 10:00:00', 1, 1),
('2025-02-01 11:00:00', 2, 2),
('2025-02-01 12:00:00', 3, 3);
