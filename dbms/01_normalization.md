# MessMetrics: Normalization

## 1. Tables in Scope

Tables currently in our database schema:

| Table | Columns | Primary Key | Candidate Keys | Purpose |
| --- | --- | --- | --- | --- |
| `Dish` | `id`, `name`, `category` | `id` | `id`, `name` | Master list of all dishes and items served. |
| `Meal` | `id`, `date`, `mealType`, `attendance` | `id` | `id`, `(date, mealType)` | Tracks each meal service and the attendance count. |
| `MealDish` | `id`, `mealId`, `dishId`, `quantityPrepared`, `quantityWasted` | `id` | `id`, `(mealId, dishId)` | Junction table logging food prepared vs wasted per dish. |

---

## 2. Unnormalized Form (UNF)

Without normalization, all meal and dish data would be lumped into a single record with repeating lists of dishes:

`MealRecord(meal_id, date, meal_type, attendance, {dish_id, dish_name, category, quantity_prepared, quantity_wasted}...)`

The `{ ... }` means one meal has a repeating group of dishes. Storing it like this causes repeated data and update headaches.

---

## 3. Functional Dependencies

Based on the attributes and candidate keys in our schema:

* **`Meal`**:
  * `id -> date, mealType, attendance`
  * `(date, mealType) -> id, attendance` *(a specific meal like Lunch only happens once per date)*
* **`Dish`**:
  * `id -> name, category`
  * `name -> id, category` *(dish name is unique)*
* **`MealDish`**:
  * `id -> mealId, dishId, quantityPrepared, quantityWasted`
  * `(mealId, dishId) -> id, quantityPrepared, quantityWasted` *(each dish appears at most once in a meal)*

---

## 4. First Normal Form (1NF)

**Rule:** Remove repeating groups so every attribute is atomic (single-valued).

The unnormalized `MealRecord` has repeating dish entries inside each meal. We reach 1NF by breaking it into three separate tables with single values in every column:

* `Dish(id, name, category)`
* `Meal(id, date, mealType, attendance)`
* `MealDish(id, mealId, dishId, quantityPrepared, quantityWasted)`

For example, if lunch serves Dal and Rice, we store one row in `Meal` and two rows in `MealDish`, instead of stuffing multiple dishes into one row.

---

## 5. Second Normal Form (2NF)

**Rule:** Be in 1NF, and ensure non-key attributes depend on the full candidate key (no partial dependencies).

* In **`Meal`**: For the composite key `(date, mealType)`, attendance describes that specific meal on that date. Attendance doesn't depend on just `date` (there are multiple meals that day) or just `mealType` (attendance varies daily). It depends on both together.
* In **`Dish`**: Keys are single attributes (`id` and `name`), so partial dependencies cannot exist.
* In **`MealDish`**: The candidate key is `(mealId, dishId)`. `quantityPrepared` and `quantityWasted` depend on both the meal and the dish together—you can't know the wasted amount with just `mealId` or just `dishId`. Dish details (`name`, `category`) stay in `Dish`, so they don't depend partially on `dishId` here.

So there are no partial dependencies, and 2NF is satisfied.

---

## 6. Third Normal Form (3NF)

**Rule:** Be in 2NF, and ensure non-key attributes don't depend on other non-key attributes (no transitive dependencies).

* In **`Meal`**: `date`, `mealType`, and `attendance` depend directly on the key. None of them determine each other.
* In **`Dish`**: `name` and `category` depend directly on the key. `category` does not determine `name` because multiple dishes share the same category (like "Curry").
* In **`MealDish`**: `quantityPrepared` and `quantityWasted` depend directly on the key. Prepared quantity doesn't determine waste because waste changes each time.
* `MealDish` only stores foreign keys (`mealId`, `dishId`) instead of repeating dish names or dates.

This avoids update issues—for example, renaming a dish only takes one update in `Dish` instead of changing every meal it was served in.

---

## 7. Boyce-Codd Normal Form (BCNF)

**Rule:** For every functional dependency $X \rightarrow Y$, $X$ must be a candidate key (superkey).

* In **`Meal`**: Both `id` and `(date, mealType)` are candidate keys.
* In **`Dish`**: Both `id` and `name` are candidate keys.
* In **`MealDish`**: Both `id` and `(mealId, dishId)` are candidate keys.

Since all the left-hand sides in our dependencies are candidate keys, the schema satisfies BCNF.
