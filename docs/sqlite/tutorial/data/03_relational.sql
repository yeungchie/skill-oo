-- 第 3 章：拆出规则表与运行表，把 violations 改成用主键引用它们。
create table rules(
    rule_id     integer primary key,
    name        text not null unique,
    category    text not null,
    severity    text not null,
    description text
);

insert into rules(rule_id, name, category, severity, description) values
    (1, 'M1.S.1', 'DRC', 'error',   null),
    (2, 'M1.W.1', 'DRC', 'error',   null),
    (3, 'PO.R.1', 'DFM', 'warning', null),
    (4, 'V1.E.1', 'DRC', 'error',   null);

create table runs(
    run_id       integer primary key,
    label        text not null unique,
    started_at   text not null,
    deck         text not null,
    tool_version text
);

insert into runs(run_id, label, started_at, deck, tool_version) values
    (1, '2026-11-10-nightly', '2026-11-10T22:00:00', 'drc_deck_v3.2', '2026.1'),
    (2, '2026-11-11-nightly', '2026-11-11T22:00:00', 'drc_deck_v3.2', '2026.1');

create table violations_new(
    violation_id integer primary key,
    run_id       integer not null references runs(run_id),
    rule_id      integer not null references rules(rule_id),
    layer_id     integer not null references layers(layer_id),
    cell         text not null,
    view         text not null,
    x            real not null,
    y            real not null,
    status       text not null default 'open'
                  check(status in ('open', 'waived', 'fixed')),
    owner        text,
    note         text
);

insert into violations_new(
    violation_id, run_id, rule_id, layer_id, cell, view,
    x, y, status, owner, note
)
select
    v.violation_id,
    r.run_id,
    ru.rule_id,
    l.layer_id,
    v.cell,
    v.view,
    v.x,
    v.y,
    v.status,
    v.owner,
    v.note
from violations v
join runs r on r.label = v.run_label
join rules ru on ru.name = v.rule_name
join layers l on l.name = v.layer;

drop table violations;
alter table violations_new rename to violations;
