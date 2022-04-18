use Covid19
GO

EXEC spInsertZone 'GREEN'
EXEC spInsertZone 'YELLOW'
EXEC spInsertZone 'RED'
EXEC spInsertZone 'BLUE'
GO
SELECT * FROM Zones
GO
--
EXEC spUpdateZone @ZoneID = 3 , @ZoneName = 'WHITE'
GO 
SELECT * FROM Zones
GO
EXEC spUpdateZone @ZoneID = 3 , @ZoneName = 'RED'
GO 
SELECT * FROM Zones
GO
--
EXEC spDeleteZone 4
GO
SELECT * FROM Zones
GO
Exec spInsertAreas 'Mirpur',1
Exec spInsertAreas 'Mohammadpur',1
Exec spInsertAreas 'Uttara',1
-- 
Exec spInsertAreas 'Gulshan',2
Exec spInsertAreas 'Dhanmondi',2
Exec spInsertAreas 'Motijheel',2
-- 
Exec spInsertAreas 'Sutrapur',3
Exec spInsertAreas 'Nobabgonj',3
Exec spInsertAreas 'Keranigonj',3
Exec spInsertAreas 'Narayangonj',3
GO
--
SELECT * FROM Areas
GO
--
EXEC spUpdateAreas @AreaID = 10, @AreaName = 'Khilkhet', @CurrentZone = 3
GO
SELECT * FROM Areas
GO
--
Exec spDeleteArea 10
GO
SELECT * FROM Areas
GO
-- 
EXEC spInsertDailyRecords '2021-07-01',1,123,23,63
EXEC spInsertDailyRecords '2021-07-01',2,65,20,25
GO
--
DECLARE @CurrentDate DATE
		SET @CurrentDate = GETDATE()
EXEC spInsertDailyRecords @AreaId =1, @Date =@CurrentDate,
						  @NewCases= 123, @DeathCases = 23, @Cures = 33
GO
SELECT * FROM DailyRecords
GO
-- 
Exec spDeleteFromDailyRecords 1, '2021-07-05'
GO
-- 
SELECT * FROM DailyRecords
GO
--
EXEC spCaseRecord 'Mirpur','2021-07-01','2021-07-03'
GO
EXEC spCaseRecord 'Mohammadpur','2021-07-01','2021-07-03'
GO
EXEC spCaseRecord 'Gulshan','2021-07-01','2021-07-03'
GO
EXEC spCaseRecord 'Nobabgonj','2021-07-01','2021-07-03'
GO
--
select * from todaysrecords
GO
--
select * from fnAreaSummary(1)
go
select * from areainzone(3)
go
select dbo.totalCases(1)
select dbo.totalDeaths(1)
GO




