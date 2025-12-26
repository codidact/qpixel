select
  user_id,
  comment_thread_id,
  count(*) as count
from
  thread_followers
where
  post_id is null
group by
  user_id,
  comment_thread_id
having
  count > 1;
