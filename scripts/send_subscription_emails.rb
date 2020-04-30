# SQL for selecting subscriptions due for sending.
# DO NOT USE USER INPUT IN THIS CLAUSE, IT GETS PASSED DIRECTLY TO Arel.sql
select_clause = 'last_sent_at IS NULL OR DATE_ADD(last_sent_at, INTERVAL frequency DAY) <= CURRENT_TIMESTAMP'

Subscription.unscoped.where(Arel.sql(select_clause)).includes(:community).each do |sub|
  SubscriptionMailer.with(subscription: sub).subscription.deliver_now
end