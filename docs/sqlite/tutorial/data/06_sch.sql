-- 第 9 章：反相器链的连接快照。
create table instances(
    instance_id integer primary key,
    name        text not null unique,
    cell        text not null,
    x           real,
    y           real
);

insert into instances(instance_id, name, cell, x, y) values
    (1, 'PORT_A', 'PORT',   0.0, 0.0),
    (2, 'I1',     'INV_X1', 2.0, 0.0),
    (3, 'I2',     'INV_X1', 4.0, 0.0),
    (4, 'BUF',    'BUF_X2', 6.0, 0.0),
    (5, 'PORT_Y', 'PORT',   8.0, 0.0);

create table nets(
    net_id integer primary key,
    name   text not null unique,
    kind   text not null check(kind in ('signal', 'power', 'ground'))
);

insert into nets(net_id, name, kind) values
    (1, 'A',     'signal'),
    (2, 'N1',    'signal'),
    (3, 'Y',     'signal'),
    (4, 'SPARE', 'signal'),
    (5, 'VDD',   'power'),
    (6, 'VSS',   'ground');

create table terminals(
    terminal_id integer primary key,
    instance_id integer not null references instances(instance_id),
    pin         text not null,
    direction   text not null
                check(direction in ('input', 'output', 'inout', 'power', 'ground')),
    net_id      integer references nets(net_id),
    unique(instance_id, pin)
);

insert into terminals(instance_id, pin, direction, net_id) values
    (1, 'P',   'inout',  1),
    (2, 'A',   'input',  1),
    (2, 'ZN',  'output', 2),
    (2, 'VDD', 'power',  5),
    (2, 'VSS', 'ground', 6),
    (3, 'A',   'input',  2),
    (3, 'ZN',  'output', 3),
    (3, 'VDD', 'power',  5),
    (3, 'VSS', 'ground', 6),
    (4, 'A',   'input',  3),
    (4, 'Z',   'output', 4),
    (4, 'EN',  'input',  null),
    (4, 'VDD', 'power',  5),
    (4, 'VSS', 'ground', 6),
    (5, 'P',   'inout',  3);
