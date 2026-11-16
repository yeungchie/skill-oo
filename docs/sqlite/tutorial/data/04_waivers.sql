-- 第 6 章：豁免记录单独成表，一条违例最多有一条有效豁免。
create table waivers(
    waiver_id    integer primary key,
    violation_id integer not null unique
                   references violations(violation_id) on delete cascade,
    reason       text not null,
    owner        text not null,
    expires_on   text,
    created_at   text not null
);

insert into waivers(violation_id, reason, owner, expires_on, created_at) values
    (3, 'foundry approved spacing exception', 'li', '2026-12-31', '2026-11-10T22:10:00'),
    (7, 'resistor value under review',        'li', '2026-10-31', '2026-10-20T09:30:00');
