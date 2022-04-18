IF db_id ('covid19') IS NULL
CREATE DATABASE covid19
GO

--  TABLES 

use covid19
go
create table zones
(
	zoneid int identity primary key,
	zonename nvarchar(10) not null
)
go
create table areas
(
	areaid int identity primary key,
	areaname nvarchar(30) not null,
	currentzone int not null references zones(zoneid)
)
go
create table dailyrecords
(
	[date] date not null,
	areaid int not null references areas(areaid),
	newcases int not null,
	deathcases int not null,
	curedcases int not null,
	primary key([date], areaid) 
)
go
create table zonetracks
(
	zonetackid int identity primary key,
	areaid int not null references areas(areaid),
	zoneid int not null references zones(zoneid),
	lastupdatedate date not null
)
go
--Views
CREATE VIEW todaysrecords
AS
SELECT        dailyrecords.date, areas.areaname, dailyrecords.newcases, dailyrecords.deathcases, dailyrecords.curedcases, zones.zonename, areas.currentzone
FROM            dailyrecords INNER JOIN
                         areas ON dailyrecords.areaid = areas.areaid INNER JOIN
                         zones ON areas.currentzone = zones.zoneid INNER JOIN
                         zonetracks ON areas.areaid = zonetracks.areaid AND zones.zoneid = zonetracks.zoneid
where cast([Date] as date) = cast(getdate() as date)
go
-- proc to insert data into "Zones" Table

CREATE PROC spInsertZone 
@ZoneName NVARCHAR(20)
AS

BEGIN TRY 

INSERT INTO Zones(ZoneName)
VALUES (@ZoneName)
END TRY

BEGIN CATCH
DECLARE @msg  NVARCHAR (1000)
	SELECT @msg = ERROR_MESSAGE()
	;
	THROW 50001, @msg, 1
END CATCH
GO

-- procedure to update "Zones"
CREATE PROC spUpdateZone 
@ZoneID int,
@ZoneName NVARCHAR(20)

AS
BEGIN TRY
	UPDATE Zones
	SET  ZoneName = ISNULL(@ZoneName,ZoneName)
	WHERE Zoneid = @ZoneID
END TRY
BEGIN CATCH
	DECLARE @msg  NVARCHAR(1000)
	SELECT @msg=ERROR_MESSAGE()
	;
	THROW 50001, @msg, 1
END CATCH
GO
-- procedure to delete data from "Zones" 

CREATE PROC spDeleteZone
@ZoneId int
AS
BEGIN TRY
	DELETE Zones WHERE Zoneid=@ZoneId
END TRY
BEGIN CATCH
	DECLARE @msg  NVARCHAR(1000)
	SELECT @msg=ERROR_MESSAGE()
	;
	THROW 50001, @msg, 1
END CATCH
GO


-- procedure to insert data into "Areas" 

CREATE PROC spInsertAreas @AreaName NVARCHAR(20), @CurrentZone NVARCHAR(10)
AS
BEGIN TRY 

INSERT INTO Areas(AreaName,CurrentZone)
VALUES (@AreaName,@CurrentZone)
END TRY

BEGIN CATCH
DECLARE @msg  NVARCHAR (1000)
	SELECT @msg = ERROR_MESSAGE()
	;
	THROW 50001, @msg, 1
END CATCH
GO

-- procedure to update  data in "Area" 
CREATE PROC spUpdateAreas @AreaID int, @AreaName NVARCHAR(20),@CurrentZone NVARCHAR(10)
AS
BEGIN TRY
	UPDATE Areas
	SET  AreaName = ISNULL(@AreaName,AreaName), CurrentZone = ISNULL(@CurrentZone, CurrentZone)
	WHERE AreaId = @AreaID
END TRY
BEGIN CATCH
	DECLARE @msg  NVARCHAR(1000)
	SELECT @msg=ERROR_MESSAGE()
	;
	THROW 50001, @msg, 1
END CATCH
GO
-- procedure to delete from "Area" 

CREATE PROC spDeleteArea @AreaId int
AS
BEGIN TRY
	DELETE Areas WHERE AreaId=@AreaId
END TRY
BEGIN CATCH
	DECLARE @msg  NVARCHAR(1000)
	SELECT @msg=ERROR_MESSAGE()
	;
	THROW 50001, @msg, 1
END CATCH
GO

SELECT * FROM DailyRecords
GO								--//--
-- creating a INSERT procedure to insert data into "Daily Records" table
create PROC spInsertDailyRecords @Date DATE, @AreaID NVARCHAR(10), @NewCases INT, @DeathCases INT, @Cures INT
AS
BEGIN TRY

		INSERT INTO DailyRecords ([Date],AreaID,NewCases,DeathCases,curedcases ) VALUES
		(@Date,@AreaID, @NewCases,@DeathCases,@Cures)
END TRY
BEGIN CATCH
	print ERROR_MESSAGE()
	RAISERROR('Inserted already', 11, 1)
END CATCH
GO

-- procedure to update "DailyRecords"

CREATE PROC spUpdateDailyRecords @Date DATE, @AreaID int, @NewCases INT, @DeathCases INT, @Cured INT
AS
	UPDATE DailyRecords
	SET  Date = ISNULL(@Date,Date),NewCases = ISNULL(@NewCases,NewCases),
	     DeathCases= ISNULL(@DeathCases,DeathCases),curedcases = ISNULL(@Cured,curedcases)
	WHERE AreaId = @AreaID
GO



--proc for deleting "DailyRecords" 

CREATE PROC spDeleteFromDailyRecords @AreaID int, @Date DATE
AS
BEGIN TRY
	 DELETE FROM DailyRecords
	 WHERE AreaID = @AreaID AND Date = @Date
	 --Date = @Date
END TRY

BEGIN CATCH
	RAISERROR('Data can not be Deleted', 11, 1)
END CATCH
GO
-----procedure to records

CREATE PROC spCaseRecord 
	@Area NVARCHAR(20),
	@StartDate DATE,
	@EndDate DATE
AS
SELECT DR.AreaID ,[Date], AreaName, NewCases, DeathCases, curedcases 
FROM DailyRecords DR
INNER JOIN Areas AR ON DR.AreaID = AR.AreaId
WHERE AreaName = @Area AND  Date BETWEEN @StartDate AND @EndDate
GO
create trigger trsetgreen 
on areas
after insert
as
begin
	insert into zonetracks (areaid, zoneid, lastupdatedate)
	select areaid,1, getdate()  from inserted

end
go

create trigger trchangezoneoninsert
on dailyrecords
after insert
as
begin 
	declare @d date, @aid int, @nc int
	SELECT @d =[date], @aid=areaid,@nc=NewCases  from inserted
	if @nc >=20
	begin
			update areas
			set currentzone = 3
			where areaid = @aid

			insert into zonetracks (areaid, zoneid, lastupdatedate)
			values(@aid, 3, getdate())
		end
	else if @nc >=10
	begin
			update areas
			set currentzone = 2
			where areaid = @aid

			insert into zonetracks (areaid, zoneid, lastupdatedate)
			values(@aid, 2, getdate())
		end
	else
	begin
			update areas
			set currentzone = 2
			where areaid = @aid

			insert into zonetracks (areaid, zoneid, lastupdatedate)
			values(@aid, 1, getdate())
	end
	
end
go
---UDF
create function totalDeaths(@areaid int) returns int
as
begin
declare @c int 
SELECT       @c=SUM(deathcases) 
FROM            dailyrecords
where areaid = @areaid
return @c
end
go
create function totalCases(@areaid int) returns int
as
begin
declare @c int 
SELECT       @c=SUM(newcases) 
FROM            dailyrecords
where areaid = @areaid
return @c
end
go
CREATE FUNCTION fnAreaSummary(@areaid INT) RETURNS TABLE
AS
RETURN (
SELECT        areaid, SUM(deathcases) as deaths, sum(curedcases) as cured, sum(newcases) as infected
FROM            dailyrecords
group by areaid
having areaid=@areaid
)
GO
create function areainzone(@zoneid int)
	returns table
as
return (
select * from areas
where currentzone=@zoneid
)
go
--USE master
--GO
--DROP  DATABASE Covid_19
--GO