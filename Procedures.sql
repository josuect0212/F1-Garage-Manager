USE F1_Garage_Manager;
GO

CREATE PROCEDURE sp_CompraConPresupuesto
    @ID_Parte INT,
    @Tipo_Parte VARCHAR(50),
    @p_stat INT,
    @a_stat INT,
    @m_stat INT,
    @Nombre_Equipo VARCHAR(100),
    @ID_Item INT,
    @No_Chasis VARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRAN;

    DECLARE @Presupuesto DECIMAL(18,2);
    DECLARE @Gastado DECIMAL(18,2);
    DECLARE @Precio DECIMAL(18,2);

    SELECT @Presupuesto = ISNULL(SUM(A.Monto_Aporte),0)
    FROM Patrocinadores P
    JOIN Aporte A 
        ON P.ID_Patrocinador = A.ID_Patrocinador_FK
    WHERE P.Nombre_Equipo_FK = @Nombre_Equipo;

    SELECT @Gastado = ISNULL(SUM(I.Precio),0)
    FROM Parte Pa
    JOIN Inventario_General I 
        ON Pa.ID_Item_FK = I.ID_Item
    WHERE Pa.Nombre_Equipo_FK = @Nombre_Equipo;

    SELECT @Precio = Precio
    FROM Inventario_General
    WHERE ID_Item = @ID_Item;


    IF NOT EXISTS (
        SELECT 1 
        FROM Inventario_General
        WHERE ID_Item = @ID_Item AND Stock > 0
    )
    BEGIN
        ROLLBACK;
        RAISERROR('No hay stock disponible',16,1);
        RETURN;
    END

    IF (@Gastado + @Precio) > @Presupuesto
    BEGIN
        ROLLBACK;
        RAISERROR('Presupuesto insuficiente',16,1);
        RETURN;
    END

    UPDATE Inventario_General
    SET Stock = Stock - 1
    WHERE ID_Item = @ID_Item;

    INSERT INTO Parte
    (ID_Parte, Tipo_Parte, p_stat, a_stat, m_stat,
     Nombre_Equipo_FK, No_Chasis_FK, ID_Item_FK)
    VALUES
    (@ID_Parte, @Tipo_Parte, @p_stat, @a_stat, @m_stat,
     @Nombre_Equipo, @No_Chasis, @ID_Item);

    COMMIT;
END;
GO


CREATE PROCEDURE sp_ComprarParte
    @ID_Parte INT,
    @Tipo_Parte VARCHAR(50),
    @p_stat INT,
    @a_stat INT,
    @m_stat INT,
    @Nombre_Equipo VARCHAR(100),
    @ID_Item INT,
    @No_Chasis VARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRAN;

    IF NOT EXISTS (
        SELECT 1 
        FROM Inventario_General
        WHERE ID_Item = @ID_Item AND Stock > 0
    )
    BEGIN
        ROLLBACK;
        RAISERROR('No hay stock disponible',16,1);
        RETURN;
    END

    UPDATE Inventario_General
    SET Stock = Stock - 1
    WHERE ID_Item = @ID_Item;

    INSERT INTO Parte
    (ID_Parte, Tipo_Parte, p_stat, a_stat, m_stat,
     Nombre_Equipo_FK, No_Chasis_FK, ID_Item_FK)
    VALUES
    (@ID_Parte, @Tipo_Parte, @p_stat, @a_stat, @m_stat,
     @Nombre_Equipo, @No_Chasis, @ID_Item);

    COMMIT;
END;
GO


CREATE PROCEDURE sp_ArmarCarro
    @ID_Parte INT,
    @No_Chasis VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Parte
    SET No_Chasis_FK = @No_Chasis
    WHERE ID_Parte = @ID_Parte;
END;
GO


CREATE PROCEDURE sp_InventarioEquipo
    @Nombre_Equipo VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        P.ID_Parte,
        P.Tipo_Parte,
        I.Categoria,
        I.Precio,
        P.No_Chasis_FK
    FROM Parte P
    JOIN Inventario_General I 
        ON P.ID_Item_FK = I.ID_Item
    WHERE P.Nombre_Equipo_FK = @Nombre_Equipo;
END;
GO

--- Deshacer la compra ---
DROP PROCEDURE IF EXISTS sp_DeshacerCompra;
GO

CREATE PROCEDURE sp_DeshacerCompra
    @ID_Parte INT
AS
BEGIN
    BEGIN TRAN;

    DECLARE @ID_Item INT;

    SELECT @ID_Item = ID_Item_FK
    FROM Parte
    WHERE ID_Parte = @ID_Parte;

    IF @ID_Item IS NULL
    BEGIN
        ROLLBACK;
        RAISERROR('La parte no existe.',16,1);
        RETURN;
    END

    DELETE FROM Parte
    WHERE ID_Parte = @ID_Parte;

    UPDATE Inventario_General
    SET Stock = Stock + 1
    WHERE ID_Item = @ID_Item;

    COMMIT;
END;
GO