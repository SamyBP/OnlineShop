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

### Setup
1. Create a database **online_shop**
2. Navigate to the [scripts](scripts) directory and run the following command to restore the database schema
   ````
      pg_restore -U postgres -d online_shop schema.sql
   ````
3. After restoration run the **setup.sql** script to populate the database. The script creates n number of users and assigns the role of Administrator to [n/3] random users, the role of Regular user to [n/3] random users, and for the rest both roles.
   The script also creates m categories, creating a random number (between 1 and p) of products for each category, for each product is assigned a random price (between 1 and x) and a random quantity (between 1 and q)   
   e.g:
   ````
      psql -U postgres -d online_shop -f setup.sql -v n= -v m= -v p= -v q= -v x=
   ````