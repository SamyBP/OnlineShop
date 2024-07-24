### Product Description: Online Shop Database Design

Create and implement a database for an online shop application that is well-structured, efficient, and capable of handling various functionalities required for an online store.

The application should support the following user roles:
* Administrator
* Regular User

Note that a single user can have both Administrator and Regular User roles, and additional roles may be added in the future.

#### Key Features:

1. **Product Management:**
    * The application should allow the definition of a set of products.
    * Each product must belong to a single product category.
    * A category is identified by its name, and no two categories can have the same name.
    * The application should track the stock for each product.
    * An order cannot be completed if the items in the cart are not available in stock.
    * The application should log any new stock received for each product.
    * For each product, and administrator can set the product name, a description (size limit of 200 characters).

2. **Cart and Order Management:**
    * Users can add products to a cart along with their quantities and which the current product price.
    * Each user can have only one active cart at a time.
    * Users can store up to five addresses.
    * When placing an order, users can choose one of their stored addresses as the delivery address and/or invoice address.
    * An order is identified by the user, delivery address, invoice address, and the set of products.

#### Constraints:
* Each entity should have the following fields:
    * **created_at**: Represents the timestamp without timezone when the entity was created.
    * **updated_at**: Represents the last timestamp when the entity was updated.

#### Additional Considerations:
* Ensure that the database design can accommodate potential future requirements and scalability.
* Consider implementing audit trails for critical actions performed by users, especially administrators.
* Include appropriate indexing and optimization techniques to ensure efficient query performance.
* User deletion is forbidden. A user can be deleted by a soft delete. 