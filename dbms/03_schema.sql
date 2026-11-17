DROP TABLE IF EXISTS "MealDish" CASCADE;
DROP TABLE IF EXISTS "Meal" CASCADE;
DROP TABLE IF EXISTS "Dish" CASCADE;
DROP TYPE IF EXISTS "MealType" CASCADE;

CREATE TYPE "MealType" AS ENUM ('Breakfast', 'Lunch', 'Snacks', 'Dinner');

CREATE TABLE "Dish" (
    "id" SERIAL PRIMARY KEY,
    "name" TEXT NOT NULL UNIQUE,
    "category" TEXT NOT NULL
);

CREATE TABLE "Meal" (
    "id" SERIAL PRIMARY KEY,
    "date" DATE NOT NULL DEFAULT CURRENT_DATE,
    "mealType" "MealType" NOT NULL,
    "attendance" INTEGER NOT NULL DEFAULT 0,
    CONSTRAINT "Meal_date_mealType_key" UNIQUE ("date", "mealType"),
    CONSTRAINT "chk_attendance_non_negative" CHECK ("attendance" >= 0)
);

CREATE TABLE "MealDish" (
    "id" SERIAL PRIMARY KEY,
    "mealId" INTEGER NOT NULL REFERENCES "Meal"("id") ON DELETE CASCADE,
    "dishId" INTEGER NOT NULL REFERENCES "Dish"("id") ON DELETE CASCADE,
    "quantityPrepared" DOUBLE PRECISION NOT NULL,
    "quantityWasted" DOUBLE PRECISION NOT NULL,
    CONSTRAINT "MealDish_mealId_dishId_key" UNIQUE ("mealId", "dishId"),
    CONSTRAINT "chk_quantity_prepared_non_negative" CHECK ("quantityPrepared" >= 0),
    CONSTRAINT "chk_quantity_wasted_non_negative" CHECK ("quantityWasted" >= 0),
    CONSTRAINT "chk_wasted_lte_prepared" CHECK ("quantityWasted" <= "quantityPrepared")
);