SELECT "arn", "user", date_diff('day', from_iso8601_timestamp("access_key_1_last_used_date"), current_timestamp) AS "days_since_last_usage"
FROM "${database-name}"."${table-name}"
WHERE "access_key_1_last_used_date" <> 'N/A'
        AND date_diff('day', from_iso8601_timestamp("access_key_1_last_used_date"), current_timestamp) > {0}
        AND "user" <> '<root_account>'
        AND "access_key_1_active" = true
        AND "year" = {1}
        AND "month" = {2}
        AND "day" = {3}
        AND "time" = {4}
UNION ALL
SELECT "arn", "user", date_diff('day', from_iso8601_timestamp("access_key_2_last_used_date"), current_timestamp) AS "days_since_last_usage"
FROM "${database-name}"."${table-name}"
WHERE "access_key_2_last_used_date" <> 'N/A'
        AND date_diff('day', from_iso8601_timestamp("access_key_2_last_used_date"), current_timestamp) > {0}
        AND "user" <> '<root_account>'
        AND "access_key_2_active" = true
        AND "year" = {1}
        AND "month" = {2}
        AND "day" = {3}
        AND "time" = {4}
