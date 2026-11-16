-- 第 4 章：block 与 check 的多对多关系。
create table blocks(
    block_id integer primary key,
    name     text not null unique,
    owner    text not null,
    revision text
);

insert into blocks(name, owner, revision) values
    ('INV_X1',      'wang',  'r3'),
    ('NAND2_X1',    'li',    'r2'),
    ('BUF_X2',      'wang',  'r1'),
    ('LEVEL_SHIFT', 'chen',  'r5');

create table checks(
    check_id integer primary key,
    name     text not null unique,
    category text not null
);

insert into checks(name, category) values
    ('DRC', 'physical'),
    ('LVS', 'physical'),
    ('ANT', 'reliability'),
    ('EM',  'reliability');

create table block_checks(
    block_id  integer not null references blocks(block_id),
    check_id  integer not null references checks(check_id),
    status    text not null check(status in ('signed', 'open', 'waived')),
    signed_at text,
    primary key(block_id, check_id)
);

insert into block_checks(block_id, check_id, status, signed_at) values
    (1, 1, 'signed', '2026-11-10T18:00:00'),
    (1, 2, 'signed', '2026-11-10T18:05:00'),
    (1, 3, 'open',   null),
    (1, 4, 'waived', '2026-11-09T10:00:00'),
    (2, 1, 'signed', '2026-11-11T09:00:00'),
    (2, 2, 'open',   null),
    (2, 4, 'open',   null),
    (3, 1, 'signed', '2026-11-11T11:00:00'),
    (3, 2, 'signed', '2026-11-11T11:10:00'),
    (4, 1, 'open',   null);
