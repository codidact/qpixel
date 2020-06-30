WITH RECURSIVE CTE (id, group_id) AS (
    SELECT id, parent_id
    FROM tags
    WHERE parent_id = $ParentId
    UNION ALL
    SELECT t.id, t.parent_id
    FROM tags t
    INNER JOIN CTE ON t.parent_id = CTE.id
)
SELECT * FROM CTE;