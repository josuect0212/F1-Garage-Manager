CREATE DATABASE F1_Garage_Manager;
GO
USE F1_Garage_Manager;
GO

CREATE TABLE Equipo (
    Nombre VARCHAR(100) NOT NULL PRIMARY KEY
);

CREATE TABLE Circuito (
    Nombre VARCHAR(100) NOT NULL PRIMARY KEY,
    Distancia DECIMAL(6,2) NOT NULL,
    Curvas INT NOT NULL CHECK (Curvas >= 0),
    Nombre_Equipo VARCHAR(100) NOT NULL
);


CREATE TABLE Usuario (
    Correo VARCHAR(150) NOT NULL PRIMARY KEY,
    Contrasena VARCHAR(255) NOT NULL,
    Rol VARCHAR(50) NOT NULL,
    Habilidad INT NOT NULL CHECK (Habilidad BETWEEN 1 AND 100),
    Nombre_Equipo VARCHAR(100) NOT NULL
);

CREATE TABLE Carro (
    N_Chasis VARCHAR(50) NOT NULL PRIMARY KEY,
    Nombre_Equipo VARCHAR(100) NOT NULL,
    Correo VARCHAR(150) NULL 
);

CREATE TABLE Usuario_Carro (
    Correo VARCHAR(150) NOT NULL,
    N_Chasis VARCHAR(50) NOT NULL,
    CONSTRAINT PK_Usuario_Carro PRIMARY KEY (Correo, N_Chasis)
);

CREATE TABLE Instalacion (
    ID INT NOT NULL PRIMARY KEY,
    PU INT NOT NULL,
    Aerodinamica INT NOT NULL,
    Neumaticos INT NOT NULL,
    Suspension INT NOT NULL,
    Caja_Cambios INT NOT NULL,
    N_Chasis VARCHAR(50) NOT NULL
);

CREATE TABLE Inventario_General (
    ID_Item INT NOT NULL PRIMARY KEY,
    Categoria VARCHAR(100) NOT NULL,
    Precio DECIMAL(10,2) NOT NULL CHECK (Precio >= 0),
    Stock INT NOT NULL CHECK (Stock >= 0)
);

CREATE TABLE Parte (
    ID_Parte INT NOT NULL PRIMARY KEY,
    Tipo VARCHAR(100) NOT NULL,
    p INT NOT NULL,
    a INT NOT NULL,
    m INT NOT NULL,
    Nombre_Equipo VARCHAR(100) NOT NULL,
    N_Chasis VARCHAR(50) NOT NULL,
    ID_Item INT NOT NULL
);

CREATE TABLE Simulacion (
    ID_Simulacion INT NOT NULL PRIMARY KEY,
    Correo VARCHAR(150) NOT NULL,
    Nombre_Circuito VARCHAR(100) NOT NULL
);

CREATE TABLE Resultado (
    [Timestamp] DATETIME NOT NULL PRIMARY KEY,
    Rankings INT NOT NULL CHECK (Rankings >= 1),
    ID_Simulacion INT NOT NULL
);

CREATE TABLE Patrocinadores (
    ID INT NOT NULL PRIMARY KEY,
    Nombre VARCHAR(100) NOT NULL,
    Nombre_Equipo VARCHAR(100) NOT NULL
);

CREATE TABLE Aporte (
    ID_Aporte INT NOT NULL PRIMARY KEY,
    Fecha DATE NOT NULL,
    Monto DECIMAL(10,2) NOT NULL CHECK (Monto > 0),
    Descripcion VARCHAR(255) NULL,
    ID INT NOT NULL
);

ALTER TABLE Circuito
ADD CONSTRAINT FK_Circuito_Equipo
FOREIGN KEY (Nombre_Equipo) REFERENCES Equipo(Nombre);

ALTER TABLE Usuario
ADD CONSTRAINT FK_Usuario_Equipo
FOREIGN KEY (Nombre_Equipo) REFERENCES Equipo(Nombre);

ALTER TABLE Carro
ADD CONSTRAINT FK_Carro_Equipo
FOREIGN KEY (Nombre_Equipo) REFERENCES Equipo(Nombre);

ALTER TABLE Carro
ADD CONSTRAINT FK_Carro_Usuario
FOREIGN KEY (Correo) REFERENCES Usuario(Correo);

ALTER TABLE Usuario_Carro
ADD CONSTRAINT FK_UsuarioCarro_Usuario
FOREIGN KEY (Correo) REFERENCES Usuario(Correo);

ALTER TABLE Usuario_Carro
ADD CONSTRAINT FK_UsuarioCarro_Carro
FOREIGN KEY (N_Chasis) REFERENCES Carro(N_Chasis);

ALTER TABLE Instalacion
ADD CONSTRAINT FK_Instalacion_Carro
FOREIGN KEY (N_Chasis) REFERENCES Carro(N_Chasis);

ALTER TABLE Parte
ADD CONSTRAINT FK_Parte_Equipo
FOREIGN KEY (Nombre_Equipo) REFERENCES Equipo(Nombre);

ALTER TABLE Parte
ADD CONSTRAINT FK_Parte_Carro
FOREIGN KEY (N_Chasis) REFERENCES Carro(N_Chasis);

ALTER TABLE Parte
ADD CONSTRAINT FK_Parte_Inventario
FOREIGN KEY (ID_Item) REFERENCES Inventario_General(ID_Item);

ALTER TABLE Simulacion
ADD CONSTRAINT FK_Simulacion_Usuario
FOREIGN KEY (Correo) REFERENCES Usuario(Correo);

ALTER TABLE Simulacion
ADD CONSTRAINT FK_Simulacion_Circuito
FOREIGN KEY (Nombre_Circuito) REFERENCES Circuito(Nombre);

ALTER TABLE Resultado
ADD CONSTRAINT FK_Resultado_Simulacion
FOREIGN KEY (ID_Simulacion) REFERENCES Simulacion(ID_Simulacion);

ALTER TABLE Patrocinadores
ADD CONSTRAINT FK_Patrocinadores_Equipo
FOREIGN KEY (Nombre_Equipo) REFERENCES Equipo(Nombre);

ALTER TABLE Aporte
ADD CONSTRAINT FK_Aporte_Patrocinador
FOREIGN KEY (ID) REFERENCES Patrocinadores(ID);
