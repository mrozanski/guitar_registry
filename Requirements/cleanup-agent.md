# Scheduled process to clean up inconsistencies and missing database

## Summary
When new data is added to the database, there can be inconsistencies and missing data.
The goal of this task is to cover two specific cases and define the approach for doing this in a way that will be reused for future use cases.

## Case: Individual guitar relation to model and manufacturer

New individual guitars are added with fallback manufacturer and model names and no relation is estabnlished to the model or manufacturer tables.

To solve this, we need to create the necessary logic that can be used either by a manual run or by cron job in order to:

1. Find individual guitars in the DB that have no relation to the model or manufacturer tables.
2. For each individual guitar, find the most similar model and manufacturer in the DB.
3. Create a relation between the individual guitar and the model and manufacturer.

## Case no serial number

If a new individual guitar is added with no serial number, we need to attempt to find it  a new serial number for it.
This process involves agentic processing, web search, image recognition and agent orchestration.