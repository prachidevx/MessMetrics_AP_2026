-- SECTION 1: DISH MANAGEMENT (backend/src/routes/dishRoutes.js)

-- 1.1 List All Dishes (with optional category filter)
-- READ
SELECT
    d.id,
    d.name,
    d.category
FROM "Dish" d
WHERE ($1::text IS NULL OR d.category = $1)
ORDER BY d.id ASC;

-- 1.2 Get Single Dish by ID with Associated Meal History
-- READ
SELECT
    d.id AS dish_id,
    d.name AS dish_name,
    d.category AS dish_category,
    md.id AS meal_dish_id,
    m.id AS meal_id,
    m.date AS meal_date,
    m.mealType AS meal_type,
    m.attendance AS meal_attendance,
    m.waste AS meal_waste
FROM "Dish" d
LEFT JOIN "MealDish" md ON d.id = md."dishId"
LEFT JOIN "Meal" m ON md."mealId" = m.id
WHERE d.id = $1;

-- 1.3 Create a New Dish
-- WRITE
INSERT INTO "Dish" (name, category)
VALUES ($1, $2)
RETURNING id, name, category;

-- 1.4 Update Dish Details
-- WRITE
UPDATE "Dish"
SET
    name = COALESCE($2, name),
    category = COALESCE($3, category)
WHERE id = $1
RETURNING id, name, category;

-- 1.5 Delete a Dish
-- WRITE
DELETE FROM "Dish"
WHERE id = $1;

-- SECTION 2: MEAL LOGGING & MANAGEMENT (backend/src/routes/mealRoutes.js)

-- 2.1 List All Meals with Dishes (with filters for mealType, date range, and limit)
-- READ
SELECT
    m.id AS meal_id,
    m.date AS meal_date,
    m.mealType AS meal_type,
    m.attendance AS meal_attendance,
    m.waste AS meal_waste,
    md.id AS meal_dish_id,
    d.id AS dish_id,
    d.name AS dish_name,
    d.category AS dish_category
FROM "Meal" m
LEFT JOIN "MealDish" md ON m.id = md."mealId"
LEFT JOIN "Dish" d ON md."dishId" = d.id
WHERE ($1::"MealType" IS NULL OR m.mealType = $1)
  AND ($2::date IS NULL OR m.date >= $2)
  AND ($3::date IS NULL OR m.date < $3)
ORDER BY m.date DESC, m.id DESC
LIMIT $4;

-- 2.2 Get Single Meal by ID with Associated Dishes
-- READ
SELECT
    m.id AS meal_id,
    m.date AS meal_date,
    m.mealType AS meal_type,
    m.attendance AS meal_attendance,
    m.waste AS meal_waste,
    md.id AS meal_dish_id,
    d.id AS dish_id,
    d.name AS dish_name,
    d.category AS dish_category
FROM "Meal" m
LEFT JOIN "MealDish" md ON m.id = md."mealId"
LEFT JOIN "Dish" d ON md."dishId" = d.id
WHERE m.id = $1;

-- 2.3 Create a New Meal Session
-- WRITE
INSERT INTO "Meal" (date, mealType, attendance, waste)
VALUES (COALESCE($1, CURRENT_DATE), $2::"MealType", COALESCE($3, 0), 0.0)
RETURNING id, date, mealType, attendance, waste;

-- 2.4 Update an Existing Meal Session
-- WRITE
UPDATE "Meal"
SET
    date = COALESCE($2, date),
    mealType = COALESCE($3::"MealType", mealType),
    attendance = COALESCE($4, attendance),
    waste = COALESCE($5, waste)
WHERE id = $1
RETURNING id, date, mealType, attendance, waste;

-- 2.5 Delete a Meal Session
-- WRITE
DELETE FROM "Meal"
WHERE id = $1;

-- SECTION 3: MEAL-DISH ASSOCIATIONS (backend/src/routes/mealRoutes.js)

-- 3.1 List All Meal-Dish Records with Joined Meal and Dish Details
-- READ
SELECT
    md.id AS meal_dish_id,
    md."mealId",
    md."dishId",
    d.name AS dish_name,
    d.category AS dish_category,
    m.date AS meal_date,
    m.mealType AS meal_type,
    m.attendance AS meal_attendance,
    m.waste AS meal_waste
FROM "MealDish" md
INNER JOIN "Dish" d ON md."dishId" = d.id
INNER JOIN "Meal" m ON md."mealId" = m.id
WHERE ($1::int IS NULL OR md."mealId" = $1)
  AND ($2::int IS NULL OR md."dishId" = $2)
ORDER BY md.id DESC;

-- 3.2 Get Single Meal-Dish Record by ID
-- READ
SELECT
    md.id AS meal_dish_id,
    md."mealId",
    md."dishId",
    d.name AS dish_name,
    d.category AS dish_category,
    m.date AS meal_date,
    m.mealType AS meal_type,
    m.attendance AS meal_attendance,
    m.waste AS meal_waste
FROM "MealDish" md
INNER JOIN "Dish" d ON md."dishId" = d.id
INNER JOIN "Meal" m ON md."mealId" = m.id
WHERE md.id = $1;

-- 3.3 Link a Dish to a Meal Session
-- WRITE
INSERT INTO "MealDish" ("mealId", "dishId")
VALUES ($1, $2)
RETURNING id, "mealId", "dishId";

-- 3.4 Verify Existence of a Meal-Dish Record Before Modification
-- READ
SELECT
    id,
    "mealId",
    "dishId"
FROM "MealDish"
WHERE id = $1;

-- 3.5 Update a Meal-Dish Association Record
-- WRITE
UPDATE "MealDish"
SET
    "mealId" = COALESCE($2, "mealId"),
    "dishId" = COALESCE($3, "dishId")
WHERE id = $1
RETURNING id, "mealId", "dishId";

-- 3.6 Remove a Dish from a Meal Session
-- WRITE
DELETE FROM "MealDish"
WHERE id = $1;

-- SECTION 4: WEEKLY MENU SYNC (backend/src/routes/weeklyMenuRoutes.js)

-- 4.1 Upsert Dish from Weekly Menu Sync
-- WRITE
INSERT INTO "Dish" (name, category)
VALUES ($1, $2)
ON CONFLICT (name) DO UPDATE
SET category = EXCLUDED.category
RETURNING id, name, category;

-- SECTION 5: ANALYTICS & REPORTING (backend/src/routes/analyticsRoutes.js)

-- 5.1 Analytics Summary: Fetch Meals with Dishes (Application Layer Aggregation)
-- READ
SELECT
    m.id AS meal_id,
    m.date AS meal_date,
    m.mealType AS meal_type,
    m.attendance AS meal_attendance,
    m.waste AS meal_waste,
    md.id AS meal_dish_id,
    md."dishId"
FROM "Meal" m
LEFT JOIN "MealDish" md ON m.id = md."mealId"
WHERE ($1::date IS NULL OR m.date >= $1)
  AND ($2::date IS NULL OR m.date < $2);

-- 5.1b Analytics Summary: Equivalent Direct PostgreSQL Aggregation
-- READ
SELECT
    COUNT(DISTINCT m.id) AS total_meals,
    COALESCE(SUM(m.attendance), 0) AS total_attendance,
    COALESCE(SUM(m.waste), 0.0) AS total_waste
FROM "Meal" m
WHERE ($1::date IS NULL OR m.date >= $1)
  AND ($2::date IS NULL OR m.date < $2);

-- 5.2 Analytics by Meal Type: Fetch Meals with Dishes (Application Layer Grouping)
-- READ
SELECT
    m.id AS meal_id,
    m.date AS meal_date,
    m.mealType AS meal_type,
    m.attendance AS meal_attendance,
    m.waste AS meal_waste,
    md.id AS meal_dish_id,
    md."dishId"
FROM "Meal" m
LEFT JOIN "MealDish" md ON m.id = md."mealId"
WHERE ($1::date IS NULL OR m.date >= $1)
  AND ($2::date IS NULL OR m.date < $2)
ORDER BY m.mealType;

-- 5.2b Analytics by Meal Type: Equivalent Direct PostgreSQL GROUP BY Aggregation
-- READ
SELECT
    m.mealType AS meal_type,
    COUNT(DISTINCT m.id) AS total_meals,
    COALESCE(SUM(m.attendance), 0) AS total_attendance,
    COALESCE(SUM(m.waste), 0.0) AS total_waste
FROM "Meal" m
WHERE ($1::date IS NULL OR m.date >= $1)
  AND ($2::date IS NULL OR m.date < $2)
GROUP BY m.mealType
ORDER BY m.mealType;

-- 5.3 Daily Analytics: Fetch Chronological Meals with Dishes (Application Layer Grouping)
-- READ
SELECT
    m.id AS meal_id,
    m.date AS meal_date,
    m.mealType AS meal_type,
    m.attendance AS meal_attendance,
    m.waste AS meal_waste,
    md.id AS meal_dish_id,
    md."dishId"
FROM "Meal" m
LEFT JOIN "MealDish" md ON m.id = md."mealId"
WHERE ($1::date IS NULL OR m.date >= $1)
  AND ($2::date IS NULL OR m.date < $2)
ORDER BY m.date ASC;

-- 5.3b Daily Analytics: Equivalent Direct PostgreSQL Daily Aggregation
-- READ
SELECT
    m.date AS meal_date,
    COUNT(DISTINCT m.id) AS total_meals,
    COALESCE(SUM(m.attendance), 0) AS total_attendance,
    COALESCE(SUM(m.waste), 0.0) AS total_waste
FROM "Meal" m
WHERE ($1::date IS NULL OR m.date >= $1)
  AND ($2::date IS NULL OR m.date < $2)
GROUP BY m.date
ORDER BY m.date ASC;

-- SECTION 6: DATABASE SEEDING & ADMINISTRATIVE OPERATIONS

-- 6.1 Purge All Records Before Reseeding
-- WRITE
DELETE FROM "MealDish";
DELETE FROM "Dish";
DELETE FROM "Meal";

-- 6.2 Check Dish Existence by Unique Name (Master Dishes Seeding)
-- READ
SELECT
    id,
    name,
    category
FROM "Dish"
WHERE name = $1;

-- 6.3 Count Total Dishes in Catalog
-- READ
SELECT COUNT(*) AS total_dishes
FROM "Dish";
