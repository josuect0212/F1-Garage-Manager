USE F1_Garage_Manager;
GO

SELECT *
FROM Circuito;

DECLARE @ID_Simulacion INT;

EXEC sp_SimularCarrera
    @Nombre_Circuito = 'Silverstone',    
    @Correo_Usuario_FK = 'admin@f1.com', 
    @ID_Simulacion = @ID_Simulacion OUTPUT;

-- Ver el ID generado
SELECT @ID_Simulacion AS ID_Simulacion;




SELECT R.Posicion,
       R.No_Chasis,
       C.Nombre_Equipo_FK AS Equipo,
       R.Tiempo_Total,
       U.Nombre_Completo AS Piloto
FROM Resultado_Simulacion R
JOIN Carro C ON R.No_Chasis = C.No_Chasis
JOIN Usuario_Carro UC ON C.No_Chasis = UC.No_Chasis_FK
JOIN Usuario U ON UC.Correo_Usuario_FK = U.Correo
WHERE R.ID_Simulacion = @ID_Simulacion
ORDER BY R.Posicion ASC;




SELECT *
FROM Resultado_Simulacion;


SELECT R.ID_Simulacion,
       R.Posicion,
       R.No_Chasis,
       C.Nombre_Equipo_FK AS Equipo,
       R.Tiempo_Total,
       U.Nombre_Completo AS Piloto
FROM Resultado_Simulacion R
JOIN Carro C ON R.No_Chasis = C.No_Chasis
JOIN Usuario_Carro UC ON C.No_Chasis = UC.No_Chasis_FK
JOIN Usuario U ON UC.Correo_Usuario_FK = U.Correo
ORDER BY R.ID_Simulacion DESC, R.Posicion ASC;



SELECT ID_Simulacion,
       Fecha_Simulacion,
       Correo_Usuario_FK AS Ejecutada_Por,
       Nombre_Circuito_FK AS Circuito
FROM Simulacion
ORDER BY Fecha_Simulacion DESC;