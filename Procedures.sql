USE F1_Garage_Manager;
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Historial_Compras')
BEGIN
    CREATE TABLE Historial_Compras (
        ID_Compra INT PRIMARY KEY IDENTITY(1,1),
        Fecha_Compra DATETIME DEFAULT GETDATE(),
        Nombre_Equipo VARCHAR(100) NOT NULL,
        ID_Parte INT NOT NULL,
        ID_Item INT NOT NULL,
        Precio_Pagado DECIMAL(18,2) NOT NULL,
        Presupuesto_Previo DECIMAL(18,2),
        Presupuesto_Posterior DECIMAL(18,2),
        Usuario_Ejecutor VARCHAR(100)
    );
END
GO

CREATE OR ALTER FUNCTION fn_ObtenerPresupuestoDisponible
(
    @Nombre_Equipo VARCHAR(100)
)
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @Presupuesto DECIMAL(18,2);
    DECLARE @Gastado DECIMAL(18,2);
    
    -- Total de aportes recibidos
    SELECT @Presupuesto = ISNULL(SUM(A.Monto_Aporte), 0)
    FROM Patrocinadores P
    JOIN Aporte A ON P.ID_Patrocinador = A.ID_Patrocinador_FK
    WHERE P.Nombre_Equipo_FK = @Nombre_Equipo;
    
    -- Total gastado en partes
    SELECT @Gastado = ISNULL(SUM(I.Precio), 0)
    FROM Parte Pa
    JOIN Inventario_General I ON Pa.ID_Item_FK = I.ID_Item
    WHERE Pa.Nombre_Equipo_FK = @Nombre_Equipo;
    
    RETURN (@Presupuesto - @Gastado);
END
GO

CREATE OR ALTER PROCEDURE sp_ComprarParteConValidacion
    @ID_Parte INT,
    @Tipo_Parte VARCHAR(50),
    @p_stat INT,
    @a_stat INT,
    @m_stat INT,
    @Nombre_Equipo VARCHAR(100),
    @ID_Item INT,
    @Usuario_Ejecutor VARCHAR(100),
    @No_Chasis VARCHAR(50) = NULL,
    @Resultado VARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @PresupuestoDisponible DECIMAL(18,2);
    DECLARE @PrecioItem DECIMAL(18,2);
    DECLARE @StockActual INT;
    DECLARE @PresupuestoPrevio DECIMAL(18,2);
    DECLARE @ErrorMessage VARCHAR(500);
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM Equipo WHERE Nombre_Equipo = @Nombre_Equipo)
        BEGIN
            SET @ErrorMessage = 'ERROR: El equipo ''' + @Nombre_Equipo + ''' no existe';
            RAISERROR(@ErrorMessage, 16, 1);
        END
        SELECT @PrecioItem = Precio, @StockActual = Stock
        FROM Inventario_General WITH (UPDLOCK, HOLDLOCK)
        WHERE ID_Item = @ID_Item;
        
        IF @PrecioItem IS NULL
        BEGIN
            SET @ErrorMessage = 'ERROR: El item ' + CAST(@ID_Item AS VARCHAR) + ' no existe en el inventario';
            RAISERROR(@ErrorMessage, 16, 1);
        END
        IF @StockActual <= 0
        BEGIN
            SET @ErrorMessage = 'ERROR: No hay stock disponible para el item ' + CAST(@ID_Item AS VARCHAR);
            RAISERROR(@ErrorMessage, 16, 1);
        END
        IF EXISTS (SELECT 1 FROM Parte WHERE ID_Parte = @ID_Parte)
        BEGIN
            SET @ErrorMessage = 'ERROR: Ya existe una parte con ID ' + CAST(@ID_Parte AS VARCHAR);
            RAISERROR(@ErrorMessage, 16, 1);
        END
        SET @PresupuestoPrevio = dbo.fn_ObtenerPresupuestoDisponible(@Nombre_Equipo);
        
        IF @PresupuestoPrevio < @PrecioItem
        BEGIN
            SET @ErrorMessage = 'ERROR: Presupuesto insuficiente. Disponible: $' + 
                CAST(@PresupuestoPrevio AS VARCHAR) + ' - Necesario: $' + 
                CAST(@PrecioItem AS VARCHAR);
            RAISERROR(@ErrorMessage, 16, 1);
        END
        IF @No_Chasis IS NOT NULL
        BEGIN
            IF NOT EXISTS (
                SELECT 1 FROM Carro 
                WHERE No_Chasis = @No_Chasis 
                AND Nombre_Equipo_FK = @Nombre_Equipo
            )
            BEGIN
                SET @ErrorMessage = 'ERROR: El chasis ''' + @No_Chasis + 
                    ''' no existe o no pertenece al equipo ' + @Nombre_Equipo;
                RAISERROR(@ErrorMessage, 16, 1);
            END
        END
        IF @p_stat < 0 OR @p_stat > 9 OR 
           @a_stat < 0 OR @a_stat > 9 OR 
           @m_stat < 0 OR @m_stat > 9
        BEGIN
            SET @ErrorMessage = 'ERROR: Los valores de stats deben estar entre 0 y 9';
            RAISERROR(@ErrorMessage, 16, 1);
        END

        UPDATE Inventario_General WITH (ROWLOCK)
        SET Stock = Stock - 1
        WHERE ID_Item = @ID_Item;
        INSERT INTO Parte (
            ID_Parte, 
            Tipo_Parte, 
            p_stat, 
            a_stat, 
            m_stat,
            Nombre_Equipo_FK, 
            No_Chasis_FK, 
            ID_Item_FK
        )
        VALUES (
            @ID_Parte, 
            @Tipo_Parte, 
            @p_stat, 
            @a_stat, 
            @m_stat,
            @Nombre_Equipo, 
            @No_Chasis, 
            @ID_Item
        );
        INSERT INTO Historial_Compras (
            Fecha_Compra,
            Nombre_Equipo,
            ID_Parte,
            ID_Item,
            Precio_Pagado,
            Presupuesto_Previo,
            Presupuesto_Posterior,
            Usuario_Ejecutor
        )
        VALUES (
            GETDATE(),
            @Nombre_Equipo,
            @ID_Parte,
            @ID_Item,
            @PrecioItem,
            @PresupuestoPrevio,
            dbo.fn_ObtenerPresupuestoDisponible(@Nombre_Equipo),
            @Usuario_Ejecutor
        );
        COMMIT TRANSACTION;
        
        SET @Resultado = 'ÉXITO: Parte ' + CAST(@ID_Parte AS VARCHAR) + 
            ' comprada exitosamente. Precio: $' + CAST(@PrecioItem AS VARCHAR) + 
            '. Presupuesto restante: $' + 
            CAST(dbo.fn_ObtenerPresupuestoDisponible(@Nombre_Equipo) AS VARCHAR);
        
    END TRY
    BEGIN CATCH
    IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        SET @Resultado = 'ERROR: ' + ERROR_MESSAGE();
         THROW;
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE sp_DeshacerCompraSegura
    @ID_Parte INT,
    @Usuario_Ejecutor VARCHAR(100),
    @Resultado VARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    DECLARE @ID_Item INT;
    DECLARE @Nombre_Equipo VARCHAR(100);
    DECLARE @PrecioDevuelto DECIMAL(18,2);
    DECLARE @ErrorMessage VARCHAR(500);
    
    BEGIN TRY
        BEGIN TRANSACTION;
        SELECT 
            @ID_Item = P.ID_Item_FK,
            @Nombre_Equipo = P.Nombre_Equipo_FK,
            @PrecioDevuelto = I.Precio
        FROM Parte P WITH (UPDLOCK, HOLDLOCK)
        JOIN Inventario_General I ON P.ID_Item_FK = I.ID_Item
        WHERE P.ID_Parte = @ID_Parte;
        
        IF @ID_Item IS NULL
        BEGIN
            SET @ErrorMessage = 'ERROR: La parte ' + CAST(@ID_Parte AS VARCHAR) + ' no existe';
            RAISERROR(@ErrorMessage, 16, 1);
        END
         DECLARE @No_Chasis VARCHAR(50);
        SELECT @No_Chasis = No_Chasis_FK FROM Parte WHERE ID_Parte = @ID_Parte;
        IF @No_Chasis IS NOT NULL
        BEGIN
            SET @ErrorMessage = 'ERROR: No se puede deshacer la compra. La parte está instalada en el chasis ' + @No_Chasis;
            RAISERROR(@ErrorMessage, 16, 1);
        END

        DELETE FROM Parte
        WHERE ID_Parte = @ID_Parte;
        UPDATE Inventario_General WITH (ROWLOCK)
        SET Stock = Stock + 1
        WHERE ID_Item = @ID_Item;
        INSERT INTO Historial_Compras (
            Fecha_Compra,
            Nombre_Equipo,
            ID_Parte,
            ID_Item,
            Precio_Pagado,
            Presupuesto_Previo,
            Presupuesto_Posterior,
            Usuario_Ejecutor
        )
        VALUES (
            GETDATE(),
            @Nombre_Equipo,
            @ID_Parte,
            @ID_Item,
            -@PrecioDevuelto,
            dbo.fn_ObtenerPresupuestoDisponible(@Nombre_Equipo),
            dbo.fn_ObtenerPresupuestoDisponible(@Nombre_Equipo) + @PrecioDevuelto,
            @Usuario_Ejecutor
        );
        
        COMMIT TRANSACTION;
        
        SET @Resultado = 'ÉXITO: Compra deshecha. Parte eliminada y stock restaurado. Presupuesto devuelto: $' + 
            CAST(@PrecioDevuelto AS VARCHAR);
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        SET @Resultado = 'ERROR: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE sp_InstalarParteEnCarro
    @ID_Parte INT,
    @No_Chasis VARCHAR(50),
    @Usuario_Ejecutor VARCHAR(100),
    @Resultado VARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    DECLARE @Tipo_Parte VARCHAR(50);
    DECLARE @Nombre_Equipo_Parte VARCHAR(100);
    DECLARE @Nombre_Equipo_Carro VARCHAR(100);
    DECLARE @Chasis_Actual VARCHAR(50);
    DECLARE @ErrorMessage VARCHAR(500);
    
    BEGIN TRY
        BEGIN TRANSACTION;
        SELECT 
            @Tipo_Parte = Tipo_Parte,
            @Nombre_Equipo_Parte = Nombre_Equipo_FK,
            @Chasis_Actual = No_Chasis_FK
        FROM Parte WITH (UPDLOCK, HOLDLOCK)
        WHERE ID_Parte = @ID_Parte;
        
        IF @Tipo_Parte IS NULL
        BEGIN
            SET @ErrorMessage = 'ERROR: La parte ' + CAST(@ID_Parte AS VARCHAR) + ' no existe';
            RAISERROR(@ErrorMessage, 16, 1);
        END
        SELECT @Nombre_Equipo_Carro = Nombre_Equipo_FK
        FROM Carro WITH (UPDLOCK, HOLDLOCK)
        WHERE No_Chasis = @No_Chasis;
        
        IF @Nombre_Equipo_Carro IS NULL
        BEGIN
            SET @ErrorMessage = 'ERROR: El chasis ''' + @No_Chasis + ''' no existe';
            RAISERROR(@ErrorMessage, 16, 1);
        END
        IF @Nombre_Equipo_Parte != @Nombre_Equipo_Carro
        BEGIN
            SET @ErrorMessage = 'ERROR: La parte pertenece al equipo ' + @Nombre_Equipo_Parte + 
                ' pero el carro pertenece a ' + @Nombre_Equipo_Carro;
            RAISERROR(@ErrorMessage, 16, 1);
        END
        IF EXISTS (
            SELECT 1 FROM Parte 
            WHERE No_Chasis_FK = @No_Chasis 
            AND Tipo_Parte = @Tipo_Parte 
            AND ID_Parte != @ID_Parte
        )
        BEGIN
            SET @ErrorMessage = 'ERROR: Ya existe una parte de tipo ''' + @Tipo_Parte + 
                ''' instalada en este carro. Use sp_ReemplazarParte para reemplazarla';
            RAISERROR(@ErrorMessage, 16, 1);
        END

        UPDATE Parte WITH (ROWLOCK)
        SET No_Chasis_FK = @No_Chasis
        WHERE ID_Parte = @ID_Parte;
        
        COMMIT TRANSACTION;
        
        SET @Resultado = 'ÉXITO: Parte ' + CAST(@ID_Parte AS VARCHAR) + 
            ' instalada en el chasis ' + @No_Chasis;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        SET @Resultado = 'ERROR: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE sp_ReemplazarParte
    @ID_Parte_Nueva INT,
    @No_Chasis VARCHAR(50),
    @Usuario_Ejecutor VARCHAR(100),
    @Resultado VARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    DECLARE @Tipo_Parte VARCHAR(50);
    DECLARE @ID_Parte_Antigua INT;
    DECLARE @ErrorMessage VARCHAR(500);
    
    BEGIN TRY
        BEGIN TRANSACTION;
        SELECT @Tipo_Parte = Tipo_Parte
        FROM Parte WITH (UPDLOCK, HOLDLOCK)
        WHERE ID_Parte = @ID_Parte_Nueva;
        
        IF @Tipo_Parte IS NULL
        BEGIN
            SET @ErrorMessage = 'ERROR: La parte nueva ' + CAST(@ID_Parte_Nueva AS VARCHAR) + ' no existe';
            RAISERROR(@ErrorMessage, 16, 1);
        END
        SELECT @ID_Parte_Antigua = ID_Parte
        FROM Parte WITH (UPDLOCK, HOLDLOCK)
        WHERE No_Chasis_FK = @No_Chasis 
        AND Tipo_Parte = @Tipo_Parte;
        IF @ID_Parte_Antigua IS NOT NULL
        BEGIN
            UPDATE Parte WITH (ROWLOCK)
            SET No_Chasis_FK = NULL
            WHERE ID_Parte = @ID_Parte_Antigua;
        END
        UPDATE Parte WITH (ROWLOCK)
        SET No_Chasis_FK = @No_Chasis
        WHERE ID_Parte = @ID_Parte_Nueva;
        
        COMMIT TRANSACTION;
        
        IF @ID_Parte_Antigua IS NOT NULL
            SET @Resultado = 'ÉXITO: Parte ' + CAST(@ID_Parte_Antigua AS VARCHAR) + 
                ' reemplazada por parte ' + CAST(@ID_Parte_Nueva AS VARCHAR);
        ELSE
            SET @Resultado = 'ÉXITO: Parte ' + CAST(@ID_Parte_Nueva AS VARCHAR) + 
                ' instalada (no había parte previa de este tipo)';
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        SET @Resultado = 'ERROR: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO


CREATE OR AlTER PROCEDURE sp_SimularCarrera
    @Nombre_Circuito VARCHAR(100),
    @Correo_Usuario_FK VARCHAR(100),
    @ID_Simulacion INT OUTPUT

AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Distancia_KM Decimal(10,2),
            @Curvas INT,
            @d_c DECIMAL(10,4),
            @D_Curvas DECIMAL(10,2),
            @D_Rectas DECIMAL(10,2);

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT @Distancia_KM = Distancia_KM, @Curvas = Curvas
        FROM Circuito
        WHERE Nombre_Circuito = @Nombre_Circuito;

        IF @Distancia_KM IS NULL
            THROW 50001, 'Circuito no encontrado', 1;

        SELECT @d_c = Valor FROM Parametro_Sistema WHERE Nombre = 'd_c';

        SET @D_Curvas = @Curvas * @d_c;
        SET @D_Rectas = @Distancia_KM - @D_Curvas;

        IF @D_Rectas < 0
            SET @D_Rectas = 0;

        INSERT INTO Simulacion (Fecha_Simulacion, Correo_Usuario_FK, Nombre_Circuito_FK)
        VALUES (GETDATE(), @Correo_Usuario_FK, @Nombre_Circuito);

        SET @ID_Simulacion = SCOPE_IDENTITY();

        ;WITH CarrosSimulacion AS (
            SELECT 
                C.No_Chasis,
                C.Nombre_Equipo_FK AS Equipo,
                U.Habilidad AS H,
                EC.P_Total AS P,
                EC.A_Total AS A,
                EC.M_Total AS M
            FROM Carro C
            JOIN vw_EstadoCompletoCarro EC ON C.No_Chasis = EC.No_Chasis
            JOIN Usuario_Carro UC ON C.No_Chasis = UC.No_Chasis_FK
            JOIN Usuario U ON UC.Correo_Usuario_FK = U.Correo
            WHERE EC.Estado_Carro = 'COMPLETO'
        ),
        CarrosConTiempo AS (
            SELECT *,
                (200 + 3*P + 0.2*H - A) AS V_Rectas,
                (90 + 2*A + 2*M + 0.2*H) AS V_Curvas,
                (@Curvas*40.0)/(1 + H/100.0) AS Penalizacion,
                ((@D_Rectas/(200 + 3*P + 0.2*H - A)) + (@D_Curvas/(90 + 2*A + 2*M + 0.2*H)))*3600 +
                ((@Curvas*40.0)/(1 + H/100.0)) AS TiempoTotal
            FROM CarrosSimulacion
        ),
        CarrosFiltrados AS (
            SELECT *
            FROM (
                SELECT *,
                    ROW_NUMBER() OVER (PARTITION BY Equipo ORDER BY TiempoTotal ASC) AS RN
                FROM CarrosConTiempo
            ) AS t
            WHERE RN <= 2
        )
        INSERT INTO Resultado_Simulacion (ID_Simulacion, No_Chasis, Posicion, Tiempo_Total)
        SELECT @ID_Simulacion,
               No_Chasis,
               ROW_NUMBER() OVER (ORDER BY TiempoTotal ASC) AS Posicion,
               TiempoTotal
        FROM CarrosFiltrados
        ORDER BY TiempoTotal ASC;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO



CREATE OR ALTER VIEW vw_PresupuestoEquipos AS
SELECT 
    E.Nombre_Equipo,
    ISNULL(SUM(A.Monto_Aporte), 0) AS Total_Aportes,
    ISNULL((
        SELECT SUM(I.Precio)
        FROM Parte P
        JOIN Inventario_General I ON P.ID_Item_FK = I.ID_Item
        WHERE P.Nombre_Equipo_FK = E.Nombre_Equipo
    ), 0) AS Total_Gastado,
    ISNULL(SUM(A.Monto_Aporte), 0) - ISNULL((
        SELECT SUM(I.Precio)
        FROM Parte P
        JOIN Inventario_General I ON P.ID_Item_FK = I.ID_Item
        WHERE P.Nombre_Equipo_FK = E.Nombre_Equipo
    ), 0) AS Presupuesto_Disponible
FROM Equipo E
LEFT JOIN Patrocinadores Pat ON E.Nombre_Equipo = Pat.Nombre_Equipo_FK
LEFT JOIN Aporte A ON Pat.ID_Patrocinador = A.ID_Patrocinador_FK
GROUP BY E.Nombre_Equipo;
GO

CREATE OR ALTER VIEW vw_HistorialComprasDetallado AS
SELECT 
    HC.ID_Compra,
    HC.Fecha_Compra,
    HC.Nombre_Equipo,
    HC.ID_Parte,
    P.Tipo_Parte,
    HC.ID_Item,
    I.Categoria,
    HC.Precio_Pagado,
    HC.Presupuesto_Previo,
    HC.Presupuesto_Posterior,
    (HC.Presupuesto_Posterior - HC.Presupuesto_Previo) AS Cambio_Presupuesto,
    HC.Usuario_Ejecutor,
    CASE 
        WHEN HC.Precio_Pagado < 0 THEN 'DEVOLUCIÓN'
        ELSE 'COMPRA'
    END AS Tipo_Operacion
FROM Historial_Compras HC
LEFT JOIN Parte P ON HC.ID_Parte = P.ID_Parte
LEFT JOIN Inventario_General I ON HC.ID_Item = I.ID_Item;
GO

CREATE OR ALTER VIEW vw_InventarioConUso AS
SELECT 
    I.ID_Item,
    I.Categoria,
    I.Precio,
    I.Stock AS Stock_Actual,
    COUNT(P.ID_Parte) AS Unidades_Usadas,
    I.Stock + COUNT(P.ID_Parte) AS Stock_Inicial_Estimado,
    CASE 
        WHEN I.Stock = 0 THEN 'SIN STOCK'
        WHEN I.Stock <= 3 THEN 'STOCK BAJO'
        ELSE 'DISPONIBLE'
    END AS Estado_Stock
FROM Inventario_General I
LEFT JOIN Parte P ON I.ID_Item = P.ID_Item_FK
GROUP BY I.ID_Item, I.Categoria, I.Precio, I.Stock;
GO

CREATE OR ALTER VIEW vw_PartesInstaladasPorCarro AS
SELECT 
    C.No_Chasis,
    C.Nombre_Equipo_FK AS Equipo,
    P.ID_Parte,
    P.Tipo_Parte,
    P.p_stat,
    P.a_stat,
    P.m_stat
FROM Carro C
LEFT JOIN Parte P ON C.No_Chasis = P.No_Chasis_FK;
GO

CREATE OR ALTER VIEW vw_PartesDisponiblesSinInstalar AS
SELECT 
    P.ID_Parte,
    P.Tipo_Parte,
    P.Nombre_Equipo_FK,
    I.Categoria,
    I.Precio,
    P.p_stat,
    P.a_stat,
    P.m_stat
FROM Parte P
JOIN Inventario_General I ON P.ID_Item_FK = I.ID_Item
WHERE P.No_Chasis_FK IS NULL;
GO

CREATE OR ALTER VIEW vw_EstadoCompletoCarro AS
SELECT 
    C.No_Chasis,
    C.Nombre_Equipo_FK AS Equipo,
    -- Conteo de partes instaladas
    COUNT(P.ID_Parte) AS Partes_Instaladas,
    -- Stats totales
    ISNULL(SUM(P.p_stat), 0) AS P_Total,
    ISNULL(SUM(P.a_stat), 0) AS A_Total,
    ISNULL(SUM(P.m_stat), 0) AS M_Total,
    -- Estado del carro
    CASE 
        WHEN COUNT(P.ID_Parte) = 5 THEN 'COMPLETO'
        WHEN COUNT(P.ID_Parte) > 0 THEN 'EN CONSTRUCCIÓN'
        ELSE 'VACÍO'
    END AS Estado_Carro,
    -- Categorías instaladas
    STRING_AGG(P.Tipo_Parte, ', ') AS Categorias_Instaladas
FROM Carro C
LEFT JOIN Parte P ON C.No_Chasis = P.No_Chasis_FK
GROUP BY C.No_Chasis, C.Nombre_Equipo_FK;
GO

CREATE OR ALTER VIEW vw_InventarioPorEquipo AS
SELECT 
    E.Nombre_Equipo,
    P.Tipo_Parte,
    COUNT(P.ID_Parte) AS Cantidad_Total,
    SUM(CASE WHEN P.No_Chasis_FK IS NULL THEN 1 ELSE 0 END) AS Cantidad_Disponible,
    SUM(CASE WHEN P.No_Chasis_FK IS NOT NULL THEN 1 ELSE 0 END) AS Cantidad_Instalada,
    AVG(CAST(P.p_stat AS DECIMAL(5,2))) AS Promedio_P,
    AVG(CAST(P.a_stat AS DECIMAL(5,2))) AS Promedio_A,
    AVG(CAST(P.m_stat AS DECIMAL(5,2))) AS Promedio_M
FROM Equipo E
LEFT JOIN Parte P ON E.Nombre_Equipo = P.Nombre_Equipo_FK
GROUP BY E.Nombre_Equipo, P.Tipo_Parte;
GO

CREATE OR ALTER VIEW vw_PartesFaltantesPorCarro AS
SELECT 
    C.No_Chasis,
    C.Nombre_Equipo_FK AS Equipo,
    Categorias.Categoria AS Categoria_Faltante
FROM Carro C
CROSS JOIN (
    VALUES 
        ('Motor'),
        ('Aleron'),
        ('Neumaticos'),
        ('Suspension'),
        ('Caja')
) AS Categorias(Categoria)
WHERE NOT EXISTS (
    SELECT 1 
    FROM Parte P 
    WHERE P.No_Chasis_FK = C.No_Chasis 
    AND P.Tipo_Parte = Categorias.Categoria
);
GO

CREATE OR ALTER VIEW vw_GastosPorEquipoCategoria AS
SELECT 
    P.Nombre_Equipo_FK AS Equipo,
    I.Categoria,
    COUNT(P.ID_Parte) AS Cantidad_Comprada,
    SUM(I.Precio) AS Total_Gastado,
    AVG(I.Precio) AS Precio_Promedio
FROM Parte P
JOIN Inventario_General I ON P.ID_Item_FK = I.ID_Item
GROUP BY P.Nombre_Equipo_FK, I.Categoria;
GO

CREATE OR ALTER VIEW vw_UsuariosConEquipos AS
SELECT 
    U.Correo,
    U.Nombre_Completo,
    U.Rol AS Rol_Sistema,
    UE.Nombre_Equipo_FK AS Equipo,
    UE.Rol_En_Equipo,
    U.Habilidad,
    (SELECT COUNT(*) FROM Usuario_Carro WHERE Correo_Usuario_FK = U.Correo) AS Carros_Asignados
FROM Usuario U
LEFT JOIN Usuario_Equipo UE ON U.Correo = UE.Correo_Usuario_FK;
GO