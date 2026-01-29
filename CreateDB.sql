CREATE DATABASE F1_Garage_Manager;
GO  
USE F1_Garage_Manager;
GO


CREATE TABLE Inventario_General (
    ID_Item INT PRIMARY KEY IDENTITY(1,1),
    Categoria NVARCHAR(50) NOT NULL,
    p_stat INT,
    a_stat INT,
    m_stat INT,
    Precio DECIMAL(18, 2) NOT NULL,
    Stock INT NOT NULL
);
GO

-- 2. Creamos la tabla con la nueva estructura

CREATE TABLE Equipo (
    Id_Equipo INT PRIMARY KEY IDENTITY(1,1),
    Nombre_Equipo NVARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE Usuario (
    Id_Usuario INT PRIMARY KEY IDENTITY(1,1),
    Correo NVARCHAR(100) UNIQUE,
    Contrasena NVARCHAR(255) NOT NULL,
    Nombre_Completo NVARCHAR(150),
    Rol NVARCHAR(50),
    Habilidad NVARCHAR(50)
);

CREATE TABLE Circuito (
    Id_circuito INT PRIMARY KEY IDENTITY(1,1),
    Nombre_Circuito NVARCHAR(100),
    Distancia_KM DECIMAL(10, 2),
    Curvas INT,
    Id_Equipo_FK INT
);

CREATE TABLE Carro (
    No_Chasis NVARCHAR(50) PRIMARY KEY,
    Id_Equipo_FK INT,
    PU BIT DEFAULT 0,
    Aerodinamica BIT DEFAULT 0,
    Neumaticos BIT DEFAULT 0,
    Suspension BIT DEFAULT 0,
    Caja_Cambios BIT DEFAULT 0,
	Listo BIT DEFAULT 0
);

CREATE TABLE Parte (
    ID_Parte INT PRIMARY KEY IDENTITY(1,1),
    Id_Equipo_FK INT,
    No_Chasis_FK NVARCHAR(50),
    ID_Item_FK INT
);

CREATE TABLE Usuario_Equipo (
    Id_Usuario_FK INT,
    Id_Equipo_FK INT,
    PRIMARY KEY (Id_Usuario_FK, Id_Equipo_FK)
);

CREATE TABLE Usuario_Carro (
    Id_Usuario_FK INT,
    No_Chasis_FK NVARCHAR(50),
    PRIMARY KEY (Id_Usuario_FK, No_Chasis_FK)
);

CREATE TABLE Patrocinadores (
    ID_Patrocinador INT PRIMARY KEY,
    Nombre_Patrocinador NVARCHAR(100),
    Id_Equipo_FK INT
);

CREATE TABLE Aporte (
    Fecha_Aporte DATETIME DEFAULT GETDATE() PRIMARY KEY,
    Monto_Aporte DECIMAL(18, 2),
    Descripcion NVARCHAR(255),
    ID_Patrocinador_FK INT
);
CREATE TABLE Simulacion (
    Fecha_Simulacion DATETIME NOT NULL,
    Id_Usuario_FK INT NOT NULL,
    Id_circuito_FK INT NULL,
    Tiempo_Seg FLOAT NULL, -- Antes Ranking_Posicion
    
    -- Definimos la PK Compuesta (Fecha + Usuario)
    -- Esto permite que varios usuarios corran al mismo tiempo, 
    -- pero bloquea que un mismo usuario tenga dos registros con la misma fecha/hora exacta.
    CONSTRAINT PK_Simulacion_Usuario PRIMARY KEY (Fecha_Simulacion, Id_Usuario_FK),
    
    -- Definición de llaves foráneas según tu diagrama
    CONSTRAINT FK_Simulacion_Usuario FOREIGN KEY (Id_Usuario_FK) REFERENCES Usuario(Id_Usuario),
    CONSTRAINT FK_Simulacion_Circuito FOREIGN KEY (Id_circuito_FK) REFERENCES Circuito(Id_Circuito)
);
GO


-- 1. Relaciones de Circuito y Carro
-- Cambiado Id_Equipo_FK para que coincida con la tabla Circuito
ALTER TABLE Circuito ADD CONSTRAINT FK_Circuito_Equipo 
    FOREIGN KEY (Id_Equipo_FK) REFERENCES Equipo(Id_Equipo);

ALTER TABLE Carro ADD CONSTRAINT FK_Carro_Equipo 
    FOREIGN KEY (Id_Equipo_FK) REFERENCES Equipo(Id_Equipo);

-- 2. Relaciones de Parte
ALTER TABLE Parte ADD CONSTRAINT FK_Parte_Equipo 
    FOREIGN KEY (Id_Equipo_FK) REFERENCES Equipo(Id_Equipo);

ALTER TABLE Parte ADD CONSTRAINT FK_Parte_Carro 
    FOREIGN KEY (No_Chasis_FK) REFERENCES Carro(No_Chasis);

ALTER TABLE Parte ADD CONSTRAINT FK_Parte_Inventario 
    FOREIGN KEY (ID_Item_FK) REFERENCES Inventario_General(ID_Item);

-- 4. Relaciones de Simulacion
ALTER TABLE Simulacion ADD CONSTRAINT FK_Simulacion_Usuario 
    FOREIGN KEY (Id_Usuario_FK) REFERENCES Usuario(Id_Usuario);

ALTER TABLE Simulacion ADD CONSTRAINT FK_Simulacion_Circuito 
    FOREIGN KEY (Id_circuito_FK) REFERENCES Circuito(Id_circuito);

-- 5. Relaciones de Tablas Intermedias (N:M)
ALTER TABLE Usuario_Equipo ADD CONSTRAINT FK_UE_Usuario 
    FOREIGN KEY (Id_Usuario_FK) REFERENCES Usuario(Id_Usuario);

ALTER TABLE Usuario_Equipo ADD CONSTRAINT FK_UE_Equipo 
    FOREIGN KEY (Id_Equipo_FK) REFERENCES Equipo(Id_Equipo);

ALTER TABLE Usuario_Carro ADD CONSTRAINT FK_UC_Usuario 
    FOREIGN KEY (Id_Usuario_FK) REFERENCES Usuario(Id_Usuario);

ALTER TABLE Usuario_Carro ADD CONSTRAINT FK_UC_Carro 
    FOREIGN KEY (No_Chasis_FK) REFERENCES Carro(No_Chasis);

-- 6. Relaciones de Patrocinio
-- Corregido: En tu tabla Patrocinadores el campo se llama Id_Equipo_FK, no Nombre_Equipo_FK
ALTER TABLE Patrocinadores ADD CONSTRAINT FK_Patrocinador_Equipo 
    FOREIGN KEY (Id_Equipo_FK) REFERENCES Equipo(Id_Equipo);

ALTER TABLE Aporte ADD CONSTRAINT FK_Aporte_Patrocinador 
    FOREIGN KEY (ID_Patrocinador_FK) REFERENCES Patrocinadores(ID_Patrocinador);
