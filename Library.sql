-- Create Books Table 
CREATE TABLE books(
	bookid SERIAL PRIMARY KEY,
	title VARCHAR(255),
	author VARCHAR(50),
	genre VARCHAR(50),
	pudlisheddate DATE,
	isbn VARCHAR(50) NOT NULL, 
	copiesavailable INT
);

--Create Members Table
CREATE TABLE members(
	memberid SERIAL PRIMARY KEY,
	firstname VARCHAR(50),
	latname VARCHAR(50),
	email VARCHAR(255),
	registereddate DATE NOT NULL
);

DROP TABLE members;

-- Create loan table
CREATE TABLE loan(
	loanid SERIAL PRIMARY KEY,
	bookid SERIAL,
	memberid SERIAL,
	loandate DATE NOT NULL,
	Duedate DATE NOT NULL,
	returndate DATE,
	FOREIGN KEY (bookid) REFERENCES books(bookid),
	FOREIGN KEY (memberid) REFERENCES members(memberid)
);


/*1.How can you identify members who frequently borrow books from a specific genre but have never borrowed from 
another specified genre?*/

SELECT m.memberid, m.firstname, m.latname, b.genre
FROM members m
JOIN books b
ON m.memberid=b.bookid 
WHERE genre = 'Thriller' 
AND m.memberid NOT IN
	(SELECT m.memberid
	FROM members m
	JOIN books b
	ON m.memberid=b.bookid
	WHERE genre = 'Fantasy');		

--OR

SELECT DISTINCT m.memberID, m.firstName, m.latName, b.genre
FROM members m
JOIN loan l ON m.memberID = l.memberID
JOIN books b ON l.bookid = b.bookid
WHERE b.genre = 'Thriller'  -- Replace with your desired genre
AND m.MemberID NOT IN (
    SELECT l.memberid
    FROM loan l
    JOIN books b ON l.bookid = b.bookid
    WHERE b.genre = 'Fantasy'  -- Replace with the genre to be excluded
);
GROUP BY m.memberid;

HAVING COUNT(l.bookid) > 3; 


/*Which books have been consistently borrowed and returned late, and what is the average number of 
days late for each book?*/
SELECT b.bookid, b.title, AVG(l.returndate - l.duedate) AS AvgDaysLate
FROM books b
JOIN loan l ON b.bookid = l.bookid
WHERE l.returndate > l.duedate
GROUP BY b.bookid, b.title
ORDER BY AvgDaysLate DESC;

/*What are the top 5 most frequently loaned books, considering only loans that were returned late?*/

SELECT b.title, COUNT(b.title)
FROM loan l, books b
WHERE l.returndate > l.Duedate
GROUP BY b.title
LIMIT 5;

/*3.How can you find members who have borrowed books with a diverse set of genres 
(e.g., at least one book from more than 3 distinct genres)?*/

SELECT l.memberid, m.firstname, m.latname, COUNT(b.genre) AS genre_count
FROM loan l
JOIN members m ON l.memberid = m.memberid
JOIN books b ON l.bookid = b.bookid
GROUP BY l.memberid, m.firstname, m.latname
HAVING COUNT(b.genre) > 3;

/*4.How would you rank the books based on their popularity (number of loans) and also include their average 
loan duration (from LoanDate to ReturnDate) for all completed loans?*/

SELECT b.title, COUNT(l.bookid) AS ranking, AVG(returndate-loandate) AS Average_loan_duration, b.genre
FROM loan l
JOIN members m ON l.memberid = m.memberid
JOIN books b ON l.bookid = b.bookid
GROUP BY b.title, b.genre
ORDER BY ranking DESC;


/*5.Which books have the longest average loan durations, and how does this correlate with the book's 
genre or publication date?*/

SELECT b.title, AVG(returndate-loandate) AS Average_loan_duration, b.genre, b.pudlisheddate
FROM loan l
JOIN members m
ON m.memberid = l.memberid
JOIN books b
ON b.bookid = l.bookid
GROUP BY b.title, b.genre, b.pudlisheddate
ORDER BY Average_loan_duration DESC;

/*6.How can you generate a report showing the number of overdue loans per member, along with the total 
number of days those loans were overdue?*/

SELECT b.title, COUNT(returndate-duedate) AS No_of_due_days, l.loanid
FROM loan l
JOIN books b
ON b.bookid = l.bookid
WHERE returndate > duedate 
GROUP BY b.title, l.returndate-l.loandate, l.loanid
ORDER BY l.loanid ASC;

/*7.	How would you identify the most popular authors based on the total number of loans across all 
their books, and which of their books are most frequently borrowed?*/


SELECT b.author, COUNT(l.bookid)
FROM loan l
JOIN books b
ON b.bookid = l.loanid
GROUP BY b.author
ORDER BY COUNT(l.bookid) DESC;

/*8 How can you calculate the proportion of books loaned out compared to the total available copies
in the library for each genre?*/
SELECT b.genre,
       COUNT(l.loanid) AS total_loans,
       SUM(b.copiesavailable) AS total_copies,
       COUNT(l.loanid) / SUM(b.copiesavailable) AS loaned_proportion
FROM books b
LEFT JOIN loan l ON b.bookid = l.bookid
GROUP BY b.genre;

/*9 How can you detect borrowing patterns, such as members who tend to borrow books within a short time 
after another specific member returns a book?*/

SELECT b.title,l.loandate, l.returndate, (l.returndate-l.loandate) AS TIME
FROM loan l
JOIN members m
ON m.memberid = l.loanid
JOIN books b
ON b.bookid = l.loanid
GROUP BY l.loandate, l.returndate, (l.returndate-l.loandate), b.title
ORDER BY (l.returndate-l.loandate) ASC;


SELECT l1.memberid AS original_member,
       l2.memberid AS subsequent_member,
       b.title,
       l1.returndate AS original_return_date,
       l2.loandate AS subsequent_loan_date,
       (l2.loandate - l1.returndate) AS days_between
FROM loan l1
JOIN loan l2 ON l1.bookid = l2.bookid
JOIN books b ON l1.bookid = b.bookid
WHERE l1.memberid <> l2.memberid  -- Different members (not equal to)
AND (l2.loandate - l1.returndate) BETWEEN 1 AND 7  -- Within a short time, e.g., 1 to 7 days
ORDER BY original_member, subsequent_member, l1.returndate;

/* 10.How would you identify books that have been borrowed more frequently during certain months or seasons 
(e.g., summer vs. winter), and what patterns emerge by genre?*/
SELECT b.genre,
       EXTRACT(MONTH FROM l.loandate) AS loan_month,
       COUNT(l.loanid) AS loan_count
FROM loan l
JOIN books b ON l.bookid = b.bookid
GROUP BY b.genre, EXTRACT(MONTH FROM l.loandate)
ORDER BY b.genre, loan_month;

/*11.	How can you identify members who have borrowed books consecutively (i.e., borrowing a new book immediately 
after returning a previous one)? */
SELECT m.memberid, m.firstname, m.latname,
	   l1.loandate AS first_borrow,
	   l1.returndate AS first_return,
	   l2.loandate AS second_borrow,
	   (l2.loandate-l1.returndate) AS gap
FROM loan l1
JOIN loan l2 ON l1.bookid = l2.bookid
JOIN members m ON m.memberid = l1.loanid
WHERE l2.loandate-l1.returndate BETWEEN 0 AND 4
GROUP BY m.memberid, l1.loandate, l1.returndate, l2.loandate, m.firstname, m.latname
ORDER BY gap DESC;


SELECT m.memberid, m.firstname, m.latname,
       l1.loandate AS first_borrow,
       b1.title AS first_book,
       l1.returndate AS first_return,
       l2.loandate AS second_borrow,
       b2.title AS second_book,
       (l2.loandate - l1.returndate) AS gap
FROM loan l1
JOIN loan l2 ON l1.memberid = l2.memberid
             AND l2.loandate > l1.returndate  -- Second loan after the first return
JOIN books b1 ON l1.bookid = b1.bookid
JOIN books b2 ON l2.bookid = b2.bookid
JOIN members m ON l1.memberid = m.memberid
WHERE (l2.loandate - l1.returndate) BETWEEN 0 AND 4  -- Borrowing within 0 to 4 days
ORDER BY gap ASC;

/*12.	Which books have been consistently borrowed and returned late, and what is the average number of 
days late for each book?*/

SELECT b.bookid, b.title, AVG(l.returndate - l.duedate) AS AvgDaysLate
FROM books b
JOIN loan l ON b.bookid = l.bookid
WHERE l.returndate > l.duedate
GROUP BY b.bookid, b.title
ORDER BY AvgDaysLate DESC;

/*How would you calculate the "borrow rate" of books based on the time they spend in circulation 
versus the time they are available?*/
SELECT b.bookid, b.title, 
	   (l1.returndate-l1.loandate)AS circulation,
	   (l2.loandate-l1.returndate) AS time_avaible,
	    AS borrow_rate
FROM loan l1
JOIN loan l2 on L2.loanid= l2.bookid
JOIN books b ON l1.bookid= l2.bookid
WHERE l2.loandate > l1.returndate
GROUP BY b.bookid, b.title;

WITH LoanDurations AS (
    SELECT b.bookid, 
           b.title, 
           SUM(l.returndate - l.loandate) AS time_in_circulation  -- Total days the book has been on loan
    FROM books b
    LEFT JOIN loan l ON b.bookid = l.bookid
    WHERE l.returndate IS NOT NULL  -- Only consider completed loans
    GROUP BY b.bookid, b.title
),
TotalAvailableTime AS (
    SELECT b.bookid, 
           b.title,
           (CURRENT_DATE - b.dateadded) AS total_time_available  -- Total time available since the book was added
    FROM books b
)
SELECT t.bookid, 
       t.title, 
       COALESCE(ld.time_in_circulation, 0) AS time_in_circulation,  -- If no loans, time_in_circulation = 0
       t.total_time_available,
       COALESCE(ld.time_in_circulation, 0) / t.total_time_available AS borrow_rate  -- Borrow rate calculation
FROM TotalAvailableTime t
LEFT JOIN LoanDurations ld ON t.bookid = ld.bookid
ORDER BY borrow_rate DESC;
	   


















