# 第 5 章 汇总与透视

[返回目录](README.md) ｜ [上一章：多对多](04-many-to-many.md) ｜ [下一章：改数据不出事故](06-changing-data-safely.md)

**本章目标**：学会 `count`、`sum`、`avg`、`min`、`max`、`group by`、`having`，并用条件求和做出 Excel 透视表的效果。

**本章从**：`full` 教程库。

```lisp
load("skill-oo/docs/sqlite/tutorial/setup.il")
ycSQLiteTutorialSetup(?stage 'full)
db = ycSQLite::Open("./sqlite-tutorial/drc.db")
```

## 5.1 Excel 透视表在 SQL 里叫什么

Excel 透视表通常有三块：

- 行：按什么分组，例如按 rule；
- 列：按什么展开，例如按 status；
- 值：每组算什麼，例如 count。

SQL 用 `group by` 做“行”，用 `case when` 做“列”，用 `count`/`sum` 做“值”。

先看最简单的分组：

```lisp
ycSQLiteTutorialShow(db->query(strcat(
    "select status, count(*) as n "
    "from violations "
    "group by status "
    "order by status;"
)))
; => status  n
;    ------  -
;    fixed   3
;    open    8
;    waived  1
```

8 条 open，3 条 fixed，1 条 waived。和前面手工数的结果一致。

## 5.2 按规则统计

把规则名和严重级别一起带出来：

```lisp
ycSQLiteTutorialShow(db->query(strcat(
    "select ru.name as rule, ru.severity as severity, count(*) as n "
    "from violations v "
    "join rules ru on ru.rule_id = v.rule_id "
    "group by ru.rule_id, ru.name, ru.severity "
    "order by n desc, ru.name;"
)))
; => rule    severity  n
;    ------  --------  -
;    M1.S.1  error     6
;    V1.E.1  error     3
;    M1.W.1  error     2
;    PO.R.1  warning   1
```

`group by` 里写了 `ru.rule_id, ru.name, ru.severity` 三列。标准 SQL 要求 `select` 里非聚合的列都出现在 `group by` 里；SQLite 比较宽松，但写全更清楚，也方便换数据库。

`order by n desc` 按别名 `n` 排序。`desc` 是从大到小。

## 5.3 条件计数：open 率

想同时看每个 cell 的总数和 open 数：

```lisp
ycSQLiteTutorialShow(db->query(strcat(
    "select cell, "
    "       count(*) as total, "
    "       sum(case when status = 'open' then 1 else 0 end) as open_n "
    "from violations "
    "group by cell "
    "order by cell;"
)))
; => cell      total  open_n
;    --------  -----  ------
;    INV_X1    8      5
;    NAND2_X1  4      3
```

`case when status = 'open' then 1 else 0 end` 把每一行变成 1 或 0，再 `sum`。这是 Excel 里 `COUNTIFS` 的 SQL 写法。

`INV_X1` 总共 8 条，其中 5 条 open；`NAND2_X1` 总共 4 条，其中 3 条 open。

## 5.4 Top N：先排序，再截断

按 open 数排前 3 条规则：

```lisp
ycSQLiteTutorialShow(db->query(strcat(
    "select ru.name as rule, count(*) as open_n "
    "from violations v "
    "join rules ru on ru.rule_id = v.rule_id "
    "where v.status = 'open' "
    "group by ru.rule_id, ru.name "
    "order by open_n desc, ru.name "
    "limit 3;"
)))
; => rule    open_n
;    ------  ------
;    M1.S.1  3
;    M1.W.1  2
;    V1.E.1  2
```

`M1.S.1` 有 3 条 open；`M1.W.1` 和 `V1.E.1` 各 2 条。`order by open_n desc, ru.name` 在数量相同时按规则名排序，结果才稳定。

## 5.5 透视：图层 × 状态

把图层放在行，状态放在列：

```lisp
ycSQLiteTutorialShow(db->query(strcat(
    "select l.name as layer, "
    "       sum(case when v.status = 'open' then 1 else 0 end) as open_n, "
    "       sum(case when v.status = 'waived' then 1 else 0 end) as waived_n, "
    "       sum(case when v.status = 'fixed' then 1 else 0 end) as fixed_n "
    "from layers l "
    "left join violations v on v.layer_id = l.layer_id "
    "group by l.layer_id, l.name "
    "order by l.name;"
)))
; => layer  open_n  waived_n  fixed_n
;    -----  ------  --------  -------
;    M1     5       1         2
;    PO     1       0         0
;    V1     2       0         1
```

这就是一张透视表：

- 行是 `layer`；
- 列是 `open_n`、`waived_n`、`fixed_n`；
- 值来自 `sum(case when ...)`。

用 `left join` 是为了让没有违例的图层也出现。现在三个图层都有数据，所以结果一样；以后新增一个空图层时，`left join` 会保留它，计数为 0。

## 5.6 豁免与过期

`waivers` 表记录 waiver。查哪些违例有 waiver，以及 waiver 是否过期：

```lisp
ycSQLiteTutorialShow(db->query(strcat(
    "select v.violation_id, ru.name as rule, w.owner, w.expires_on, "
    "       case "
    "         when w.waiver_id is null then 'none' "
    "         when w.expires_on < '2026-11-16' then 'expired' "
    "         else 'active' "
    "       end as waiver_state "
    "from violations v "
    "join rules ru on ru.rule_id = v.rule_id "
    "left join waivers w on w.violation_id = v.violation_id "
    "where w.waiver_id is not null or v.status = 'waived' "
    "order by v.violation_id;"
)))
; => violation_id  rule    owner  expires_on  waiver_state
;    ------------  ------  -----  ----------  ------------
;    3             M1.S.1  li     2026-12-31  active
;    7             PO.R.1  li     2026-10-31  expired
```

这条查询混合了三种技巧：

1. `left join waivers`：没有 waiver 的违例也要保留；
2. `case when`：把“有没有 waiver、过没过期”翻译成文本状态；
3. `where ... or ...`：只看有 waiver 的，或者状态本身是 waived 的。

教程把“今天”固定成 `2026-11-16`，所以结果是确定的。真实脚本里可以用 SQLite 的 `date('now')`，或者由外部传入日期。

## 5.7 `having`：过滤组

找违例超过 4 条的 cell：

```lisp
ycSQLiteTutorialShow(db->query(strcat(
    "select cell, count(*) as n "
    "from violations "
    "group by cell "
    "having count(*) > 4 "
    "order by n desc;"
)))
; => cell    n
;    ------  -
;    INV_X1  8
```

`where` 在分组前过滤行，`having` 在分组后过滤组。`count(*) > 4` 是对组的条件，所以用 `having`。

## 5.8 聚合函数的空值

`sum`、`avg`、`min`、`max` 在没有行时返回 `NULL`，不是 0：

```lisp
db->query("select sum(x) as s from violations where 0;")->toList()
; => ((nil))
```

需要 0 时用 `coalesce`：

```lisp
db->query("select coalesce(sum(x), 0) as s from violations where 0;")->toList()
; => ((0))
```

`count(*)` 是例外，没有行时返回 0。

## 5.9 本章检查点

```lisp
db->query(strcat(
    "select status, count(*) as n from violations "
    "group by status order by status;"
))->toList()
; => (("fixed" 3) ("open" 8) ("waived" 1))
```

再确认：

- `INV_X1` 有 8 条，其中 5 条 open；
- 按规则统计是 6、3、2、1；
- 图层 × 状态矩阵是 M1 `5/1/2`、PO `1/0/0`、V1 `2/0/1`；
- 有一条 active waiver 和一条 expired waiver。

## 5.10 常见错误

- **在 `where` 里用聚合函数。** `where count(*) > 4` 会报错；用 `having`。
- **`count(column)` 当行数。** 它跳过 `NULL`；行数用 `count(*)`。
- **`sum` 没行时当成 0。** 它是 `NULL`；需要 0 就用 `coalesce`。
- **分组后 `select` 了没分组的列。** 结果不可预测；把非聚合列写进 `group by`。
- **`left join` 后再用 `where` 过滤右表。** 会把外连接变成内连接；条件写进 `on`，或者接受这个语义。

## 5.11 练习

1. 按 `run_id` 统计每次运行的 open 数。
2. 按 `owner` 统计 open 数，`NULL` 单独一组。
3. 查每条规则的 open 率，按 open 率降序。
4. 把 5.5 的矩阵加上 `total_n` 列。

示例：

```lisp
ycSQLiteTutorialShow(db->query(strcat(
    "select owner, count(*) as open_n "
    "from violations "
    "where status = 'open' "
    "group by owner "
    "order by open_n desc;"
)))
; => owner  open_n
;    -----  ------
;           4
;    wang   3
;    li     1
```

本章结束，关闭会话：

```lisp
db->close()
```

[返回目录](README.md) ｜ [上一章：多对多](04-many-to-many.md) ｜ [下一章：改数据不出事故](06-changing-data-safely.md)
