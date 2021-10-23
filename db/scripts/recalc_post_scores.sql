update posts pu
inner join (
    select pq.id,
           count(distinct if(v.vote_type = 1, v.id, null)) as uvc,
           count(distinct if(v.vote_type = -1, v.id, null)) as dvc
    from posts pq
    left join votes v on pq.id = v.post_id
    group by pq.id
) ps on pu.id = ps.id
set pu.upvote_count = ps.uvc,
    pu.downvote_count = ps.dvc,
    pu.score = (ps.uvc + 2) / (ps.uvc + ps.dvc + 4);