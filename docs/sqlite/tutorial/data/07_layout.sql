-- 第 10 章：INV_X1 的版图图形快照。
create table shapes(
    shape_id   integer primary key,
    cell       text not null,
    view       text not null default 'layout',
    layer      text not null,
    purpose    text not null default 'drawing',
    shape_type text not null
               check(shape_type in ('rect', 'polygon', 'path', 'via')),
    x1         real,
    y1         real,
    x2         real,
    y2         real,
    points     text,
    width      real,
    via        text,
    check(shape_type != 'path' or width is not null),
    check(shape_type != 'via' or via is not null)
);

insert into shapes(
    shape_id, cell, layer, purpose, shape_type,
    x1, y1, x2, y2, points, width, via
) values
    (1,  'INV_X1', 'M1', 'drawing', 'rect',
     0.0, 0.0, 2.0, 1.0, null, null, null),
    (2,  'INV_X1', 'M1', 'drawing', 'rect',
     0.2, 0.2, 0.6, 0.8, null, null, null),
    (3,  'INV_X1', 'M1', 'drawing', 'rect',
     1.4, 0.2, 1.8, 0.8, null, null, null),
    (4,  'INV_X1', 'M1', 'drawing', 'polygon',
     0.6, 0.2, 1.4, 0.8, '0.6,0.2 1.4,0.2 1.0,0.8', null, null),
    (5,  'INV_X1', 'M1', 'drawing', 'path',
     0.0, 1.15, 2.0, 1.25, '0,1.2 2,1.2', 0.1, null),
    (6,  'INV_X1', 'V1', 'drawing', 'via',
     0.35, 0.45, 0.45, 0.55, null, null, 'V1'),
    (7,  'INV_X1', 'V1', 'drawing', 'via',
     1.55, 0.45, 1.65, 0.55, null, null, 'V1'),
    (8,  'INV_X1', 'PO', 'drawing', 'rect',
     0.2, 0.0, 0.6, 1.0, null, null, null),
    (9,  'INV_X1', 'PO', 'drawing', 'rect',
     1.4, 0.0, 1.8, 1.0, null, null, null),
    (10, 'INV_X1', 'M2', 'drawing', 'rect',
     0.0, 1.15, 2.0, 1.25, null, null, null);
