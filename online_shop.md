```mermaid
erDiagram
    user {
        int user_id
        String username
        String password
        String first_name
        String last_name
        timestamp last_login
        boolean is_active
        timestamp created_at
        timestamp updated_at
    }

    role {
        int role_id
        String role_name
        timestamp created_at
        timestamp updated_at
    }

    user_role {
        int user_id
        int role_id
        timestamp created_at
        timestamp updated_at
    }

    user_address {
        int user_id
        int address_id
        timestamp created_at
        timestamp updated_at
    }

    address {
        int address_id
        String address
        int city_id
        timestamp created_at
        timestamp updated_at
    }

    city {
        int city_id
        String city
        int country_id
        timestamp created_at
        timestamp updated_at
    }

    country {
        int country_id
        String country
        timestamp created_at
        timestamp updated_at
    }

    category{
        int category_id
        String name
        timestamp created_at
        timestamp updated_at
    }

    product {
        int product_id
        String name
        String description
        double price
        int category_id
        timestamp created_at
        timestamp updated_at
    }
    
    stock {
        int stock_id
        int product_id
        int quantity
        timestamp created_at
        timestamp updated_at
    }

    cart {
        int cart_id
        int user_id
        boolean is_active
        timestamp created_at
        timestamp updated_at
    }

    cart_product {
        int cart_id
        int product_id
        int quantity
        timestamp created_at
        timestamp updated_at
    }

    order {
        serial order_id
        int user_id
        int cart_id
        int delivery_address
        int invoice_address
        String status
        double price
        timestamp created_at
        timestamp updated_at
    }
    
    stock_log {
        int stock_log_id
        int product_id
        int quantity
        timestamp created_at
        timestamp updated_at
    }

    user ||--|{ user_role: ""
    role ||--o{ user_role: ""
    user ||--o{ user_address: ""
    user ||--o{ cart: ""

    address ||--o{ user_address: ""
    city ||--|{ address: ""
    country ||--|{ city: ""

    product ||--|| category: ""
    product ||--o{ cart_product: ""
    product ||--o{ stock_log: ""
    product ||--o{ stock: ""
    
    cart ||--|{ cart_product: ""
    cart ||--|| order: ""

    order ||--|{ address: ""
    user ||--o{ order: ""
```
## Relationships
- A user can have one or more roles. A role can be assigned to 0 or more users
- A user can have 0 or more addresses. An address can belong to 0 or more users
- A user can have 0 or more carts ( not at the same time )
- A city can have 1 or more addresses
- A country can have 1 or more cities
- A product can have 1 category
- A product can have 0 or more stock_logs 
- A cart can have one or more products. A product can be assigned to 0 or more carts
- A user can have 0 or more orders.

## Constraints notes
- Users: username = unique
- Category: name = not null and unique
- Cart: is_active default is true
- To ensure one active cart at all time:
  - Option1: a unique partial index on user_id where is_active = true
  - Option2: an exclude constraint on user_id where is_active = true 
  - Option3: a trigger
- Trigger before insert on user_address => if 5 addresses for user then rollback 
- Trigger before update for each entity => set updated_at to current_timestamp
- Trigger before delete for users:
  - Option1: just raise an exception => all "deletes" must be done using update users set is_active = 0
  - Option2: update in the trigger and return null
- Product: fk(category_id) on update cascade on delete set null (maybe)

## Potential indexes
- Order -> created_at
- Product -> name (maybe)