?USE F1_Garage_Manager;
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Historial_Compras')
BEGIN
    CREATE TABLE Historial_Compras (
        ID_Compra INT PRIMARY KEY IDENTITY(1,1),
        Fecha_Compra DATETIME DEFAULT GETDATE(),
        ID_Equipo INT NOT NULL,
        ID_Item INT NOT NULL,
        Precio_Pagado DECIMAL(18,2) NOT NULL,
        Presupuesto_Previo DECIMAL(18,2),
        Presupuesto_Posterior DECIMAL(18,2),
        Usuario_Ejecutor INT
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

--Funciones que estoy usando
CREATE OR ALTER FUNCTION fn_ObtenerPresupuestoDisponible
(
    @Id_Equipo INT
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
    WHERE P.Id_Equipo_FK = @Id_Equipo;
    
    -- Total gastado en partes
    SELECT @Gastado = ISNULL(SUM(I.Precio), 0)
    FROM Parte Pa
    JOIN Inventario_General I ON Pa.ID_Item_FK = I.ID_Item
    WHERE Pa.Id_Equipo_FK = @Id_Equipo;
    
    RETURN (@Presupuesto - @Gastado);
END
GO

IF EXISTS (SELECT * FROM sys.objects WHERE name = 'sp_ObtenerInfoCarroConductor')
    DROP PROCEDURE sp_ObtenerCarroConductor;
GO

USE F1_Garage_Manager;
GO
--Procedures que estoy usando
--EXEC sp_ObtenerCarroConductor @Id_Usuario = 5;


CREATE OR ALTER PROCEDURE sp_ReemplazarParte
    @ID_Parte_Nueva INT,
    @No_Chasis VARCHAR(50),
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
        SELECT @ID_Parte_Antigua = ID_Parte
        FROM Parte WITH (UPDLOCK, HOLDLOCK)
        WHERE No_Chasis_FK = @No_Chasis 
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

CREATE OR ALTER PROCEDURE sp_SimularCarrera
    @Id_Usuario INT,
    @Id_Circuito INT,
	@date DATETIME,
	@resultado NVARCHAR(500) OUTPUT,
    @dc FLOAT = 0.2 
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Variables para el Carro/Conductor
    DECLARE @P FLOAT, @A FLOAT, @M FLOAT, @H FLOAT;
    -- Variables del Circuito
    DECLARE @D FLOAT, @C INT;
    -- Variables de Cálculo
    DECLARE @Dcurvas FLOAT, @Drectas FLOAT;
    DECLARE @Vrecta FLOAT, @Vcurva FLOAT;
    DECLARE @Penalizacion FLOAT, @TiempoHoras FLOAT, @TiempoSegundos FLOAT;

    -- 1. Obtener Stats del Carro y Habilidad (Usando lógica similar a tu SP anterior)
    SELECT 
        @H = U.Habilidad,
        @P = SUM(IG.p_stat),
        @A = SUM(IG.a_stat),
        @M = SUM(IG.m_stat)
    FROM Usuario U
    JOIN Usuario_Carro UC ON U.Id_Usuario = UC.Id_Usuario_FK
    JOIN Carro CAR ON UC.No_Chasis_FK = CAR.No_Chasis
    JOIN Parte P ON CAR.No_Chasis = P.No_Chasis_FK
    JOIN Inventario_General IG ON P.ID_Item_FK = IG.ID_Item
    WHERE U.Id_Usuario = @Id_Usuario AND CAR.Listo = 1
    GROUP BY U.Habilidad;

    -- 2. Obtener Datos del Circuito
    SELECT @D = Distancia_KM, @C = Curvas 
    FROM Circuito WHERE Id_Circuito = @Id_Circuito;

    -- 3. Cálculos de Distancia (Punto 9.1)
    SET @Dcurvas = @C * @dc;
    SET @Drectas = @D - @Dcurvas;

    IF @Drectas < 0
    BEGIN
        RAISERROR('Error: Las curvas exceden la distancia total del circuito.', 16, 1);
        RETURN;
    END

    -- 4. Cálculos de Velocidad (Punto 9.2)
    SET @Vrecta = 200 + (3 * @P) + (0.2 * @H) - (1 * @A);
    SET @Vcurva = 90 + (2 * @A) + (2 * @M) + (0.2 * @H);

    -- 5. Penalización y Tiempos (Punto 9.3)
    SET @Penalizacion = (@C * 40) / (1 + (@H / 100));
    SET @TiempoHoras = (@Drectas / @Vrecta) + (@Dcurvas / @Vcurva);
    SET @TiempoSegundos = (@TiempoHoras * 3600) + @Penalizacion;

    -- 6. Persistencia (Punto 9.4)
    INSERT INTO Simulacion (Id_Usuario_FK, Id_Circuito_FK, Tiempo_Seg, Fecha_Simulacion)
    VALUES (@Id_Usuario, @Id_Circuito, @TiempoSegundos, @date);

    -- Retornar el resultado para la API
    SELECT @TiempoSegundos AS TiempoTotalSegundos, @Vrecta AS VelRecta, @Vcurva AS VelCurva;
END
GO


CREATE OR ALTER PROCEDURE sp_crearUsuarioConEquipo
    @Correo NVARCHAR(100),
    @Contrasena NVARCHAR(255),
    @Nombre_Completo NVARCHAR(150),
    @Rol NVARCHAR(50),
    @Habilidad INT,
    @Id_Equipo INT,
    @Resultado NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1️⃣ Insertar Usuario
        INSERT INTO Usuario (
            Correo,
            Contrasena,
            Nombre_Completo,
            Rol,
            Habilidad
        )
        VALUES (
            @Correo,
            @Contrasena,
            @Nombre_Completo,
            @Rol,
            @Habilidad
        );

        -- 2️⃣ Obtener ID generado
        DECLARE @Id_Usuario INT;
        SET @Id_Usuario = SCOPE_IDENTITY();

        -- 3️⃣ Insertar relación SOLO si hay equipo válido
        IF @Id_Equipo <> 0
        BEGIN
            INSERT INTO Usuario_Equipo (
                Id_Usuario_FK,
                Id_Equipo_FK
            )
            VALUES (
                @Id_Usuario,
                @Id_Equipo
            );
        END

        COMMIT TRANSACTION;

        SET @Resultado = 'Éxito: Usuario creado correctamente';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @Resultado = 'Error: ' + ERROR_MESSAGE();
    END CATCH
END
GO


CREATE OR ALTER PROCEDURE sp_InstalarParteEnCarro
    @ID_Parte INT,
    @No_Chasis VARCHAR(50),
    @Usuario_Ejecutor INT,
    @Resultado VARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    DECLARE @Tipo_Parte VARCHAR(50);
    DECLARE @Id_Equipo_Parte INT;
    DECLARE @Id_Equipo_Carro INT;
    DECLARE @Chasis_Actual VARCHAR(50);
    DECLARE @ErrorMessage VARCHAR(500);
    
    BEGIN TRY
        BEGIN TRANSACTION;
        SELECT 
            @Tipo_Parte = IG.Categoria,
            @Id_Equipo_Parte = P.Id_Equipo_FK,
            @Chasis_Actual = P.No_Chasis_FK
        FROM Parte P WITH (UPDLOCK, HOLDLOCK)
		JOIN Inventario_General IG ON P.ID_Item_FK = IG.ID_Item
        WHERE ID_Parte = @ID_Parte;
        
        IF @Tipo_Parte IS NULL
        BEGIN
            SET @ErrorMessage = 'ERROR: La parte ' + CAST(@ID_Parte AS VARCHAR) + ' no existe';
            RAISERROR(@ErrorMessage, 16, 1);
        END
        SELECT @Id_Equipo_Carro = Id_Equipo_FK
        FROM Carro WITH (UPDLOCK, HOLDLOCK)
        WHERE No_Chasis = @No_Chasis;
        
        IF @Id_Equipo_Carro IS NULL
        BEGIN
            SET @ErrorMessage = 'ERROR: El chasis ''' + @No_Chasis + ''' no existe';
            RAISERROR(@ErrorMessage, 16, 1);
        END
        IF @Id_Equipo_Parte != @Id_Equipo_Carro
        BEGIN
            SET @ErrorMessage = 'ERROR: La parte pertenece al equipo ' + @Id_Equipo_Parte + 
                ' pero el carro pertenece a ' + @Id_Equipo_Carro;
            RAISERROR(@ErrorMessage, 16, 1);
        END
        IF EXISTS (
            SELECT 1 FROM Parte P JOIN Inventario_General IG ON P.ID_Item_FK = IG.ID_Item
            WHERE P.No_Chasis_FK = @No_Chasis 
            AND IG.Categoria = @Tipo_Parte 
            AND P.ID_Parte != @ID_Parte
        )
        BEGIN
            SET @ErrorMessage = 'ERROR: Ya existe una parte de tipo ''' + @Tipo_Parte + 
                ''' instalada en este carro. Use sp_ReemplazarParte para reemplazarla';
            RAISERROR(@ErrorMessage, 16, 1);
        END

        UPDATE Parte WITH (ROWLOCK)
        SET No_Chasis_FK = @No_Chasis
        WHERE ID_Parte = @ID_Parte;

		UPDATE Carro WITH (ROWLOCK)
		SET 
			-- Si la categoría coincide, se pone en 1 (true), si no, mantiene su valor actual
			PU = CASE WHEN @Tipo_Parte = 'Motor' THEN 1 ELSE PU END,
			Aerodinamica = CASE WHEN @Tipo_Parte = 'Aerodinamica' THEN 1 ELSE Aerodinamica END,
			Neumaticos = CASE WHEN @Tipo_Parte = 'Neumaticos' THEN 1 ELSE Neumaticos END,
			Suspension = CASE WHEN @Tipo_Parte = 'Suspension' THEN 1 ELSE Suspension END,
			Caja_Cambios = CASE WHEN @Tipo_Parte = 'Caja_Cambios' THEN 1 ELSE Caja_Cambios END
		WHERE No_Chasis = @No_Chasis;
        
		

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

CREATE OR ALTER PROCEDURE sp_ComprarParteConValidacion
    @Id_Equipo INT,
    @ID_Item INT,
    @Usuario_Ejecutor INT,
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
	DECLARE @Id_Parte INT;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM Equipo WHERE Id_Equipo = @Id_Equipo)
        BEGIN
            SET @ErrorMessage = 'ERROR: El equipo no existe';
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
        SET @PresupuestoPrevio = dbo.fn_ObtenerPresupuestoDisponible(@Id_Equipo);
        
        IF @PresupuestoPrevio < @PrecioItem
        BEGIN
            SET @ErrorMessage = 'ERROR: Presupuesto insuficiente. Disponible: $' + 
                CAST(@PresupuestoPrevio AS VARCHAR) + ' - Necesario: $' + 
                CAST(@PrecioItem AS VARCHAR);
            RAISERROR(@ErrorMessage, 16, 1);
        END

        UPDATE Inventario_General WITH (ROWLOCK)
        SET Stock = Stock - 1
        WHERE ID_Item = @ID_Item;
        INSERT INTO Parte (
            Id_Equipo_FK, 
            ID_Item_FK
        )
        VALUES (
            @Id_Equipo,  
            @ID_Item
        );
		SET @Id_Parte = SCOPE_IDENTITY();
        INSERT INTO Historial_Compras (
			Fecha_Compra,
			ID_Equipo,             -- En tu SP lo llamabas ID_Compra, pero en la tabla es ID_Equipo
			ID_Parte,               -- Esta columna espera el ID del item del inventario
			Precio_Pagado,
			Presupuesto_Previo,
			Presupuesto_Posterior,
			Usuario_Ejecutor
		)
		VALUES (
			GETDATE(),
			@Id_Equipo,            -- Parámetro del SP
			@Id_Parte,              -- Parámetro del SP (el item comprado)
			@PrecioItem,           -- Variable calculada
			@PresupuestoPrevio,    -- Variable calculada
			dbo.fn_ObtenerPresupuestoDisponible(@Id_Equipo),
			@Usuario_Ejecutor      -- El Ingeniero que realiza la compra
		);
        COMMIT TRANSACTION;
        
        SET @Resultado = 'ÉXITO: Parte ' + CAST(@ID_Parte AS VARCHAR) + 
            ' comprada exitosamente. Precio: $' + CAST(@PrecioItem AS VARCHAR) + 
            '. Presupuesto restante: $' + 
            CAST(dbo.fn_ObtenerPresupuestoDisponible(@Id_Equipo) AS VARCHAR);
        
    END TRY
    BEGIN CATCH
    IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        SET @Resultado = 'ERROR: ' + ERROR_MESSAGE();
         THROW;
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE sp_EstadoCompletoCarro
	@no_chasis NVARCHAR(50)
AS
BEGIN
	SELECT
		-- Stats totales
		ISNULL(SUM(IG.p_stat), 0) AS P_Total,
		ISNULL(SUM(IG.a_stat), 0) AS A_Total,
		ISNULL(SUM(IG.m_stat), 0) AS M_Total,
		-- Estado del carro
		C.Listo AS Estado_Carro,
		-- Categorías instaladas
		C.PU AS Motor,
		C.Aerodinamica,
		C.Neumaticos,
		C.Suspension,
		C.Caja_Cambios
	FROM Carro C
	JOIN Parte P ON C.No_Chasis =P.No_Chasis_FK
	JOIN Inventario_General IG ON P.ID_Item_FK = IG.ID_Item
	WHERE C.No_Chasis = @no_chasis
	GROUP BY C.No_Chasis, C.Listo,C.PU,C.Aerodinamica,C.Neumaticos,C.Suspension,C.Caja_Cambios

END;
GO

EXEC sp_EstadoCompletoCarro @no_chasis = W14;


CREATE OR ALTER PROCEDURE sp_CarrosPorEquipo
    @nombre_equipo NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        c.No_Chasis,
        c.PU,
        c.Aerodinamica,
        c.Neumaticos,
        c.Suspension,
        c.Caja_Cambios,
        c.Listo
    FROM Carro c
    INNER JOIN Equipo e
        ON c.id_Equipo_FK = e.id_equipo
    WHERE e.nombre_equipo = @nombre_equipo;
END;
GO


--Vistas que estoy usando
CREATE OR ALTER VIEW vw_ObtenerCarroConductor 
AS
SELECT 
	U.Nombre_Completo AS Conductor,
	U.Id_Usuario,
	U.Habilidad,
	E.Nombre_Equipo AS Equipo,
	C.No_Chasis
FROM Usuario U
-- 1. Unión Usuario -> Usuario_Carro (Id_Usuario_FK e Id_Usuario)
JOIN Usuario_Carro UC ON U.Id_Usuario = UC.Id_Usuario_FK
-- 2. Unión Usuario_Carro -> Carro (No_Chasis_FK y No_Chasis)
JOIN Carro C ON UC.No_Chasis_FK = C.No_Chasis
-- 3. Unión Carro -> Equipo (Id_Equipo_FK e Id_Equipo)
JOIN Equipo E ON C.Id_Equipo_FK = E.Id_Equipo
WHERE C.Listo = 1;
GO

SELECT * FROM vw_ObtenerCarroConductor;
GO

CREATE OR ALTER VIEW vw_PartesDisponiblesSinInstalar AS
SELECT 
    P.ID_Parte,
    P.Id_Equipo_FK,
    IG.Categoria,
    IG.p_stat,
    IG.a_stat,
    IG.m_stat
FROM Parte P
JOIN Inventario_General IG ON P.ID_Item_FK = IG.ID_Item
WHERE P.No_Chasis_FK IS NULL;
GO

CREATE OR ALTER VIEW vw_PartesInstaladasPorCarro AS
SELECT 
    C.No_Chasis,
    C.Id_Equipo_FK AS Id_Equipo,
    P.ID_Parte,
    IG.Categoria,
	IG.p_stat,
    IG.a_stat,
    IG.m_stat
FROM Carro C
LEFT JOIN Parte P ON C.No_Chasis = P.No_Chasis_FK
JOIN Inventario_General IG ON P.ID_Item_FK = IG.ID_Item;
GO

CREATE OR ALTER VIEW vw_UsuariosConEquipos AS
SELECT
	U.Id_Usuario AS Id_Usuario,
    U.Correo,
    U.Nombre_Completo,
    U.Rol AS Rol_Sistema,
    E.Nombre_Equipo AS Equipo,
	E.Id_Equipo AS Id_Equipo,
    U.Rol,
    U.Habilidad,
    (SELECT COUNT(*) FROM Usuario_Carro WHERE Id_Usuario_FK = U.Id_Usuario) AS Carros_Asignados
FROM Usuario U
LEFT JOIN Usuario_Equipo UE ON U.Id_Usuario = UE.Id_Usuario_FK
LEFT JOIN Equipo E ON UE.Id_Equipo_FK = E.Id_Equipo;
GO
