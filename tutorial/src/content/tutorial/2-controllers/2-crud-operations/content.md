---
type: lesson
title: CRUD Operations
focus: /workspace/store/app/controllers/products_controller.rb
previews: [3000]
mainCommand: ['node scripts/rails.js server', 'Starting Rails server']
prepareCommands:
  - ['npm install', 'Preparing Ruby runtime']
  - ['node scripts/rails.js db:prepare', 'Prepare development database']
custom:
  shell:
    workdir: '/workspace/store'
---

# CRUD Operations in Rails

**CRUD** stands for Create, Read, Update, and Delete - the four basic operations you can perform on data. Rails makes CRUD operations simple and intuitive.

## The Seven RESTful Actions

Rails controllers typically include these seven standard actions:

### Reading Data
- **`index`** - List all products
- **`show`** - Display a single product

### Creating Data
- **`new`** - Show form to create a product
- **`create`** - Process form submission and save product

### Updating Data
- **`edit`** - Show form to edit a product
- **`update`** - Process form submission and update product

### Deleting Data
- **`destroy`** - Delete a product

## Try the CRUD Operations

1. **View all products** - The home page shows the `index` action
2. **Create a new product** - Click "New Product"
3. **View a product** - Click on any product name
4. **Edit a product** - Click "Edit" on any product
5. **Delete a product** - Click "Delete" (with confirmation)

## Routes and Actions

Rails automatically creates RESTful routes for your resources:

```ruby
# In config/routes.rb
resources :products
```

This generates these routes:

| HTTP Method | URL | Controller Action | Purpose |
|-------------|-----|-------------------|---------|
| GET | `/products` | `index` | List all products |
| GET | `/products/new` | `new` | Show new product form |
| POST | `/products` | `create` | Create a product |
| GET | `/products/1` | `show` | Show product #1 |
| GET | `/products/1/edit` | `edit` | Show edit form for product #1 |
| PATCH/PUT | `/products/1` | `update` | Update product #1 |
| DELETE | `/products/1` | `destroy` | Delete product #1 |

## Strong Parameters

Notice how the controller uses **strong parameters** for security:

```ruby
def product_params
  params.expect(product: [ :name, :description, :price ])
end
```

This prevents users from submitting malicious data by only allowing specified parameters.

## Forms and Validations

Rails forms automatically:
- Handle CSRF protection
- Display validation errors
- Maintain form state on errors

Try creating a product with invalid data to see validation in action!

:::tip
Rails follows RESTful conventions, making your applications predictable and maintainable. The seven standard actions cover most use cases for managing resources.
:::

## Experiment

Try modifying the controller:
1. Add a search feature to the `index` action
2. Add custom validations to the Product model
3. Customize the success messages after create/update/delete

CRUD operations are the foundation of most web applications!
