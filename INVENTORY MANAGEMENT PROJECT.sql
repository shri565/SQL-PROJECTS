CREATE DATABASE INVENTORY;

USE INVENTORY;
/* TABLE CREATION*/
CREATE TABLE SUPPLIER (SID CHAR(5) PRIMARY KEY,SNAME VARCHAR(20) NOT NULL,SADD VARCHAR(20) NOT NULL,
						SCITY VARCHAR(15) DEFAULT 'DELHI',SPHONE VARCHAR(13) UNIQUE,MAIL VARCHAR(20));

CREATE TABLE PRODUCT (PID CHAR(5) PRIMARY KEY,PDESC VARCHAR(20) NOT NULL,PRICE INT CHECK(PRICE>0),
					CATEGORY VARCHAR(20),SID CHAR(5) FOREIGN KEY REFERENCES SUPPLIER(SID));

CREATE TABLE STOCK (PID CHAR(5) FOREIGN KEY REFERENCES PRODUCT(PID),SQTY INT CHECK(SQTY>=0),
					ROL INT CHECK(ROL >0),MOQ INT CHECK (MOQ>=5));

CREATE TABLE CUSTOMER (CID CHAR(5) PRIMARY KEY,CNAME VARCHAR(15) NOT NULL,ADDRESS VARCHAR(15) NOT NULL,
					CITY VARCHAR(15) NOT NULL,PHONE VARCHAR(13) NOT NULL,EMAIL VARCHAR(20) NOT NULL,
					DOB DATE CHECK(DOB<'1-JAN-2002'));

CREATE TABLE ORDERS (OID CHAR(5) PRIMARY KEY,ODATE DATE,PID CHAR(5) FOREIGN KEY REFERENCES PRODUCT(PID),
					CID CHAR(5) FOREIGN KEY REFERENCES CUSTOMER(CID),OQTY INT CHECK(OQTY>=1));

CREATE TABLE PURCHASE (PURID CHAR(5) PRIMARY KEY,PID CHAR(5) FOREIGN KEY REFERENCES PRODUCT(PID),
						SID CHAR(5) FOREIGN KEY REFERENCES SUPPLIER(SID),PQTY INT,DOP DATE);


--ID GENERATION(LIKE 'P0001' OR 'C0001') BY USER DEFINED FUNCTION

CREATE FUNCTION ID_GENERATION (@V AS CHAR(1),@I AS INT)
RETURNS CHAR(5)
AS
BEGIN
	DECLARE @ID AS CHAR(5)
	SET @ID= CASE WHEN @I<10 THEN CONCAT(@V,'000',@I)
				WHEN @I<100 THEN CONCAT(@V,'00',@I)
				WHEN @I<1000 THEN CONCAT(@V,'0',@I)
				WHEN @I<10000 THEN CONCAT(@V,@I)
				ELSE 'NA'
				END
	RETURN @ID
END;

--CREATING 5  DIFFERENT SEQUENCES FOR 5 DIFFERENT TABLE
CREATE SEQUENCE S1 
AS INT
START WITH 1
INCREMENT BY 1;

CREATE SEQUENCE S2 
AS INT
START WITH 1
INCREMENT BY 1;

CREATE SEQUENCE S3 
AS INT
START WITH 1
INCREMENT BY 1;

CREATE SEQUENCE S4 
AS INT
START WITH 1
INCREMENT BY 1;

CREATE SEQUENCE S5 
AS INT
START WITH 1
INCREMENT BY 1;

--CREATING PROCEDURES FOR INSERTING VALUES
--1) FOR SUPPLIER
CREATE PROCEDURE SUPPLIER_PROC @SNAME VARCHAR(20) ,@SADD VARCHAR(20),
								@SCITY VARCHAR(15) ,@SPHONE VARCHAR(13) ,@MAIL VARCHAR(20)
AS 
BEGIN
	DECLARE @SID AS CHAR(5)
	DECLARE @I AS INT
	SET @I= (NEXT VALUE FOR S1)
	SET @SID= (SELECT DBO.ID_GENERATION('S',@I))
	INSERT INTO SUPPLIER  VALUES(@SID,@SNAME,@SADD,@SCITY ,@SPHONE,@MAIL)
	SELECT * FROM SUPPLIER
END;

--2) FOR PRODUCT
CREATE PROCEDURE PRODUCT_PROC @PDESC VARCHAR(20) ,@PRICE INT ,@CATEGORY VARCHAR(20),@SID CHAR(5)
AS 
BEGIN
	DECLARE @PID AS CHAR(5)
	DECLARE @I AS INT
	SET @I= (NEXT VALUE FOR S2)
	SET @PID= (SELECT DBO.ID_GENERATION('P',@I))
	INSERT INTO PRODUCT  VALUES(@PID,@PDESC ,@PRICE ,@CATEGORY ,@SID )
	SELECT * FROM PRODUCT
END;

--3) FOR STOCK
CREATE PROCEDURE STOCK_PROC @PID CHAR(5),@SQTY INT,@ROL INT,@MOQ INT 
AS 
BEGIN
	INSERT INTO STOCK  VALUES(@PID,@SQTY,@ROL,@MOQ)
	SELECT * FROM STOCK
END;

--4) FOR CUSTOMER
CREATE PROCEDURE CUSTOMER_PROC @CNAME VARCHAR(15),@ADDRESS VARCHAR(15),
					@CITY VARCHAR(15) ,@PHONE VARCHAR(13),@EMAIL VARCHAR(20),
					@DOB DATE
AS 
BEGIN
	DECLARE @CID AS CHAR(5)
	DECLARE @I AS INT
	SET @I= (NEXT VALUE FOR S3)
	SET @CID= (SELECT DBO.ID_GENERATION('C',@I))
	INSERT INTO CUSTOMER  VALUES(@CID,@CNAME,@ADDRESS,@CITY ,@PHONE ,@EMAIL,@DOB )
	SELECT * FROM CUSTOMER
END;

--5) FOR ORDERS
CREATE PROCEDURE ORDERS_PROC @ODATE DATE,@PID CHAR(5),@CID CHAR(5),@OQTY INT 
AS 
BEGIN
	DECLARE @OID AS CHAR(5)
	DECLARE @I AS INT
	SET @I= (NEXT VALUE FOR S4)
	SET @OID= (SELECT DBO.ID_GENERATION('O',@I))
	INSERT INTO ORDERS  VALUES(@OID,@ODATE,@PID,@CID,@OQTY)
	SELECT * FROM ORDERS
END;

--6) PURCHASE
CREATE PROCEDURE PURCHASE1 @PID CHAR(5),@SID CHAR(5) ,@PQTY INT,@DOP DATE
AS
BEGIN
	DECLARE @PURID AS CHAR(5)
	DECLARE @I AS INT
	SET @I= (NEXT VALUE FOR S5)
	SET @PURID= (SELECT DBO.ID_GENERATION('U',@I))
	INSERT INTO PURCHASE VALUES (@PURID,@PID,@SID,@PQTY ,@DOP)
END;


--TRIGGERS
--1) FOR INSERT
CREATE TRIGGER TRIG1
ON ORDERS
FOR INSERT
AS
BEGIN
	SET NOCOUNT ON
	DECLARE @QS AS INT
	DECLARE @QR AS INT

	SET @QS= (SELECT SQTY FROM STOCK WHERE PID= (SELECT PID  FROM INSERTED))
	SET @QR= (SELECT OQTY FROM INSERTED )

	IF (@QS-@QR)>0
	BEGIN
		UPDATE STOCK SET SQTY= (@QS-@QR) WHERE PID= (SELECT PID  FROM INSERTED);
		COMMIT;
		PRINT('CONGRATS...!ORDER PLACED');
	END;
	ELSE
	BEGIN
		ROLLBACK;
		PRINT('THE ORDERED QUANTITY OF THE PRODUCT IS NOT AVAILABLE');
	END;
END;

--2) FOR UPDATE
CREATE TRIGGER TRIG2
ON ORDERS
FOR UPDATE
AS
BEGIN
	SET NOCOUNT ON
	DECLARE @QS AS INT
	DECLARE @QR AS INT
	DECLARE @QR2 AS INT

	SET @QS= (SELECT SQTY FROM STOCK WHERE PID= (SELECT PID  FROM INSERTED))
	SET @QR= (SELECT OQTY FROM DELETED )
	SET @QR2=(SELECT OQTY FROM INSERTED)

	IF (@QS+@QR-@QR2)>0
	BEGIN
		UPDATE STOCK SET SQTY= (@QS+@QR-@QR2) WHERE PID= (SELECT PID  FROM INSERTED);
		COMMIT;
		PRINT('CONGRATS...!ORDER PLACED');
	END;
	ELSE
	BEGIN
		ROLLBACK;
		PRINT('THE ORDERED QUANTITY OF THE PRODUCT IS NOT AVAILABLE');
	END;
END;


----REPORT---
--1)CUSTOMER_LEDGER_REPORT
CREATE PROCEDURE CUSTOMER_LEDGER_REPORT @CID AS CHAR(5)
AS
BEGIN
	SELECT OID,ODATE,CNAME,ADDRESS,PHONE,PDESC,PRICE,OQTY,(PRICE*OQTY) AS AMOUNT FROM CUSTOMER
	INNER JOIN ORDERS
	ON CUSTOMER.CID=ORDERS.CID
	INNER JOIN PRODUCT
	ON PRODUCT.PID=ORDERS.PID
	WHERE CUSTOMER.CID= @CID
END;

--2)SUPPLIER_LEDGER_REPORT
CREATE PROCEDURE SUPPLIER_LEDGER_REPORT @SID AS CHAR(5)
AS
BEGIN
	SELECT PURID,SNAME,SCITY,SADD,PDESC,PRICE,PQTY,(PRICE*PQTY)AS AMOUNT ,DOP FROM SUPPLIER
	INNER JOIN PURCHASE
	ON SUPPLIER.SID=PURCHASE.SID
	INNER JOIN PRODUCT
	ON PRODUCT.PID=PURCHASE.PID
	WHERE SUPPLIER.SID= @SID
END;
