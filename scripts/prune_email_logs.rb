EmailLog.where('created_at < DATE_SUB(CURRENT_TIMESTAMP, INTERVAL 1 MONTH)').destroy_all
