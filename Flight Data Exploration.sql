-- SQL EXPLORATION

SELECT * FROM Airports
SELECT * FROM Airlines
SELECT * FROM Flights
SELECT * FROM Passengers
SELECT * FROM Tickets



-- Q1) FIND THE BUSIEST AIRPORT BY THE NUMBER OF FLIGHTS TAKE OFF

/*
STEPS:
1- Identify what all tables will be required to solve this question
    airport - from airport tables
    number of flights take off - flights table
 
 so we will join this two tables - Flights & Airports table
*/

SELECT * FROM Flights
SELECT * FROM Airports

SELECT TOP 1 a.Name, COUNT(*) as TotalFlights  -- use TOP 1 to find the busiest one
FROM Flights f
JOIN
Airports a
on f.Origin = a.AirportID  --- the column that connect this two tables
GROUP BY a.Name -- group by the airport name
ORDER BY TotalFlights DESC -- by DESC so yang paling banyak duduk atas

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

---Q2) TOTAL NUMBER OF TICKETS SOLD PER AIRLINE

/*
the information coming from the airline tables and tickets table

*/
SELECT * FROM Airlines
SELECT * FROM Tickets
SELECT * FROM Flights

SELECT a.Name as Airline,
        count(*) as  TicketSold  --- ape yang kite nak, nama airline & nmber of tickets sold per airline
FROM Tickets t
inner join Flights f on t.FlightID = f.FlightID
inner join Airlines a on f.AirlineID = a.AirlineID
group by a.Name

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*

Q3) list all flights operated by 'IndiGO' with airports names (origin and destination)

apa yang kita nak: airport name, origin, destination (operated by IndiGo)

table yang berkenaan: Airports, Airline, Flights

*/
SELECT * FROM Airports
SELECT * FROM Airlines
SELECT * FROM Flights

SELECT f.FlightID, 
       ap.Name as OriginAirport,
       ap1.Name as DesitinationAirport
FROM Flights f
INNER JOIN Airports ap on f.origin = ap.AirportID
INNER JOIN Airlines al on f.AirlineID = al.AirlineID
INNER JOIN Airports ap1 on f.Destination = ap1.AirportID
WHERE al.Name = 'INDIGO'

---------------------------------------------------------------------------------------------
/*
Q4: For each airport, show the top airlines by number of flights departing from there.

apa yang kte nk tahu : airport, top airlines, number of flights (aggregate func) -tickets

*/

SELECT 
    ap.Name as AirportName, 
    al.Name as AirlineName,
    COUNT(*) as FlightCount
   
FROM Flights f
INNER JOIN Airports ap on f.origin = ap.AirportID
INNER JOIN Airports ap1 on f.Destination = ap1.AirportID
INNER JOIN Airlines al on f.AirlineID = al.AirlineID
INNER JOIN Tickets t on f.FlightID = t.FlightID

---------------------------------------------------------------------

WITH CTE_flightrank as (

SELECT *,
        RANK () OVER(PARTITION BY Origin ORDER BY FlightCount DESC) as rn
FROM (
    SELECT Origin, AirlineID, COUNT(*) as FlightCount
    FROM Flights 
    GROUP BY Origin, AirlineID
    )t

)

SELECT a.Name as AirportName, al.Name as AirlineName, r.FlightCount
FROM CTE_flightrank r
JOIN Airports a on r.Origin = a.airportid
JOIN Airlines al on r.AirlineID = al.AirlineID
WHERE rn = 1


---------------------------------------------------------------------------------------------
/*
Q5: For each flight, show time taken in hours and categorize it as short (<2hrs), Medium (2-5hrs), or Long (>5h)

- we have to find the different between departure and arrival time
- then we have to classified it by short, medium , long
*/

SELECT 
    FlightID,
    DepartureTime,
    ArrivalTime,
    DATEDIFF(MINUTE, DepartureTime, ArrivalTime) / 60 as DurationHours,

    CASE
        WHEN DATEDIFF(MINUTE, DepartureTime, ArrivalTime) > 120 THEN 'Short'
        WHEN DATEDIFF(MINUTE, DepartureTime, ArrivalTime) <= 300 THEN 'Medium'
        ELSE 'Long'
    END as FlightCategory

FROM Flights



---------------------------------------------------------------------------------------------
/*
Q6: Show each passenger's first and last flight dates and number of flights
*/

WITH CTE_FlightsNO as (
    SELECT PassengerID,
            MIN(F.DepartureTime) AS FirstFlight,
            MAX(F.DepartureTime) AS LastFlight,
            COUNT(*) AS TotalFlights
    FROM Tickets T
    JOIN Flights F ON T.FlightID = F.FlightID
    GROUP BY PassengerID
)

SELECT 
    p.Name,
    cte.FirstFlight,
    cte.LastFlight,
    cte.TotalFlights
FROM CTE_FlightsNo as cte
JOIN Passengers p on cte.passengerid = p.PassengerID


/*
Q7 ) find flights with the highest price ticket sold for each route (origin --> destination)

*/

WITH CTE_routetickets AS (
SELECT 
    f.FlightID,
    f.Origin,
    f.Destination,
    t.TicketID,
    t.Price,
    RANK() OVER (PARTITION BY f.origin,f.destination ORDER BY t.price DESC ) AS rnk

FROM Tickets t
JOIN Flights f on t.FlightID = f.FlightID
)

SELECT A1.Name AS Origin,
        A2.Name As Destination,
        rt.Price,
        rt.TicketID  
FROM CTE_routetickets rt
JOIN Airports A1 on rt.Origin = A1.AirportID
JOIN Airports A2 on rt.Destination = A2.AirportID
WHERE rnk = 1


/*
Q8 ) find the highest spending passenger in each frequest flyer status group

*/

WITH CTE_spending AS (
SELECT *,
    RANK() OVER (PARTITION BY FrequentFlyerStatus ORDER BY TotalSpent DESC ) AS rn
    FROM(
        SELECT p.PassengerID, p.Name, p.FrequentFlyerStatus, SUM(t.Price) AS TotalSpent
        FROM Passengers p
        JOIn Tickets t
        ON p.PassengerID = t.PassengerID
        GROUP BY p.PassengerID, p.Name, p.FrequentFlyerStatus
        )t
)

SELECT Name, FrequentFlyerStatus,TotalSpent
FROM CTE_spending
WHERE rn =1

-----------------------------------------------------------------------------------------------------------------------------------
-- Q9) Find the total revenue and number of tickets sold fpr each airline, and rank the airline based on total revenue.

WITH cte_airlinerevenue AS (
SELECT a.AirlineID, A.Name as AirlineName,
        COUNT(t.TicketID) AS TicketSold,
        SUM(t.Price) AS TotalRevenue
FROM Airlines as a
JOIN Flights f ON a.AirlineID = F.AirlineID
join Tickets T on F.FlightID = t.FlightID
GROUP BY a.AirlineID, A.Name
) 

SELECT 
AirlineID, TicketSold, TotalRevenue,
RANK() OVER (order by TotalRevenue DESC ) AS RevenueRank
FROM cte_airlinerevenue

---------------------------------------------------------------------------------------------------------------------------------
-- Q10) For each passsenger, identify their most frequently used airline. If a passenger has multiple airline with the same highest usage, show all such airlines.


WITH cte_airlinerank AS (
    SELECT *,
            RANK() OVER (PARTITION BY PassengerID ORDER BY TicketsWithAirline DESC ) AS AirlineRank
    FROM (
            SELECT p.PassengerID, p.Name AS passengerName, a.AirlineID, a.Name AS AirlineName,
                COUNT(*) AS TicketsWithAirline
            FROM Passengers p
            JOIN Tickets t on p.PassengerID = t.PassengerID
            JOIN Flights f on t.FlightID = f.FlightID
            JOIN Airlines a on a.AirlineID = f.AirlineID
            GROUP BY p.PassengerID, p.Name, a.AirlineID, a.Name

        )t
)

SELECT PassengerID, PassengerName, AirlineName ,TicketsWithAirline
FROM cte_airlinerank 
WHERE AirlineRank = 1