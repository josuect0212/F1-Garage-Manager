CREATE TABLE Inventario_General (
    ID_Item INT PRIMARY KEY,
    Categoria VARCHAR(50) NOT NULL,
    Precio DECIMAL(18, 2) NOT NULL,
    Stock INT NOT NULL
);

CREATE TABLE Equipo (
    Nombre_Equipo VARCHAR(100) PRIMARY KEY
);

CREATE TABLE Usuario (
    Correo VARCHAR(100) PRIMARY KEY,
    Contrasena VARCHAR(255) NOT NULL,
    Nombre_Completo VARCHAR(150),
    Rol VARCHAR(50),
    Habilidad VARCHAR(50)
);

CREATE TABLE Circuito (
    Nombre_Circuito VARCHAR(100) PRIMARY KEY,
    Distancia_KM DECIMAL(10, 2),
    Curvas INT,
    Nombre_Equipo_FK VARCHAR(100)
);

CREATE TABLE Carro (
    No_Chasis VARCHAR(50) PRIMARY KEY,
    Nombre_Equipo_FK VARCHAR(100),
    PU VARCHAR(50),
    Aerodinamica VARCHAR(50),
    Neumaticos VARCHAR(50),
    Suspension VARCHAR(50),
    Caja_Cambios VARCHAR(50)
);

CREATE TABLE Parte (
    ID_Parte INT PRIMARY KEY,
    Tipo_Parte VARCHAR(50),
    p_stat INT,
    a_stat INT,
    m_stat INT,
    Nombre_Equipo_FK VARCHAR(100),
    No_Chasis_FK VARCHAR(50),
    ID_Item_FK INT
);

CREATE TABLE Instalacion (
    ID_Instalacion INT PRIMARY KEY,
    PU_Nivel INT,
    Aerodinamica_Nivel INT,
    Neumaticos_Nivel INT,
    Suspension_Nivel INT,
    Caja_Cambios_Nivel INT,
    No_Chasis_FK VARCHAR(50)
);

CREATE TABLE Simulacion (
    ID_Simulacion INT PRIMARY KEY IDENTITY(1,1),
    Fecha_Simulacion DATETIME,
    Ranking_Posicion INT,
    Correo_Usuario_FK VARCHAR(100),
    Nombre_Circuito_FK VARCHAR(100)
);

CREATE TABLE Usuario_Equipo (
    Correo_Usuario_FK VARCHAR(100),
    Nombre_Equipo_FK VARCHAR(100),
    Rol_En_Equipo VARCHAR(50),
    PRIMARY KEY (Correo_Usuario_FK, Nombre_Equipo_FK)
);

CREATE TABLE Usuario_Carro (
    Correo_Usuario_FK VARCHAR(100),
    No_Chasis_FK VARCHAR(50),
    PRIMARY KEY (Correo_Usuario_FK, No_Chasis_FK)
);

CREATE TABLE Patrocinadores (
    ID_Patrocinador INT PRIMARY KEY,
    Nombre_Patrocinador VARCHAR(100),
    Nombre_Equipo_FK VARCHAR(100)
);

CREATE TABLE Aporte (
    ID_Aporte INT PRIMARY KEY,
    Fecha_Aporte DATE,
    Monto_Aporte DECIMAL(18, 2),
    Descripcion VARCHAR(255),
    ID_Patrocinador_FK INT
);

-- Relaciones de Circuito y Carro con Equipo
ALTER TABLE Circuito ADD CONSTRAINT FK_Circuito_Equipo 
    FOREIGN KEY (Nombre_Equipo_FK) REFERENCES Equipo(Nombre_Equipo);

ALTER TABLE Carro ADD CONSTRAINT FK_Carro_Equipo 
    FOREIGN KEY (Nombre_Equipo_FK) REFERENCES Equipo(Nombre_Equipo);

-- Relaciones de Parte
ALTER TABLE Parte ADD CONSTRAINT FK_Parte_Equipo 
    FOREIGN KEY (Nombre_Equipo_FK) REFERENCES Equipo(Nombre_Equipo);
ALTER TABLE Parte ADD CONSTRAINT FK_Parte_Carro 
    FOREIGN KEY (No_Chasis_FK) REFERENCES Carro(No_Chasis);
ALTER TABLE Parte ADD CONSTRAINT FK_Parte_Inventario 
    FOREIGN KEY (ID_Item_FK) REFERENCES Inventario_General(ID_Item);

-- Relación de Instalación
ALTER TABLE Instalacion ADD CONSTRAINT FK_Instalacion_Carro 
    FOREIGN KEY (No_Chasis_FK) REFERENCES Carro(No_Chasis);

-- Relaciones de Simulacion
ALTER TABLE Simulacion ADD CONSTRAINT FK_Simulacion_Usuario 
    FOREIGN KEY (Correo_Usuario_FK) REFERENCES Usuario(Correo);
ALTER TABLE Simulacion ADD CONSTRAINT FK_Simulacion_Circuito 
    FOREIGN KEY (Nombre_Circuito_FK) REFERENCES Circuito(Nombre_Circuito);

-- Relaciones de Tablas Intermedias (N:M)
ALTER TABLE Usuario_Equipo ADD CONSTRAINT FK_UE_Usuario 
    FOREIGN KEY (Correo_Usuario_FK) REFERENCES Usuario(Correo);
ALTER TABLE Usuario_Equipo ADD CONSTRAINT FK_UE_Equipo 
    FOREIGN KEY (Nombre_Equipo_FK) REFERENCES Equipo(Nombre_Equipo);

ALTER TABLE Usuario_Carro ADD CONSTRAINT FK_UC_Usuario 
    FOREIGN KEY (Correo_Usuario_FK) REFERENCES Usuario(Correo);
ALTER TABLE Usuario_Carro ADD CONSTRAINT FK_UC_Carro 
    FOREIGN KEY (No_Chasis_FK) REFERENCES Carro(No_Chasis);

-- Relaciones de Patrocinio
ALTER TABLE Patrocinadores ADD CONSTRAINT FK_Patrocinador_Equipo 
    FOREIGN KEY (Nombre_Equipo_FK) REFERENCES Equipo(Nombre_Equipo);

ALTER TABLE Aporte ADD CONSTRAINT FK_Aporte_Patrocinador 
    FOREIGN KEY (ID_Patrocinador_FK) REFERENCES Patrocinadores(ID_Patrocinador);
