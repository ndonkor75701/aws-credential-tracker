SELECT "arn", "user", date_diff('day', from_iso8601_timestamp("password_last_used"), current_timestamp) AS "days_since_last_usage"
FROM "${database-name}"."${table-name}"
WHERE "password_last_used" <> 'N/A'
        OR "password_last_used" <> 'no_information'
        AND date_diff('day', from_iso8601_timestamp("password_last_used"), current_timestamp) > {0}
        AND "user" <> '<root_account>'
        AND "year" = {1}
        AND "month" = {2}
        AND "day" = {3}
        AND "time" = {4}
