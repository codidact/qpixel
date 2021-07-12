SET @cid = 3;

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
        WHERE v.community_id = @cid
          AND p.deleted = 0
    ) vq ON vq.community_id = cu.community_id AND cu.user_id = vq.recv_user_id
    WHERE cu.community_id = @cid
    GROUP BY cu.id
) q ) x ON x.id = community_users.id
SET community_users.reputation = IFNULL(x.total_rep, 1)
WHERE community_users.community_id = @cid
  AND (community_users.reputation > 1 OR community_users.reputation IS NULL);