USE F1_Garage_Manager
GO

CREATE PROCEDURE sp_CompraConPresupuesto
    @ID_Parte INT,
    @Tipo VARCHAR(100),
    @p INT,
    @a INT,
    @m INT,
    @Nombre_Equipo VARCHAR(100),
    @ID_Item INT,
    @N_Chasis VARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRAN;

    DECLARE @Presupuesto DECIMAL(10,2);
    DECLARE @Gastado DECIMAL(10,2);
    DECLARE @Precio DECIMAL(10,2);

    SELECT @Presupuesto = ISNULL(SUM(A.Monto),0)
    FROM Patrocinadores P
    JOIN Aporte A ON P.ID = A.ID
    WHERE P.Nombre_Equipo = @Nombre_Equipo;

    SELECT @Gastado = ISNULL(SUM(I.Precio),0)
    FROM Parte Pa
    JOIN Inventario_General I ON Pa.ID_Item = I.ID_Item
    WHERE Pa.Nombre_Equipo = @Nombre_Equipo;

    SELECT @Precio = Precio
    FROM Inventario_General
    WHERE ID_Item = @ID_Item;

    IF NOT EXISTS (
        SELECT 1 FROM Inventario_General
        WHERE ID_Item=@ID_Item AND Stock > 0
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
    (ID_Parte,Tipo,p,a,m,Nombre_Equipo,N_Chasis,ID_Item)
    VALUES
    (@ID_Parte,@Tipo,@p,@a,@m,@Nombre_Equipo,@N_Chasis,@ID_Item);

    COMMIT;
END;


CREATE PROCEDURE sp_ComprarParte
    @ID_Parte INT,
    @Tipo VARCHAR(100),
    @p INT,
    @a INT,
    @m INT,
    @Nombre_Equipo VARCHAR(100),
    @ID_Item INT,
    @N_Chasis VARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRAN;

    IF NOT EXISTS (
        SELECT 1 FROM Inventario_General
        WHERE ID_Item=@ID_Item AND Stock > 0
    )
    BEGIN
        ROLLBACK;
        RAISERROR('No hay stock disponible',16,1);
        RETURN;
    END

    UPDATE Inventario_General
    SET Stock = Stock - 1
    WHERE ID_Item=@ID_Item;

    INSERT INTO Parte
    (ID_Parte,Tipo,p,a,m,Nombre_Equipo,N_Chasis,ID_Item)
    VALUES
    (@ID_Parte,@Tipo,@p,@a,@m,@Nombre_Equipo,@N_Chasis,@ID_Item);

    COMMIT;
END;



CREATE PROCEDURE sp_ArmarCarro
    @ID_Parte INT,
    @N_Chasis VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRAN;

    UPDATE Parte
    SET N_Chasis = @N_Chasis
    WHERE ID_Parte = @ID_Parte;

    COMMIT;
END;


CREATE PROCEDURE sp_InventarioEquipo
    @Nombre_Equipo VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        P.ID_Parte,
        P.Tipo,
        I.Categoria,
        I.Precio,
        P.N_Chasis
    FROM Parte P
    JOIN Inventario_General I ON P.ID_Item = I.ID_Item
    WHERE P.Nombre_Equipo = @Nombre_Equipo;
END;
