update posts tl
inner join (
    select px.id, count(pr.id) as answer_count
    from posts px
    left join posts pr on px.id = pr.parent_id
    where px.post_type_id = 1
      and pr.parent_id is not null
      and pr.deleted = false
    group by px.id
) q on q.id = tl.id
set tl.answer_count = q.answer_count;