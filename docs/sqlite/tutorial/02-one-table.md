# 第 2 章 一张表能走多远

[返回目录](README.md) ｜ [上一章：从 Excel 到数据库](01-from-excel-to-database.md) ｜ [下一章：拆表](03-split-tables.md)

**本章目标**：把一张扁平的 DRC 表搬进数据库，学会筛选、排序、去重和简单统计。学完能回答“哪些 cell 的 M1 spacing 还没修”“谁没有 owner”“两次运行各有多少条”这类问题。

**本章从**：`flat` 教程库。如果上一章改过数据，先重建：

```lisp
load("skill-oo/docs/sqlite/tutorial/setup.il")
ycSQLiteTutorialSetup(?stage 'flat)
db = ycSQLite::Open("./sqlite-tutorial/drc.db")
```

## 2.1 先把 Excel 原样搬进来

第 2 章不急着拆表。先看一张“扁平表”能做什么，也看看它的极限。

`data/02_flat.sql` 建了这张表：

| violation_id | run_label | rule_name | layer | cell | view | x | y | status | owner | note |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | 2026-11-10-nightly | M1.S.1 | M1 | INV_X1 | layout | 12.4 | 8.2 | open |  |  |
| 2 | 2026-11-10-nightly | M1.S.1 | M1 | INV_X1 | layout | 12.4 | 8.4 | open |  |  |
| 3 | 2026-11-10-nightly | M1.S.1 | M1 | NAND2_X1 | layout | 30.1 | 14.0 | waived | li | foundry approved spacing exception |
| 4 | 2026-11-10-nightly | M1.W.1 | M1 | INV_X1 | layout | 13.0 | 9.0 | open | wang |  |

这张表几乎就是 Excel 的翻版：规则名、图层名、cell 名都是文本，状态是一列，owner 可能为空，note 是一句自由文本。

它已经比“靠颜色”前进了一步：状态能读了，规则名每行都有了。但它还有三个问题，第 3 章会处理：

1. 规则名重复很多次，改一条规则的严重级别要改很多行；
2. 图层名重复，写错一个字母就会多出一个假图层；
3. 没有东西阻止你插入一条指向不存在规则的违例。

先不管这些，看看一张表能走多远。

## 2.2 取列、取行、取前几条

最基本的查询是 `select`：

```lisp
ycSQLiteTutorialShow(db->query(strcat(
    "select violation_id, rule_name, layer, cell, status "
    "from violations "
    "order by violation_id "
    "limit 5;"
)))
; => violation_id  rule_name  layer  cell      status
;    ------------  ---------  -----  --------  ------
;    1             M1.S.1     M1     INV_X1    open
;    2             M1.S.1     M1     INV_X1    open
;    3             M1.S.1     M1     NAND2_X1  waived
;    4             M1.W.1     M1     INV_X1    open
;    5             V1.E.1     V1     INV_X1    fixed
```

`select` 后面写要哪些列。不要在生产脚本里写 `select *`：表一改列，输出就变，读代码的人也不知道你到底要什么。

`limit 5` 只要前 5 行。`limit` 通常和 `order by` 一起用；没有 `order by` 时，“前 5 行”没有稳定定义。

## 2.3 筛选：`where`

只要 open 的 M1 违例：

```lisp
ycSQLiteTutorialShow(db->query(strcat(
    "select violation_id, rule_name, cell, status "
    "from violations "
    "where status = 'open' and layer = 'M1' "
    "order by violation_id;"
)))
; => violation_id  rule_name  cell      status
;    ------------  ---------  --------  ------
;    1             M1.S.1     INV_X1    open
;    2             M1.S.1     INV_X1    open
;    4             M1.W.1     INV_X1    open
;    10            M1.S.1     NAND2_X1  open
;    11            M1.W.1     NAND2_X1  open
```

`where` 后面是条件，`and` 表示两个条件都满足。常用写法：

| 写法 | 含义 | 例子 |
| --- | --- | --- |
| `=` | 等于 | `status = 'open'` |
| `<>` | 不等于 | `status <> 'fixed'` |
| `and` | 并且 | `status = 'open' and layer = 'M1'` |
| `or` | 或者 | `layer = 'V1' or layer = 'PO'` |
| `in (...)` | 在列表里 | `layer in ('V1', 'PO')` |
| `between a and b` | 闭区间 | `x between 10 and 20` |
| `like 'M1%'` | 文本匹配 | `rule_name like 'M1%'` |
| `is null` | 没有值 | `owner is null` |
| `is not null` | 有值 | `owner is not null` |

`like` 的 `%` 表示任意长度字符，`_` 表示一个字符。`%` 在开头会导致很难用索引，数据量大时要注意；第 7 章会讲索引。

数一下 `layer in ('V1', 'PO')` 有多少行：

```lisp
car(db->query("select count(*) from violations where layer in ('V1', 'PO');")->rows())->get(0)
; => 4
```

`V1` 有 3 行，`PO` 有 1 行，共 4 行。

## 2.4 排序：`order by`

按 `y` 从大到小，取前 3 条：

```lisp
ycSQLiteTutorialShow(db->query(strcat(
    "select violation_id, cell, y "
    "from violations "
    "order by y desc, violation_id "
    "limit 3;"
)))
; => violation_id  cell      y
;    ------------  --------  ----
;    11            NAND2_X1  15.2
;    6             NAND2_X1  15
;    3             NAND2_X1  14
```

`desc` 是从大到小，默认是从小到大。`order by y desc, violation_id` 的意思是：先按 `y` 降序；`y` 相同的行再按 `violation_id` 升序。加上第二个排序键，结果才稳定。

`y` 是 `real` 列，所以 `15.2 > 15 > 14`。如果把坐标存成 `text`，排序会按字符串比较，`'9'` 会排在 `'10'` 后面，结果就错了。

## 2.5 去重：`distinct`

看有哪些图层：

```lisp
db->query("select distinct layer from violations order by layer;")->toList()
; => (("M1") ("PO") ("V1"))
```

`distinct` 去掉重复值。这里 `M1` 出现很多次，但只返回一行。

`distinct` 也可以配合多列：`select distinct layer, status from violations;` 返回所有出现过的“图层 + 状态”组合。

## 2.6 空值：`is null`

找没有 owner 的违例：

```lisp
ycSQLiteTutorialShow(db->query(strcat(
    "select violation_id, cell, owner "
    "from violations "
    "where owner is null "
    "order by violation_id;"
)))
; => violation_id  cell      owner
;    ------------  --------  -----
;    1             INV_X1
;    2             INV_X1
;    6             NAND2_X1
;    11            NAND2_X1
```

四条没有 owner。注意不能写 `where owner = null`。`NULL` 表示“未知”，`= NULL` 的结果也是未知，不会返回任何行。判断空值只能用 `is null` 或 `is not null`。

## 2.7 简单统计

一行 SQL 可以同时数几件事：

```lisp
ycSQLiteTutorialShow(db->query(strcat(
    "select count(*) as rows_n, "
    "       count(owner) as owner_n, "
    "       count(distinct cell) as cell_n "
    "from violations;"
)))
; => rows_n  owner_n  cell_n
;    ------  -------  ------
;    12      8        2
```

- `count(*)` 数行数，12 行；
- `count(owner)` 只数 `owner` 不为 `NULL` 的行，8 行；
- `count(distinct cell)` 数不同的 cell，2 个。

`count(column)` 和 `count(*)` 的差别是数据库新手最常踩的坑之一。想数“有多少行”用 `count(*)`；想数“有多少行填了这个字段”用 `count(column)`。

## 2.8 分组：先看运行次数

按运行批次分组：

```lisp
ycSQLiteTutorialShow(db->query(strcat(
    "select run_label, count(*) as n "
    "from violations "
    "group by run_label "
    "order by run_label;"
)))
; => run_label           n
;    ------------------  -
;    2026-11-10-nightly  7
;    2026-11-11-nightly  5
```

`group by` 把相同的 `run_label` 放到一组，`count(*)` 数每组多少行。

再看一个更重要的现象：

```lisp
ycSQLiteTutorialShow(db->query(strcat(
    "select cell, rule_name, x, y, count(*) as n "
    "from violations "
    "group by cell, rule_name, x, y "
    "having count(*) > 1 "
    "order by cell, rule_name;"
)))
; => cell      rule_name  x     y    n
;    --------  ---------  ----  ---  -
;    INV_X1    M1.S.1     12.4  8.2  2
;    INV_X1    M1.S.1     12.4  8.4  2
;    INV_X1    V1.E.1     12.5  8.3  2
;    NAND2_X1  M1.S.1     30.1  14   2
```

同一个 cell、同一条规则、同一个坐标出现两次。数据没有重复，原因在于两次运行都发现了同一条违例。扁平表只能靠 `run_label` 区分；第 3 章会把运行拆成单独的 `runs` 表。

`having` 和 `where` 的区别：

- `where` 在分组前过滤行；
- `having` 在分组后过滤组。

上面的 `having count(*) > 1` 不能写成 `where count(*) > 1`。

## 2.9 本章检查点

```lisp
car(db->query("select count(*) from violations;")->rows())->get(0)
; => 12

car(db->query("select count(*) from violations where status = 'open';")->rows())->get(0)
; => 8

car(db->query("select count(*) from violations where status = 'open' and layer = 'M1';")->rows())->get(0)
; => 5
```

再加上：

- 没有 owner 的行有 4 条；
- 不同 cell 有 2 个；
- 不同图层有 3 个；
- 两次运行分别是 7 条和 5 条。

全部对上，说明筛选、排序和分组都跑通了。

## 2.10 常见错误

- **`select *` 上瘾。** 表一变，输出就变。写清楚要哪些列。
- **`where owner = null`。** 永远查不到；用 `is null`。
- **把数字存成文本。** 排序和比较会按字符串来。
- **`count(owner)` 当成行数。** 它只数非 `NULL` 的 owner。
- **`where` 里用聚合函数。** `count(*)`、`sum()` 这类要放到 `having`。
- **没有 `order by` 就取 `limit`。** 结果顺序没有保证。

## 2.11 练习

1. 查 `x` 在 10 到 20 之间的违例，按 `x` 排序。
2. 查状态不是 `open` 的违例，按 `status`、`violation_id` 排序。
3. 数一下 `rule_name` 以 `M1` 开头的违例有多少条。
4. 按 `cell` 分组，数每个 cell 的 open 违例数。

参考答案：

```lisp
car(db->query("select count(*) from violations where x between 10 and 20;")->rows())->get(0)
; => 7

car(db->query("select count(*) from violations where rule_name like 'M1%';")->rows())->get(0)
; => 8
```

本章结束，关闭会话：

```lisp
db->close()
```

[返回目录](README.md) ｜ [上一章：从 Excel 到数据库](01-from-excel-to-database.md) ｜ [下一章：拆表](03-split-tables.md)
