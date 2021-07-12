SET @uid = 54114;

UPDATE community_users
INNER JOIN ( SELECT * FROM (
    SELECT cu.id, SUM(vq.rep_change) + 1 AS total_rep
    FROM community_users cu
    LEFT JOIN (
        SELECT v.id, v.community_id, v.recv_user_id,
               CASE
                 WHEN v.vote_type = -1 THEN cpt.downvote_rep
                 WHEN v.vote_type = 1 THEN cpt.upvote_rep
                 ELSE 0
               END AS rep_change
        FROM votes v
        INNER JOIN posts p ON v.post_id = p.id
        INNER JOIN categories_post_types cpt ON cpt.post_type_id = p.post_type_id AND cpt.category_id = p.category_id
        WHERE p.deleted = 0
    ) vq ON cu.user_id = vq.recv_user_id
    WHERE cu.user_id = @uid
      AND vq.community_id = cu.community_id
    GROUP BY cu.id
) q ) x ON x.id = community_users.id
SET community_users.reputation = IFNULL(x.total_rep, 1);