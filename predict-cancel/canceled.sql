select
        "userId"
, case when "playerPosition" > 300 THEN 'READ' ELSE 'SKIP' END as rs
, case when M1.title is not null then 'SERIE' else 'FILM' end as type
, case when M1.title is not null then M1._id else M2._id end as id
, case when M1.title is not null then "Episodes"."episodeNumber" else 0 end as ep
, case when M1.title is not null then 'Serie: ' || M1.title || ' S' || "Seasons"."seasonNumber" || 'E' || "Episodes"."episodeNumber" else 'Film: ' || M2.title end as title
from "UsersVideos"
INNER JOIN (
        select
                BU.user_reference_uuid,
                CASE WHEN BS.sub_expires_date is null AND BS.sub_canceled_date is null THEN 'ACTIVE'
                     WHEN BS.sub_expires_date is null AND BS.sub_canceled_date is not null THEN 'FUTUR CANCELED'
                     WHEN BS.sub_expires_date is not null AND BS.sub_canceled_date is not null THEN
                        CASE WHEN BS.sub_expires_date = BS.sub_canceled_date THEN 'ERROR'
                             WHEN BS.sub_canceled_date IS NULL AND BPR._id <> 14 THEN 'EXPIRED'
                             WHEN BS.sub_expires_date <> BS.sub_canceled_date OR (BPR._id = 14 AND BS.sub_canceled_date IS NULL) THEN 'CANCELED'
                             ELSE 'unknown (2)'
                             END
                     ELSE 'unknown (1)'
                     END as "status",
                date_part('day', BS.sub_expires_date - BS.sub_activated_date) as "aboDuration",
                date_part('day', BS.sub_canceled_date - BS.sub_activated_date) as "aboDaysBeforeCancel",
                BS.sub_activated_date,
                BS.sub_canceled_date
        FROM "Vue_billing_subscriptions" BS
        INNER JOIN "Vue_billing_users" BU on (BS.userid = BU._id)
        INNER JOIN "Vue_billing_providers" BPR ON (BS.providerid = BPR._id)
        INNER JOIN "Vue_billing_plans" BP on (BS.planid = BP._id)
        INNER JOIN "Vue_billing_internal_plans" BIP on (BIP._id = BP.internal_plan_id)
        INNER JOIN (
                SELECT DISTINCT ON (subid) subid, _id, amount_in_cents
                FROM "Vue_billing_transactions"
                WHERE transaction_type = 'purchase' AND transaction_status = 'success'
                ORDER BY subid, _id ASC
        ) as BT ON BT.subid = BS._id
        WHERE BS.deleted = false AND BU.deleted = false
        -- on ne veut que les CANCELED ou FUTUR CANCELED
        AND
        (  -- futur canceled
            (BS.sub_expires_date is null AND BS.sub_canceled_date is not null)
           -- actual canceled
          OR (
            BS.sub_expires_date is not null AND BS.sub_canceled_date is not null AND (BS.sub_expires_date <> BS.sub_canceled_date OR (BPR._id = 14 AND BS.sub_canceled_date IS NULL))
          )
        )
        -- AND BIP._id IN (64,65,66,67)
        AND BS.sub_activated_date > '2016-10-01 00:00:00'
        ORDER BY "status", date (BS.sub_activated_date AT TIME ZONE 'Europe/Paris') DESC
) as billing ON billing.user_reference_uuid::integer = "UsersVideos"."userId" AND billing.sub_activated_date <= "UsersVideos"."dateStartRead"
 AND (billing.sub_canceled_date is null OR billing.sub_canceled_date >= "UsersVideos"."dateStartRead")
left join "Episodes" on "Episodes"."videoId" = "UsersVideos"."videoId"
left join "Seasons" on "Seasons"."_id" = "Episodes"."seasonId"
left join "Movies" M1 on M1."_id" = "Seasons"."movieId"
left join "Movies" M2 on M2."videoId" = "UsersVideos"."videoId"
WHERE
        (billing.status = 'ACTIVE' OR billing.status='CANCELED' OR billing.status='FUTUR CANCELED')
ORDER BY "userId", "dateStartRead"
