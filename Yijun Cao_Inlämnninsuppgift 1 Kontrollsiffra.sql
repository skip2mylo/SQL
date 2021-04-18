--Kontrollera sista siffran i ett personnummer
--Yijun Cao (June)

DROP FUNCTION dbo.KontrollSiffra

CREATE FUNCTION dbo.KontrollSiffra (@personnummer varchar(20)) 
RETURNS int
AS 
BEGIN 
	DECLARE @p1 varchar(20),
			@sum int, 
			@i int = 1, 
			@Return int = 0, 
			@p2 varchar(20) = '' 
	SET @p1 = RIGHT(REPLACE(REPLACE(@personnummer,'-',''), '+', ''),10) --get 10 digits from the right
	WHILE 0 = 0
		BEGIN
		--odd-number positions from the right times 2 and the evens times 1
		SET @p2 = @p2 + CAST((CAST(SUBSTRING(@p1,10 - @i, 1)as int)* (1 + @i % 2)) as varchar) 
		SET @i = @i + 1
			IF @i > 9
			BREAK 
		END 
	SET @i = 1 
	SET @sum = 0 
	WHILE 0 = 0 
	BEGIN 
	SET @sum = @sum + CAST(SUBSTRING(@p2,@i,1) as int) 
	SET @i = @i + 1 
		IF @i > LEN(@p2)
		BREAK 
	END 
	SET @sum = @sum % 10 
	IF @sum = 10 - CAST(SUBSTRING(@p1,10,1) as int)
	SET @Return = 1 --Valid personnummer
	ELSE 
	SET @Return = 0 --Invalid personnummer
	RETURN @Return 
END 
GO

--test--
SELECT dbo.KontrollSiffra ('0012122636') as test1 --1
SELECT dbo.KontrollSiffra ('0012122635') as test2--0
SELECT dbo.KontrollSiffra ('200012122636') as test3 --1
SELECT dbo.KontrollSiffra ('20001212-2636') as test4--1
SELECT dbo.KontrollSiffra ('001212+2636') as test5 --1
