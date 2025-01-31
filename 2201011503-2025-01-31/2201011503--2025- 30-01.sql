create database land_selling_management_system;
use land_selling_management_system;

CREATE TABLE Users (
    user_id INT PRIMARY KEY,
    name VARCHAR(100),
    contact_no VARCHAR(20),
    email VARCHAR(100) UNIQUE,
    role VARCHAR(50)
);

CREATE TABLE Land (
    land_id INT PRIMARY KEY,
    description TEXT,
    location VARCHAR(255),
    size DECIMAL(10, 2),
    price DECIMAL(15, 2),
    user_id INT,
    FOREIGN KEY (user_id) REFERENCES Users(user_id)
);

CREATE TABLE Transaction (
    transaction_id INT PRIMARY KEY,
    buyer_id INT,
    seller_id INT,
    land_id INT,
    date DATE,
    status VARCHAR(50),
    FOREIGN KEY (buyer_id) REFERENCES Users(user_id),
    FOREIGN KEY (seller_id) REFERENCES Users(user_id),
    FOREIGN KEY (land_id) REFERENCES Land(land_id)
);

CREATE TABLE Inquiry (
    inquiry_id INT PRIMARY KEY,
    user_id INT,
    land_id INT,
    inquiry_date DATE,
    message TEXT,
    FOREIGN KEY (user_id) REFERENCES Users(user_id),
    FOREIGN KEY (land_id) REFERENCES Land(land_id)
);

-- SQL Queries
-- User Table

   INSERT INTO Users (user_id, name, contact_no, email, role)
   VALUES 
   (01, 'cassper.d', '07234567890', 'cass.d@gmail.com', 'Seller');
   -- read--
   select * from Users;
   
    -- UPDATE--
    
    update users set name = 'CASLA.U' where user_id = 01;
    
    -- LAND table --
    
    INSERT INTO Land (land_id, description, location, size, price, user_id) 
    VALUES 
    (1, 'Beautiful land', 'State Park', 1.5, 150000.00, 01);
    select * from Land;
    update Land set price='170000' where land_id = 1;
    delete from land where land_id = 1;
    
    -- Transaction Table --
    
     INSERT INTO Transaction (transaction_id, buyer_id, seller_id, land_id, date, status) 
     VALUES 
     (1, 1, 1, 1, '2023-10-10', 'Completed');
     select * from Transaction;
     update  Transaction  set status='Pending' where transaction_id = 1;
     
     -- Inquiry Table --
     
     INSERT INTO Inquiry (inquiry_id, user_id, land_id, inquiry_date, message)
     VALUES 
     (1,01,1,'2024-12-10','still on the market');
     
    select * from Inquiry;
    UPDATE Inquiry set message = 'need more information' where inquiry_id = 1; 
    
    -- pl/sql --
    
    -- 1
    -- view of all available lands -- 
    
      CREATE VIEW v_available_lands AS 
    SELECT * FROM Land WHERE land_id NOT IN (SELECT land_id FROM Transaction WHERE status='pending');

  -- 2  
-- views to show inquiries relatedto some land-- 
    
    CREATE VIEW v_land_inquiries AS 
    SELECT l.description, i.message 
    FROM Inquiry i
    JOIN Land l ON l.land_id = i.land_id;
   
   -- 3
    -- view showing user roles counts --
    
      CREATE VIEW v_users_roles_count AS
    SELECT role, COUNT(*) as user_count FROM UserS GROUP BY role;
    
    -- 4
    -- View of User's transactions-

     CREATE VIEW v_user_transactions AS
    SELECT t.transaction_id, u.name AS buyer_name, l.description AS land_description, t.date, t.status
    FROM Transaction t
    JOIN Users u ON t.buyer_id = u.user_id
    JOIN Land l ON t.land_id = l.land_id;
    
    -- 5
    -- View to summarized transactions by status
     CREATE VIEW v_transaction_summary AS
    SELECT status, COUNT(*) as total FROM Transaction GROUP BY status;
    
    -- 6
--  View for lands sold by a seller

CREATE VIEW v_lands_sold_by AS
    SELECT l.description, u.name, t.status
    FROM Transaction t
    JOIN Land l ON t.land_id = l.land_id
    JOIN Users u ON t.seller_id = u.user_id;

--  Stored Procedures
-- 1 add user

show tables;
DELIMITER //
 CREATE PROCEDURE add_user(
 p_id INT ,
 p_name VARCHAR(100), 
 p_contact VARCHAR(13), 
 p_email VARCHAR(50), 
 p_role VARCHAR(100)
 ) 
 
    BEGIN
        INSERT INTO Users (user_id, name, contact_no, email, role) 
        VALUES 
        (p_id, p_name, p_contact, p_email, p_role);
        
    END;
    
    select * from Users;
    -- 2
    -- edit land price
     DELIMITER //
CREATE  PROCEDURE edit_land_price(p_land_id INT, p_new_price DECIMAL) 
 
    BEGIN
        UPDATE Land SET price = p_new_price WHERE land_id = p_land_id;
    END;
   
   -- 3 
   -- Complete Transaction
   DELIMITER //
   CREATE PROCEDURE complete_transaction(p_id INT)  
    BEGIN
        UPDATE Transaction SET status = 'Completed' WHERE transaction_id = p_id;
    END;
    
    -- 4
    -- Add Inquiry
    DELIMITER //
    CREATE  PROCEDURE add_inquiry(p_user_id INT, p_land_id INT, p_date DATE, p_message TEXT)  
    BEGIN
        INSERT INTO Inquiry (user_id, land_id, inquiry_date, message) 
        VALUES (p_user_id, p_land_id, p_date, p_message);
    END;
    
    -- 5
    -- Get User Details by ID
    DELIMITER //
    CREATE  PROCEDURE get_user_details  (
    
    in p_user_id INT, 
        v_name VARCHAR(100),
        v_contact VARCHAR(20),
        v_email VARCHAR(100),
        v_role VARCHAR(50)
)
BEGIN
    DECLARE user_count INT;
    SELECT name, contact, email, role INTO v_name, v_contact, v_email, v_role
    FROM users
    WHERE user_id = p_user_id;
    SELECT FOUND_ROWS() INTO user_count;
    
    IF user_count = 0 THEN
        SET v_name = NULL;
        SET v_contact = NULL;
        SET v_email = NULL;
        SET v_role = NULL;
    END IF;
END //
-- 6
-- Delete Land Record
DELIMITER //
CREATE  PROCEDURE delete_land(p_land_id INT)  
    BEGIN
        DELETE FROM Land WHERE land_id = p_land_id;
    END; 
    
    -- triggers
    -- 1
    -- Add User
    DELIMITER //
CREATE TRIGGER trig_user_after_insert
AFTER INSERT ON Users
FOR EACH ROW
BEGIN
    INSERT INTO user_log (log_message, created_at)
    VALUES (CONCAT('New User Added: ', NEW.name), NOW());
END //

DELIMITER ;
-- 2
-- Trigger for after inserting Land
DELIMITER //
CREATE TRIGGER after_insert_land
AFTER INSERT ON Land
FOR EACH ROW
BEGIN
   
    insert into Land_Log(land_id, description, date)
    values (NEW.land_id, '2024-12-10', NOW());
END ;//
DELIMITER ;

-- 4
-- Trigger for after inserting Transaction
DELIMITER //
CREATE TRIGGER _after_insert_transaction
AFTER INSERT ON Transaction
FOR EACH ROW
BEGIN
    insert into Transaction_Log(transaction_id, land_id, buyer_id, seller_id, date, status)
    values (NEW.transaction_id, NEW.land_id, NEW.seller_id, '2024-10-05', NOW());
END //
DELIMITER ;
-- 5
-- Trigger for after inserting Inquiry
DELIMITER //
CREATE  TRIGGER _after_insert_inquiry
    AFTER INSERT ON Inquiry
    FOR EACH ROW
    BEGIN
    insert into Inquiry_Log(inquiry_id, user_id, land_id, inquiry_date,message)
    values
    ((NEW.inquiry_id, NEW.user_id, NEW.land_id, NEW.inquiry_date,'new inquiry'));
    END; //
    
    -- 6
-- Trigger for after updating User
DELIMITER //
 CREATE  TRIGGER after_update_user
    AFTER UPDATE ON Users
    FOR EACH ROW
    BEGIN
        insert into Users_Log(user_id, old_name,new_name, old_contact_no, new_contact_no,old_email, new_email,role)
        values (OLD.user_id, OLD.name, NEW.name, OLD.contact_no, NEW.contact_no,OLD.email, NEW.email,'buyer', NOW());
    END; //


create user 'DUSHIME_HONORE30'@'127.0.0.1'identified by'2201011503';
grant all privileges on land_selling_management_system . * to 'DUSHIME_HONORE30'@'127.0.0.1';
flush privileges;
    
    
    
    
    
    
    
    
   

