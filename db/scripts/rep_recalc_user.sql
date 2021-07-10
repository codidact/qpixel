SET @uid = 8045;

UPDATE community_users
INNER JOIN ( SELECT * FROM (
    SELECT cu.id, SUM(vq.rep_change) + 1 AS total_rep
    FROM community_users cu
    LEFT JOIN (
        SELECT v.id, v.community_id, v.recv_user_id,
               CASE
                 WHEN v.vote_type = -1 THEN pt.downvote_rep
                 WHEN v.vote_type = 1 THEN pt.upvote_rep
                 ELSE 0
               END AS rep_change
        FROM votes v
        INNER JOIN posts p ON v.post_id = p.id
        INNER JOIN post_types pt ON p.post_type_id = pt.id
        WHERE p.deleted = 0
    ) vq ON cu.user_id = vq.recv_user_id
    WHERE cu.user_id = @uid
      AND vq.community_id = cu.community_id
    GROUP BY cu.id
) q ) x ON x.id = community_users.id
SET community_users.reputation = IFNULL(x.total_rep, 1)
WHERE (community_users.reputation > 1 OR community_users.reputation IS NULL);