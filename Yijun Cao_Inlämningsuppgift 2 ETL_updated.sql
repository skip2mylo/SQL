
-- Yijun Cao (June) Inlämnningsuppgift 2: Skapa SQL skript för ETL

sp_changedbowner 'sa' 

create database AdvWorksDW
go

use AdvWorksDW
go

/* create SalesPersonDim
Kolumner som ska finnas i denna dimension är:
	SalesPersonID
	Lastname
	Fullname, som är en ihopslagning av FirstName och LastName.
*/ 

	create table SalesPersonDim
	(
			SalesPersonID int primary key,
			Lastname varchar(50),
			Fullname varchar(250),
			ModifiedDate datetime --help keeping track of latest updates
	)


	--insert historical data for the first time
	
	insert into SalesPersonDim
		select 
			BusinessEntityID,	--int
			lastname,	--varchar(50)
			FirstName + ' ' + LastName,	--varchar(250)
			ModifiedDate --datetime
		 from AdventureWorks2019.person.person

	--after inserting the data we create index for better searching performance
	create index idx_salesFullname on SalesPersonDim(Fullname)

	--load newly added items
	--before updating the data we drop the index since it will slow down the process
	drop index idx_salesFullname on SalesPersonDim

	insert into SalesPersonDim
	  select 
  		BusinessEntityID,
		lastname,
		FirstName + ' ' + LastName
		Modifieddate
	  from AdventureWorks2019.person.person
	  where BusinessEntityID not in 
		  (
		  select salespersonid 
		  from SalesPersonDim
		  )

	--update if any exsited items have been changed
	update SalesPersonDim
	set lastname = app.Lastname, 
		Fullname = app.FirstName + ' ' + app.LastName,
		Modifieddate = app.ModifiedDate
		from AdventureWorks2019.person.person as app
		left outer join SalesPersonDim as spd
		on app.BusinessEntityID = spd.SalesPersonID
		where app.ModifiedDate <> spd.ModifiedDate

	--after updating the table we re-create the index
	create index idx_salesFullname on SalesPersonDim(Fullname)

/*create ProductDim
Kolumner som ska finnas i denna dimension är:
	ProductID
	ProductName
*/

	create table ProductDim
		(
		ProductID int primary key,
		ProductName varchar(50),
		ModifiedDate datetime
		)
 
	 insert into ProductDim
	 select 
		  ProductID, --int primary key
		  [Name], --varchar(50)
		  ModifiedDate --datetime
	 from AdventureWorks2019.Production.Product

	 create index idx_prodName on ProductDim(ProductName)

	--load newly added items
	
	drop index idx_prodName on ProductDim

		insert into ProductDim
		select 
  			ProductID, --int primary key
			[Name], --varchar(50)
			ModifiedDate --datetime
		from AdventureWorks2019.Production.Product
		where ProductID not in 
			  (
			  select ProductID 
			  from ProductDim
			  )

	--update if any exsited items have been changed
	update ProductDim
	set ProductName = app.[Name], 
		Modifieddate = app.ModifiedDate
		from AdventureWorks2019.Production.Product as app
		left outer join ProductDim as spd
		on app.ProductID = spd.ProductID
		where app.ModifiedDate <> spd.ModifiedDate
	select * from ProductDim

	create index idx_prodName on ProductDim(ProductName)

/* create TerritoryDim
Kolumner som ska finnas i denna dimension är: 
	TerritoryID
	Name, där Name sak vara en ihopslagning av Group och Name med ett minustecken emellan 
(innehållet ska se ut så här ”North America – Northwest” eller ”Europe – United Kingdom”)
*/

select top 1000 * from AdventureWorks2019.sales.SalesTerritory

	create table TerritoryDim
			(
			TerritoryID int primary key,
			[Name] varchar(50),
			ModifiedDate datetime
			)
 
	 insert into TerritoryDim
	 select 
		  TerritoryID, --int primary key
		  [Group] + ' ' + '-' + ' ' + [Name], --varchar(50)
		  ModifiedDate --datetime
	 from AdventureWorks2019.sales.SalesTerritory

	 create index idx_TerriName on TerritoryDim([Name])

	--load newly added items
		insert into TerritoryDim
		select 
  			TerritoryID,
			[Group] + ' ' + '-' + ' ' + [Name], 
			ModifiedDate --datetime
		from AdventureWorks2019.sales.SalesTerritory
		where TerritoryID not in 
			  (
			  select TerritoryID
			  from TerritoryDim
			  )
		drop index idx_TerriName on TerritoryDim

	--update if any exsited items have been changed
	update TerritoryDim
	set [Name] = ass.[Group] + ' ' + '-' + ' ' + ass.[Name],
		Modifieddate = ass.ModifiedDate
		from AdventureWorks2019.sales.SalesTerritory as ass
		left outer join TerritoryDim as std
		on ass.TerritoryID = std.TerritoryID
		where ass.ModifiedDate <> std.ModifiedDate

	create index idx_TerriName on TerritoryDim([Name])

/* create DateDim
Kolumner som ska finnas i denna dimension är: 
	DateID, datum i formatet ÅÅÅÅMMDD
	Date, datum i formatet ÅÅÅÅ-MM-DD
	Year
	Month, månad som siffra
	MonthName, månad som text
	Weekday, veckodag som siffra
	WeekdayName veckodag som text
	Week, veckonummer 
	Day, dag i månaden som siffra
	Quarter, kvartal som siffra
	QuarterName kvartal som text (Q1-Q4)
*/
	create table DimDate
	(
		DateID int primary key, --DateKey ÅÅÅÅMMDD
		[Date] char(10)  not null, --ÅÅÅÅ-MM-DD
		[Year] smallint not null, 
		[Month] tinyint not null, --MonthNumber
		[MonthName] varchar(15) not null, 
		[Weekday] tinyint not null, --DayOfWeekNumber
		WeekdaykName varchar(25)  not null, --DayOfWeekName
		[Week] tinyint not null,
		[Day] tinyint not null, --DayNumberInMonth
		[Quarter] tinyint not null, --QuarterNumber
		QuarterName char(2) not null, 

	)
	go

	select * from DimDate

	create proc usp_FillDateDim (@startdate date, @enddate date)
	as 
	begin

		set nocount on			
		set datefirst 1			

		declare @dateMax date 
		declare @day date


		if @startdate > @enddate
		return


		select @day = @startdate


		while @day <= @enddate
		begin


			insert DimDate
				select 
					cast(convert(char(10), @day, 112) as int) as DateID,
					cast(@day as varchar(10)) as [Date],
					year(@day) as [Year],
					datepart(month, @day) as [Month],
					datename(month, @day) as [MonthName],
					datepart(weekday, @day) as [Weekday],
					datename(weekday, @day)  as WeekdaykName,
					datepart(iso_week, @day) as [Week],
					datepart(day, @day) as [Day],
					datepart(quarter, @day) as [Quarter],
					'Q' + datename(quarter, @day) as QuarterName

				where @day not in
					(
						select [date] from DimDate
					)

			select @day = dateadd(day, 1, @day)
		end


		set nocount off			
	end

	select min(orderdate) --2011-05-31

	from AdventureWorks2019.sales.SalesOrderHeader 

	select dateadd(year,1,getdate())--2022-03-16

	usp_FillDateDim '2011-05-31', '2022-03-16'

	select top 1000 * from DimDate
	order by 1 desc
	--as we are going to search by month and year frequently, I think it will be good to index these two columns.
	create index idx_dateMonth on DimDate([month])
	create index idx_dateYear on DimDate([Year])
	--OBS, drop indexes before we update DimDate table

/* create SalesFact 
Kolumner som ska finnas i denna faktatabell är:
	SalesPersonID 
	ProductID
	TerritoryID
	OrderDateID
	Quantity; från OrderQty
	Sales; vilket alltså är OrderQty x UnitPrice. Extra bra är ifall du även tar hänsyn till UnitPriceDiscount. 
	Profit; alltså skillnaden mellan UnitPrice och produktens kostnad. 
Extra bra är ifall du tar hänsyn till att kostnaden varierar över tid och är olika vid olika datum.
*/

create table SalesFact
(
	ID int identity(1,1) primary key,
	SalesOrderID int,
	SalesPersonID int foreign key references [dbo].[SalesPersonDim] (SalesPersonID),
	ProductID int foreign key references [dbo].[ProductDim]([ProductID]),
	TerritoryID int foreign key references [dbo].[TerritoryDim]([TerritoryID]),
	OrderDateID int foreign key references [dbo].[DimDate]([DateID]),
	Quantity int,
	Sales money,
	Profit money,
	ModifiedDate1 datetime, --h.modiefieddate, modified date of order header table
	ModifiedDate2 datetime --d.modiefieddate, modified date of order detail table.
)

insert into SalesFact
select
	h.SalesOrderID,
	SalesPersonID,
	d.ProductID,
	TerritoryID,
	cast(convert(varchar, OrderDate, 112) as int),
	d.OrderQty,
	(d.OrderQty * UnitPrice) * (1-UnitPriceDiscount),
	(d.OrderQty * UnitPrice) * (1-UnitPriceDiscount) - d.OrderQty * pch.StandardCost,
	h.ModifiedDate, --modified date of order header table
	d.ModifiedDate --modified date of order detail table

from AdventureWorks2019.sales.SalesOrderHeader as h
	left outer join AdventureWorks2019.Sales.SalesOrderDetail as d
	on h.SalesOrderID = d.SalesOrderID
		left outer join AdventureWorks2019.Production.ProductCostHistory as pch 
		on d.ProductID =pch.ProductID
		where d.ModifiedDate > pch.StartDate and d.ModifiedDate < isnull(pch.EndDate,getdate()) -- when orderdate is between the cost valid period

--for better seraching performance, we create indexes on FK (PK is automatically indexed in MS SQL server), joined columns and columns we use to search the most (ex. where)

create index idx_salfaSalesOrderID on SalesFact(SalesOrderID)
create index idx_salfaSalesPersonID on SalesFact(SalesPersonID)
create index idx_salfaProductID on SalesFact(ProductID)
create index idx_salfaTerritoryID on SalesFact(TerritoryID)
create index idx_salfaOrderDateID on SalesFact(OrderDateID)

--load newly added items into SalesFact
drop index idx_salfaSalesOrderID on SalesFact
drop index idx_salfaSalesPersonID on SalesFact
drop index idx_salfaProductID on SalesFact
drop index idx_salfaTerritoryID on SalesFact
drop index idx_salfaOrderDateID on SalesFact

insert into SalesFact
select 
	h.SalesOrderID, 
	SalesPersonID,
	d.ProductID,
	TerritoryID,
	cast(convert(varchar, OrderDate, 112) as int),
	d.OrderQty,
	(d.OrderQty * UnitPrice) * (1-UnitPriceDiscount),
	(d.OrderQty * UnitPrice) * (1-UnitPriceDiscount) - d.OrderQty * pch.StandardCost,
	h.ModifiedDate, --modified date of order header table
	d.ModifiedDate --modified date of order detail table

from AdventureWorks2019.sales.SalesOrderHeader as h
	left outer join AdventureWorks2019.Sales.SalesOrderDetail as d
	on h.SalesOrderID = d.SalesOrderID
			left outer join AdventureWorks2019.Production.ProductCostHistory as pch 
			on d.ProductID =pch.ProductID
			where d.ModifiedDate > pch.StartDate and d.ModifiedDate < isnull(pch.EndDate,getdate()) and  
			 h.salesorderID not in 
					(
					select SalesOrderID
					from SalesFact
					)


--update changed items from source in SalesFact table
update SalesFact
set 
	SalesOrderID = h.SalesOrderID,
	SalesPersonID = h.salespersonID,
	TerritoryID = h.TerritoryID,
	OrderDateID = cast(convert(varchar, OrderDate, 112) as int),
	ModifiedDate1 = h.ModifiedDate, --modified date of order header table
	ProductID = d.ProductID,
	Quantity = d.OrderQty,
	Sales = (d.OrderQty * UnitPrice) * (1-UnitPriceDiscount),
	Profit = (d.OrderQty * UnitPrice) * (1-UnitPriceDiscount) - d.OrderQty * pch.StandardCost,
	ModifiedDate2 = d.ModifiedDate--modified date of order detail table
	from SalesFact 
	left outer join AdventureWorks2019.sales.SalesOrderHeader as h
	on salesfact.SalesOrderID = h.SalesOrderID 
	left outer join AdventureWorks2019.Sales.SalesOrderDetail as d
	on h.SalesOrderID = d.SalesOrderID
			left outer join AdventureWorks2019.Production.ProductCostHistory as pch 
			on d.ProductID =pch.ProductID
			where d.ModifiedDate > pch.StartDate and d.ModifiedDate < isnull(pch.EndDate,getdate()) 
			and (ModifiedDate1 <> h.ModifiedDate 
			or  SalesFact.ModifiedDate2 <> d.ModifiedDate)

--re-create indexes after data update
create index idx_salfaSalesOrderID on SalesFact(SalesOrderID)
create index idx_salfaSalesPersonID on SalesFact(SalesPersonID)
create index idx_salfaProductID on SalesFact(ProductID)
create index idx_salfaTerritoryID on SalesFact(TerritoryID)
create index idx_salfaOrderDateID on SalesFact(OrderDateID)

select top 1000 *
from SalesFact
order by OrderDateID desc