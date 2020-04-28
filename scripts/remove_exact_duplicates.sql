UPDATE posts
SET deleted = TRUE,
    deleted_at = CURRENT_TIMESTAMP,
    deleted_by_id = -1
WHERE id IN (
    SELECT * FROM (
        SELECT IF(b.answer_count = 0, b.id, a.id) AS id
        FROM posts a
        JOIN posts b ON a.id < b.id AND a.user_id = b.user_id
            AND a.title IS NOT NULL AND b.title IS NOT NULL
            AND a.title = b.title
            AND a.deleted_at IS NULL AND b.deleted_at IS NULL
            AND a.community_id = b.community_id
        LEFT JOIN posts c ON c.parent_id = b.id
        WHERE c.id IS NULL
    ) q
);