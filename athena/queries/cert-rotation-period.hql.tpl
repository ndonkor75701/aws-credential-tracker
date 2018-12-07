SELECT "arn", "user", date_diff('day', from_iso8601_timestamp("cert_1_last_rotated"), current_timestamp) AS "days_since_last_rotation"
FROM "${database-name}"."${table-name}"
WHERE "cert_1_last_rotated" <> 'N/A'
        AND date_diff('day', from_iso8601_timestamp("cert_1_last_rotated"), current_timestamp) > {0}
        AND "user" <> '<root_account>'
        AND "cert_1_active" = true
        AND "year" = {1}
        AND "month" = {2}
        AND "day" = {3}
        AND "time" = {4}
UNION ALL
SELECT "arn", "user", date_diff('day', from_iso8601_timestamp("cert_2_last_rotated"), current_timestamp) AS "days_since_last_rotation"
FROM "${database-name}"."${table-name}"
WHERE "cert_2_last_rotated" <> 'N/A'
        AND date_diff('day', from_iso8601_timestamp("cert_2_last_rotated"), current_timestamp) > {0}
        AND "user" <> '<root_account>'
        AND "cert_2_active" = true
        AND "year" = {1}
        AND "month" = {2}
        AND "day" = {3}
        AND "time" = {4}
