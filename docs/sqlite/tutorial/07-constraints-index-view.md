# 第 7 章 约束、索引与 VIEW

[返回目录](README.md) ｜ [上一章：改数据不出事故](06-changing-data-safely.md) ｜ [下一章：综合实战](08-capstone-drc.md)

**本章目标**：让数据库自己拒绝坏数据，学会索引的取舍，并理解 SQL 的 `VIEW` 和 OA 的 view 不是一回事。

**本章从**：`full` 教程库。

```lisp
load("skill-oo/docs/sqlite/tutorial/setup.il")
ycSQLiteTutorialSetup(?stage 'full)
db = ycSQLite::Open("./sqlite-tutorial/drc.db")
```

## 7.1 约束是数据库的守门员

前面已经见过几种约束：

| 约束 | 作用 | 例子 |
| --- | --- | --- |
| `primary key` | 唯一标识一行 | `violation_id integer primary key` |
| `not null` | 不能为空 | `reason text not null` |
| `unique` | 不能重复 | `violations.violation_id` 在 `waivers` 里唯一 |
| `check` | 值必须满足条件 | `status in ('open', 'waived', 'fixed')` |
| `references` | 外键，必须指向父表 | `violation_id references violations` |
| `default` | 没写时给默认值 | `status text not null default 'open'` |

看教程库里的 `waivers`：

```lisp
printf("%s\n" db->schema(?table "waivers"))
; => CREATE TABLE waivers(
;        waiver_id    integer primary key,
;        violation_id integer not null unique
;                       references violations(violation_id) on delete cascade,
;        reason       text not null,
;        owner        text not null,
;        expires_on   text,
;        created_at   text not null
;    )
```

逐条读：

- 每条 waiver 有独立 `waiver_id`；
- `violation_id` 不能为空，不能重复，必须指向一条存在的违例；
- `reason`、`owner`、`created_at` 不能为空；
- `expires_on` 可以为空，表示长期有效；
- `on delete cascade` 表示违例被删除时，对应的 waiver 也跟着删。

## 7.2 约束怎么拒绝坏数据

为了不污染教程库，下面用内存库演示：

```lisp
mem = ycSQLite::Open(":memory:")
mem->executeScript(strcat(
    "create table t("
    "  id     integer primary key,"
    "  name   text not null unique,"
    "  status text not null check(status in ('open', 'fixed'))"
    ");"
    "insert into t(id, name, status) values (1, 'a', 'open');"
))
```

唯一约束：

```lisp
errset(mem->execute("insert into t(id, name, status) values (2, 'a', 'open');") nil)
; => nil
```

CIW 里会看到类似 `column name is not unique` 的诊断。`name` 上写了 `unique`，第二行 `a` 被拒绝。

`CHECK`：

```lisp
errset(mem->execute("update t set status = 'done' where id = 1;") nil)
; => nil
```

`status` 只允许 `open` 和 `fixed`，`done` 被拒绝。诊断类似 `constraint failed`。

`NOT NULL`：

```lisp
errset(mem->execute("insert into t(id, name, status) values (3, null, 'open');") nil)
; => nil
```

`name` 不能为空，诊断类似 `t.name may not be NULL`。

外键：

```lisp
fk = ycSQLite::Open(":memory:")
fk->executeScript(strcat(
    "create table parent(id integer primary key);"
    "create table child(pid integer references parent(id));"
))
errset(fk->execute("insert into child(pid) values (99);") nil)
; => nil
```

`child.pid = 99` 找不到父行，诊断类似 `foreign key constraint failed`。

这些错误都在插入或修改时发生，数据不会写进去。数据库不会“先收下再提醒你”。

## 7.3 唯一约束和主键的区别

主键也是唯一，但一个表只能有一个主键；唯一约束可以有多个。

- `violations.violation_id` 是主键：每条违例只能有一个 id。
- `waivers.violation_id` 是唯一约束：一条违例最多一个 waiver，但 waiver 自己还有主键 `waiver_id`。
- `layers.name` 是唯一约束：图层名不能重复。

SQLite 的 `UNIQUE` 允许多个 `NULL`。如果业务上要求“不能为空且不能重复”，要同时写 `not null unique`。

## 7.4 索引：让查找变快，让写入变慢

查 `rule_id = 1` 的违例，如果表很大，逐行扫描很慢。索引像书的目录，先查目录再定位行。

在 `violations.rule_id` 上建索引：

```lisp
db->execute("create index if not exists idx_violations_rule on violations(rule_id);")
```

确认索引存在：

```lisp
ycSQLiteTutorialShow(db->query(strcat(
    "select name, tbl_name "
    "from sqlite_master "
    "where type = 'index' and name = 'idx_violations_rule';"
)))
; => name                 tbl_name
;    -------------------  ----------
;    idx_violations_rule  violations
```

`sqlite_master` 是数据库自己的目录表，记录所有表、索引、视图和触发器。`type = 'index'` 筛出索引。

索引不是越多越好：

- 查询会变快；
- 插入、更新、删除要维护索引，会变慢；
- 索引占空间；
- 重复值很多的列，索引收益有限。

常给外键列建索引，例如 `violations.rule_id`、`violations.run_id`、`block_checks.check_id`。不要给每个列都建。

## 7.5 VIEW：保存一条查询

经常要查 open 违例，可以存成视图：

```lisp
db->executeScript(strcat(
    "create view if not exists open_violations as "
    "select v.violation_id, ru.name as rule, v.cell, v.owner "
    "from violations v "
    "join rules ru on ru.rule_id = v.rule_id "
    "where v.status = 'open';"
))
```

之后像表一样查：

```lisp
car(db->query("select count(*) from open_violations;")->rows())->get(0)
; => 8
```

视图不存数据，只保存查询。每次查视图，数据库都会重新执行里面的 `select`。

确认它是视图：

```lisp
db->exists("open_violations")
; => t

db->tables()
; => ("layers" "rules" "runs" "violations" "waivers")
```

`tables()` 不返回视图；`exists()` 对表和视图都返回 `t`。看视图定义：

```lisp
printf("%s\n" db->schema(?table "open_violations"))
; => CREATE VIEW open_violations as select ...
```

需要删除时执行 `drop view if exists open_violations;`。教程先保留这个视图，第 8 章还会用。

## 7.6 SQL VIEW 不是 OA view

版图里的 view 是 `layout`、`schematic`、`symbol` 这类设计视图，属于 OA 库，背后有 `cellview`、`dbId` 和几何对象。

SQL 的 `VIEW` 只是一条保存的 `SELECT`：

- 不包含版图数据；
- 不产生新的 OA cellview；
- 不能替代 `dbOpenCellViewByType`；
- 默认只读，除非额外写触发器。

名字一样，东西完全不同。读文档时看到 `VIEW`，先看上下文。

## 7.7 本章检查点

```lisp
ycSQLiteTutorialShow(db->query(strcat(
    "select name from sqlite_master "
    "where type = 'index' and name = 'idx_violations_rule';"
)))
; => name
;    -------------------
;    idx_violations_rule

car(db->query("select count(*) from open_violations;")->rows())->get(0)
; => 8
```

再回答：

1. `unique` 和 `primary key` 有什么区别？
2. 为什么不要给每一列都建索引？
3. SQL `VIEW` 能不能替代 OA view？

答案：主键只能一个，唯一约束可以多个；索引让写入变慢、占空间；不能。

## 7.8 常见错误

- **以为 `UNIQUE` 不允许 `NULL`。** SQLite 允许多个 `NULL`；需要非空就加 `not null`。
- **给每一列建索引。** 写入会变慢，空间也会涨。
- **把视图当备份。** 视图不存数据；删了基表，视图也查不出东西。
- **用 `CHECK` 修旧数据。** 约束只影响之后的插入和修改；旧数据要自己清理。
- **把 SQL `VIEW` 和 OA view 混为一谈。** 两者没有关系。

## 7.9 练习

1. 给 `violations.run_id` 建索引，确认 `sqlite_master` 里有记录。
2. 建一个 `open_by_cell` 视图，按 cell 统计 open 数。
3. 在内存库里试 `not null`、`unique`、`check`、外键各一次。
4. 想想 `waivers` 的 `on delete cascade` 删除违例时会发生什么。

关闭本章的内存库和教程库：

```lisp
mem->close()
fk->close()
db->close()
```

[返回目录](README.md) ｜ [上一章：改数据不出事故](06-changing-data-safely.md) ｜ [下一章：综合实战](08-capstone-drc.md)
