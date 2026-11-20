select
  user_id,
  comment_thread_id,
  count(*) as count
from
  thread_followers
group by
  user_id,
  comment_thread_id
having
  count > 1;
