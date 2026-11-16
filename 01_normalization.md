# MessMetrics: Normalization

## 1. Scope and evidence

This document covers only the tables currently present in the MessMetrics PostgreSQL database:

| Table | Confirmed columns | Purpose |
| --- | --- | --- |
| `Dish` | `id`, `name` | A dish that can be served, such as a menu item. |
| `Meal` | `id`, `date`, `mealType`, `attendance` | One meal service on a date, with its meal type and recorded attendance. |
| `MealDish` | `id`, `mealId`, `dishId`, `quantityPrepared`, `quantityWasted` | The occurrence of a dish in a meal, including its prepared and wasted quantities. |

The database contains no `Student`, `Admin`, `Hostel`, `Menu`, or `Feedback` table at this point. They are intentionally outside this normalization scope.

The Neon table view shows the IDs as serial values and shows `MealDish` connected to both `Meal` and `Dish`. This document therefore uses the IDs as the intended identifiers. The exact database constraints (primary keys, foreign keys, `NOT NULL`, and unique constraints) should be verified when the PostgreSQL schema is documented in CP2.

## 2. Business relationships

* One `Meal` can contain zero or more `MealDish` records.
* One `Dish` can occur in zero or more `MealDish` records.
* Each `MealDish` record belongs to one meal and one dish.
* Prepared and wasted quantities belong to the specific meal-and-dish occurrence, not to the meal alone or to the dish alone.

Conceptually, a single unstructured meal record could look like this:

`MealRecord(meal_id, date, meal_type, attendance, {dish_id, dish_name, quantity_prepared, quantity_wasted}...)`

The braces mean that one meal can have a repeating list of dishes. That form is useful to illustrate normalization, but it must not be stored as one database row.

## 3. Functional dependencies

Using the intended identifiers, the relevant dependencies are:

* `meal_id -> date, meal_type, attendance`
* `dish_id -> name`
* `meal_dish_id -> meal_id, dish_id, quantity_prepared, quantity_wasted`

At the business level, the measurements are identified by a particular meal and a particular dish. Whether the pair `(meal_id, dish_id)` must be unique has not yet been confirmed by the team, so this document does not claim that constraint exists.

## 4. First Normal Form (1NF)

**Rule:** every field contains one atomic value, and repeating groups are removed.

The unstructured `MealRecord` is not in 1NF because its list of dishes repeats inside a meal. Splitting the repeating dish list into one `MealDish` row per occurrence produces atomic values:

* `Meal(id, date, mealType, attendance)`
* `Dish(id, name)`
* `MealDish(id, mealId, dishId, quantityPrepared, quantityWasted)`

For example, if one lunch serves dal and rice, it is represented by one `Meal` row and two `MealDish` rows, rather than comma-separated dishes or quantity lists in the meal row.

## 5. Second Normal Form (2NF)

**Rule:** be in 1NF, and make every non-key attribute depend on the whole key.

The three current tables meet 2NF:

* In `Meal`, `date`, `mealType`, and `attendance` describe the complete meal identified by `id`.
* In `Dish`, `name` describes the complete dish identified by `id`.
* In `MealDish`, `mealId`, `dishId`, `quantityPrepared`, and `quantityWasted` describe the complete meal-dish occurrence identified by `id`.

There is no partial dependency in the current design because each table uses a single-column identifier. Also, meal-level facts are not repeated for every dish, and dish names are not repeated for every meal-dish record.

## 6. Third Normal Form (3NF)

**Rule:** be in 2NF, and ensure non-key attributes do not depend on other non-key attributes.

The current design meets 3NF for the documented dependencies:

* Meal facts depend directly on `Meal.id`.
* The dish name depends directly on `Dish.id`.
* Preparation and waste figures depend directly on `MealDish.id`.
* `MealDish` stores links to `Meal` and `Dish`; it does not duplicate `date`, `mealType`, `attendance`, or `name`.

This separation prevents update anomalies. For example, renaming a dish requires changing one `Dish` row rather than every meal in which the dish was served.

## 7. BCNF

Based on the functional dependencies listed above and the intended identifiers, the current relations satisfy BCNF. This conclusion assumes that the listed identifiers correctly represent the candidate keys and that no additional functional dependencies have been introduced.

## 8. Integrity rules to confirm before CP2

Normalization describes the table structure; constraints protect its data. The following items are not assumed here and should be agreed by the team before the SQL schema is finalized:

1. `MealDish.mealId` should reference an existing `Meal` row.
2. `MealDish.dishId` should reference an existing `Dish` row.
3. `quantityPrepared` and `quantityWasted` should not be negative.
4. Decide whether one dish may appear more than once in the same meal. If the answer is no, enforce a unique constraint on `(mealId, dishId)`.
5. Decide the unit for the quantity fields (for example, kilograms, litres, or servings) and document it consistently.