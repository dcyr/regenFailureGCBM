CREATE VIEW script_example_view AS
SELECT
    col_A,
    col_B,
    col_C
FROM multi_import;

CREATE VIEW script_example_view_2 AS 
SELECT
    col_C,
    col_A,
    col_B
FROM multi_import;

CREATE VIEW script_example_view_3 AS 
SELECT
    col_B,
    col_C,
    col_A
FROM multi_import;

CREATE TABLE script_example_table (col_A text, col_B text, col_C text);

INSERT INTO script_example_table
SELECT * FROM script_example_view;

INSERT INTO script_example_table
SELECT * FROM script_example_view_2;

INSERT INTO script_example_table
SELECT * FROM script_example_view_3;