update comment_threads ct
inner join (
    select ctq.id,
    count(cq.id) as cc
    from comment_threads ctq
    inner join comments cq on ctq.id = cq.comment_thread_id
    where cq.deleted = false
    group by ctq.id
) x on ct.id = x.id
set ct.reply_count = x.cc;