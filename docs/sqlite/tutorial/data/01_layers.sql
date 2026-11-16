-- 第 1 章：第一张查找表。
create table layers(
    layer_id integer primary key,
    name     text not null unique,
    purpose  text
);

insert into layers(name, purpose) values
    ('M1', 'metal 1 routing'),
    ('V1', 'via between M1 and M2'),
    ('PO', 'poly gate');
