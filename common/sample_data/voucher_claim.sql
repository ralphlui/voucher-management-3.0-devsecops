INSERT INTO `core`.`voucher`
(
    `voucher_id`,
    `claim_time`,
    `claimed_by`,
    `consumed_time`,
    `voucher_status`,
    `campaign_id`
)
VALUES
(
    '8b18a4a1-df24-4a5f-b0d2-1c464b73449d', 
    CURRENT_TIMESTAMP, 
    'b7bb891e-a365-42ee-8d2e-5e23c8fdbee9',
    '2025-04-25 10:00:00',
    'CLAIMED',
    'd22a54d0-c8bb-4ed5-9dbf-5f705c7b7c0b'
),
(
    '9d1a5c4a-35f2-4e2c-b6a5-0f1e682e6a42',
    CURRENT_TIMESTAMP,
    'b7bb891e-a365-42ee-8d2e-5e23c8fdbee9',
    '2025-04-25 12:00:00',
    'CLAIMED',
    'd22a54d0-c8bb-4ed5-9dbf-5f705c7b7c0b'
),
(
    'ec1b9ab5-2381-4b22-9b4b-92f01934c29c',
    CURRENT_TIMESTAMP,
    'b7bb891e-a365-42ee-8d2e-5e23c8fdbee9',
    '2025-04-25 14:00:00',
    'CLAIMED',
    'b134abe7-505d-4939-b564-cd67231e9b67'
),
(
    'c2a7f67a-b337-4cbb-9b93-3d1625171744',
    CURRENT_TIMESTAMP,
    'b7bb891e-a365-42ee-8d2e-5e23c8fdbee9',
    '2025-04-25 16:00:00',
    'CLAIMED',
    'b134abe7-505d-4939-b564-cd67231e9b67'
),
(
    'fc081232-0e1f-4091-9a42-e2b7d89b2b18',
    CURRENT_TIMESTAMP,
    'b7bb891e-a365-42ee-8d2e-5e23c8fdbee9',
    '2025-04-25 18:00:00',
    'CLAIMED',
    'a4b1e4b8-8f47-48ab-8690-cdb0a8a77f27'
);
