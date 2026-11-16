# 附录 速查

[返回目录](README.md)

## A.1 Excel 与 SQLite 对照

| Excel 说法 | SQLite 说法 | 注意 |
| --- | --- | --- |
| 工作簿 `.xlsx` | 数据库文件 `.db` | 一个数据库文件可以有很多张表 |
| 工作表 sheet | 表 table | 表名建好后尽量不改 |
| 行号 | 主键 primary key | 行号会变，主键不会 |
| 列标题 | 列名 column name | 用英文、下划线，避免空格和关键字 |
| 单元格 | 值 value | 一个单元格只放一个值，不放列表 |
| 合并单元格 | 每一行重复写同一个键 | 数据库没有合并单元格 |
| 单元格颜色 | `status` 列 | 颜色可以保留，但状态必须有值 |
| 批注 | `note` 列或单独的备注表 | 批注不会自动跟着数据走 |
| 公式 | `SELECT` 查询或 `VIEW` | 查询按需计算，不把结果写死在单元格 |
| 透视表 | `GROUP BY` + 条件求和 | 见第 5 章 |
| VLOOKUP | `JOIN` | 见第 3 章 |
| 筛选 | `WHERE` | 见第 2 章 |
| 排序 | `ORDER BY` | 见第 2 章 |
| 多份文件副本 | 一张表 + 运行/版本列 | 不要靠文件名区分版本 |

## A.2 数据库与 OA 的关系

数据库和 OA 不是同一层的东西，不要强行一一对应。

| 问题 | 用什么 |
| --- | --- |
| 版图数据、cellview、instance、shape | OA |
| 设计数据的版本与权限 | OA 库管理 |
| DRC/LVS 检查结果、运行记录 | 数据库 |
| waiver、owner、签核状态 | 数据库 |
| 大批量结果筛选、统计、关联 | 数据库 |
| 几何布尔、描边、区域运算 | 几何库或 OA 几何接口 |

一句话：OA 管“设计是什么”，数据库管“检查发生了什么、人怎么处理”。

## A.3 SQL 速查

### 查询

```sql
-- 取列、筛选、排序、截断
select cell, x, y
from violations
where status = 'open'
order by x, y
limit 10;

-- 去重
select distinct layer from violations;

-- 空值
select * from violations where owner is null;

-- 文本匹配
select * from violations where rule_name like 'M1%';

-- 区间
select * from violations where x between 10 and 20;

-- 列表
select * from violations where layer in ('M1', 'V1');
```

### 聚合

```sql
-- 分组计数
select status, count(*) as n
from violations
group by status;

-- 分组后过滤
select cell, count(*) as n
from violations
group by cell
having count(*) > 4;

-- 条件计数
select cell,
       count(*) as total,
       sum(case when status = 'open' then 1 else 0 end) as open_n
from violations
group by cell;

-- 最值
select min(x), max(x), min(y), max(y) from violations;
```

### 连接

```sql
-- 内连接：两边都有匹配才保留
select v.violation_id, ru.name
from violations v
join rules ru on ru.rule_id = v.rule_id;

-- 左连接：左表全保留，右表没有匹配填 NULL
select b.name, bc.status
from blocks b
left join block_checks bc on bc.block_id = b.block_id;
```

### 修改

```sql
-- 插入
insert into layers(name, purpose) values ('M2', 'metal 2 routing');

-- 插入多条
insert into layers(name, purpose) values
    ('M3', 'metal 3 routing'),
    ('M4', 'metal 4 routing');

-- 更新
update violations set owner = 'chen' where violation_id = 1;

-- 删除
delete from violations where violation_id = 13;
```

改数据前先用同样的 `where` 跑一遍 `select`。

### 事务

```lisp
db->transaction(lambda((d)
    d->execute("insert into runs(label, started_at, deck) values ('r1', '2026-11-16T10:00:00', 'deck');")
    d->execute("insert into violations(run_id, rule_id, layer_id, cell, view, x, y, status) values (1, 1, 1, 'INV_X1', 'layout', 0, 0, 'open');")
))
```

回调报错时整体回滚；嵌套调用使用保存点。

### 索引与视图

```sql
create index if not exists idx_violations_rule on violations(rule_id);
create view if not exists open_violations as
    select * from violations where status = 'open';
drop view if exists open_violations;
```

## A.4 ycSQLite API 速查

| 任务 | 用法 |
| --- | --- |
| 打开文件库 | `db = ycSQLite::Open("./app.db")` |
| 临时内存库 | `db = ycSQLite::Open(":memory:")` |
| 关闭 | `db->close()` |
| 自动关闭 | `ycWith(db ycSQLite::Open("./app.db") ...)` |
| 查询 | `db->query("select ...;")` |
| 带参数查询 | `db->query("select ... where id = ?;" ?params list(1))` |
| 建表/插入/更新/删除 | `db->execute("...")` |
| 多语句脚本 | `db->executeScript("...; ...;")` |
| 事务 | `db->transaction(lambda((d) ...))` |
| 表列表 | `db->tables()` |
| 列信息 | `db->columns("violations")` |
| 表/视图 DDL | `db->schema(?table "violations")` |
| 表/视图是否存在 | `db->exists("violations")` |
| 行数 | `result->rowCount()` |
| 行列表 | `result->rows()` |
| 值列表 | `result->toList()` |
| 列名 | `result->columns()` |
| 改动行数 | `result->changes()` |
| 最近插入 id | `result->lastInsertRowid()` |
| 按列名取值 | `row->get("cell")` |
| 整行取值 | `row->toList()` / `row->toAlist()` |
| 配置客户端 | `ycSQLite::Configure(...)` |
| 检查客户端 | `ycSQLite::ProbeClient()` |
| 默认客户端 | `ycSQLite::DefaultClient()` |

## A.5 常见错误

| 错误 | 常见原因 | 处理 |
| --- | --- | --- |
| `no such table: xxx` | 表名写错，或没建表 | 查 `db->tables()` |
| `no such column: xxx` | 列名写错，或表改了 | 查 `db->columns("表名")` |
| `column xxx is not unique` | 违反 `unique` 或主键 | 先查重复值 |
| `constraint failed` | 违反 `check` | 看 `check` 允许哪些值 |
| `xxx may not be NULL` | 违反 `not null` | 补值，或允许为空 |
| `foreign key constraint failed` | 引用了不存在的父行 | 先插父表，或检查 id |
| `near "...": syntax error` | SQL 拼写、引号、分号问题 | 从错误位置往前看 |
| `database is locked` | 另一个会话在写 | 等它结束，或只留一个写入者 |
| `datatype mismatch` | 值类型和列差太多 | 检查参数类型 |

错误消息会随客户端版本变化。教程里写的是常见形式，实际以 CIW 输出为准。

## A.6 旧客户端的 SQL 限制

教程按旧客户端也能跑的范围写。下面这些特性在旧版 SQLite 里不可用：

| 特性 | 旧客户端 | 替代写法 |
| --- | --- | --- |
| `WITH`（CTE） | 不支持 | 用子查询或临时表 |
| 窗口函数 `row_number()` 等 | 不支持 | 用 `group by` + 子查询 |
| `UPSERT`（`on conflict do update`） | 不支持 | 先查再插，或 `insert or replace` |
| `RETURNING` | 不支持 | 插入后查 `last_insert_rowid()` |
| 独立 `VALUES` 语句 | 不支持 | `select ... union all select ...` |

`ycSQLite` 只透传 SQL，不会模拟客户端缺失的特性。换客户端前先确认版本。

## A.7 重置清单

教程状态乱了，按顺序执行：

```lisp
load("skill-oo/docs/sqlite/tutorial/setup.il")
ycSQLiteTutorialReset()
ycSQLiteTutorialSetup(?stage 'full)
```

只回到第 1、2 章：

```lisp
ycSQLiteTutorialSetup(?stage 'flat)
```

每次 `setup` 都会先删旧库，再按样例数据重建。

## A.8 术语

| 术语 | 含义 |
| --- | --- |
| 表 table | 由行和列组成的数据集合 |
| 行 row | 一条记录 |
| 列 column | 一个字段 |
| 主键 primary key | 唯一标识一行的列 |
| 外键 foreign key | 指向另一张表主键的列 |
| 索引 index | 加速查找的结构 |
| 视图 view | 保存下来的一条查询 |
| 事务 transaction | 一组要么全成、要么全退的修改 |
| 保存点 savepoint | 事务里的嵌套回滚点 |
| `NULL` | 没有值 |
| `JOIN` | 按条件把多张表连起来 |
| `GROUP BY` | 按列分组，常和聚合函数一起用 |

[返回目录](README.md)
