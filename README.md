## Online Shop Database Design

### Description
- The database is designed to handle various functionalities required for an online store.
- The application supports the following user roles with additional ones that can be added in the future:
  - Administrator
  - Regular User
- The application allows the definition of a set of products, each product belongs to a single product category
- The application allows users
  - To add a product to a cart, each user can have only one active cart at a time
  - To have at most five addresses
  - To place an order where the user can choose one of his stored address as the delivery address and/or invoice address
- The database lets **os_admin** and **os_rguser** to connect to it, with the following privileges [Privileges.sql](Privileges.sql)

  | Users     	| Create     	| Read       	| Update                                        	| Delete                  	| Execute                                                                             	|
  |-----------	|------------	|------------	|-----------------------------------------------	|-------------------------	|-------------------------------------------------------------------------------------	|
  | os_admin  	| All tables 	| All tables 	| All tables                                    	| All tables except users 	| All functions and procedures                                                        	|
  | os_rguser 	| All tables 	| All tables 	| All tables except is_active column from users 	| All tables except users 	| All functions and procedures except [MarkUsersDeleted](procedures/MarkUsersDeleted) 	|

### Setup
1. Create a database **online_shop**
2. Navigate to the [scripts](scripts) directory and run the following command to restore the database schema, or open the script in pgAdmin and execute it there.
   ````
      psql -U postgres -d online_shop -f .\schema.sql
   ````
3. After restoration run the **setup.sql** script to populate the database. The script creates **n** number of users and assigns the role of Administrator to **[n/3]** random users, the role of Regular user to **[n/3]** random users, and for the rest both roles.
   The script also creates **m** categories, creating a random number (between 1 and **p**) of products for each category, for each product a random price is assigned (between 1 and **x**) and a random quantity (between 1 and **q**).
   For each user an address is stored, and the script places **o** orders for random users, each user ordering a random number of products
   
  **Note**: The script uses the functions from the [functions](functions) directory for randomization
   ````
      psql -U postgres -d online_shop -f setup.sql -v n= -v m= -v p= -v q= -v x= -v o=
   ````
### Usage
- To add a product to a users cart call the procedure [AddToCart](procedures/AddToCart.sql). 
    - The first parameter represents the user_id as integer
    - The second parameter represents the product_id as integer
    - The third parameter represents the quantity the user wants for that product
    - The product will be added to the users active cart, if no active cart then the procedure will create a new one for the user
  ````sql
        call os.add_to_cart(user_id::int, product_id::int, desired_quantity::int);
  ````
- To store an address for a specific user call the procedure [StoreUserAddress](procedures/StoreUserAddress.sql)  
  - The first parameter represents the user_id as integer
  - The second represents the Country's name as text
  - The third represents the City's name as text
  - The last one represents the Address name as text
  - If a user already has 5 addresses stored then an exception will be raised and the address will not be stored
  ````sql
        call os.store_user_address(user_id::int, country_name::text, city_name::text, address_name::text);
  ````
- To place an order for a specific user call the procedure [PlaceOrder](procedures/PlaceOrder.sql)
  - The first parameter represents the user_id as integer
  - The second parameter represents the delivery_address_id as integer
  - The last parameter represents the invoice_address_id as integer
  - If the user doesn't have an active cart an exception will be raised and the order will not be placed
  - If the current stock of a product from the cart does not meet the required quantity the order will not be placed
  - If successful then the cart will become inactive and the total order price is calculated
  ````sql
        call os.place_order(user_id::int, delivery_address_id::int, invoice_address_id::int);
  ````
- To mark users with an inactivity greater than 2 years call the procedure [MarkUsersDeleted](procedures/MarkUsersDeleted.sql) while logged in as **os_admin**
  - The procedure will set is_active to false for each user that last logged since 2 years ago
  ````sql
        call os.mark_users_deleted();
  ````