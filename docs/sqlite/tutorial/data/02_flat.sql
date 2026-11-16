-- 第 2 章：先把 Excel 里的一张扁平表原样搬进数据库。
create table violations(
    violation_id integer primary key,
    run_label    text not null,
    rule_name    text not null,
    layer        text not null,
    cell         text not null,
    view         text not null,
    x            real not null,
    y            real not null,
    status       text not null default 'open',
    owner        text,
    note         text
);

insert into violations(
    violation_id, run_label, rule_name, layer, cell, view,
    x, y, status, owner, note
) values
    (1,  '2026-11-10-nightly', 'M1.S.1', 'M1', 'INV_X1',    'layout', 12.4,  8.2, 'open',   null,  null),
    (2,  '2026-11-10-nightly', 'M1.S.1', 'M1', 'INV_X1',    'layout', 12.4,  8.4, 'open',   null,  null),
    (3,  '2026-11-10-nightly', 'M1.S.1', 'M1', 'NAND2_X1',  'layout', 30.1, 14.0, 'waived', 'li',  'foundry approved spacing exception'),
    (4,  '2026-11-10-nightly', 'M1.W.1', 'M1', 'INV_X1',    'layout', 13.0,  9.0, 'open',   'wang', null),
    (5,  '2026-11-10-nightly', 'V1.E.1', 'V1', 'INV_X1',    'layout', 12.5,  8.3, 'fixed',  'wang', null),
    (6,  '2026-11-10-nightly', 'V1.E.1', 'V1', 'NAND2_X1',  'layout', 31.0, 15.0, 'open',   null,  null),
    (7,  '2026-11-10-nightly', 'PO.R.1', 'PO', 'INV_X1',    'layout',  8.0,  6.0, 'open',   'li',  'resistor value under review'),
    (8,  '2026-11-11-nightly', 'M1.S.1', 'M1', 'INV_X1',    'layout', 12.4,  8.2, 'fixed',  'li',  null),
    (9,  '2026-11-11-nightly', 'M1.S.1', 'M1', 'INV_X1',    'layout', 12.4,  8.4, 'fixed',  'li',  null),
    (10, '2026-11-11-nightly', 'M1.S.1', 'M1', 'NAND2_X1',  'layout', 30.1, 14.0, 'open',   'wang', null),
    (11, '2026-11-11-nightly', 'M1.W.1', 'M1', 'NAND2_X1',  'layout', 31.5, 15.2, 'open',   null,  null),
    (12, '2026-11-11-nightly', 'V1.E.1', 'V1', 'INV_X1',    'layout', 12.5,  8.3, 'open',   'wang', null);
