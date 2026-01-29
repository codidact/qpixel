select
  user_id,
  post_id,
  count(*) as count
from
  new_thread_followers
group by
  user_id,
  post_id
having
  count > 1;
