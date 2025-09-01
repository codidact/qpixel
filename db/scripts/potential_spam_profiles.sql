select u.id
from users u
inner join community_users cu on u.id = cu.user_id
inner join communities c on cu.community_id = c.id
left join posts p on p.user_id = u.id
left join comments cm on cm.user_id = u.id
left join votes v on v.user_id = u.id
left join flags f on f.user_id = u.id
where u.profile_markdown is not null
  and u.profile like '%href="%'
  and u.created_at >= date_sub(current_timestamp, interval 5048 hour)
  and u.deleted = false
  and u.email not like '%localhost'
group by u.id
having max(cu.reputation) = 1
   and count(distinct p.id) = 0
   and count(distinct cm.id) = 0
   and count(distinct v.id) = 0
   and count(distinct f.id) = 0
order by u.id
