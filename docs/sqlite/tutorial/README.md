# ycSQLite 数据库教程

[返回 ycSQLite API 手册](../README.md)

这是一本写给版图工程师的数据库入门教程。你不需要学过编程，也不需要先懂 SQL。教程从一张常见的 DRC Excel 表开始，一步步做出 `drc.db` 和 `signoff.db`，最后能自己设计表、查数据、改数据，并知道什么时候该用事务和约束。

学完以后，你应该能完成这些事：

- 把一张靠颜色、合并单元格和批注表达的 Excel 表，拆成有明确列、主键和外键的数据库表；
- 用 `SELECT` 筛选、排序、分组和关联多张表；
- 用 `INSERT`、`UPDATE`、`DELETE` 修改数据，并用事务避免改坏；
- 用主键、外键、唯一约束、`CHECK`、索引和 `VIEW` 管理数据质量；
- 在 CIW 里用 `ycSQLite` 的 `Open`、`query`、`execute`、`transaction` 完成一套可重复的检查流程。

## 读者与环境

教程假设你会做版图，熟悉这些词：`oa`、`ddId`、`lib`、`cell`、`view`、`dbId`、`instance`、`via`、`shape`、`rect`、`polygon`、`path`。不要求你会写 SKILL，也不要求你用过数据库。

运行环境是 Virtuoso 的 CIW。`ycSQLite` 默认会调用模块自带的 `sqlite3.sh`。如果测试机上没有可用的 `sqlite3`，教程第 0 章会给一次性的配置方法。

教程使用的数据库文件放在当前工作目录下的 `./sqlite-tutorial/`。这个目录可以随时删掉重建，不会动到 `oa` 库。

## 章节

| 章 | 主题 | 你会做出什么 |
| --- | --- | --- |
| [0](00-how-to-read.md) | 导读 | 建好教程数据库，知道怎么读示例 |
| [1](01-from-excel-to-database.md) | 从 Excel 到数据库 | 第一张 `layers` 表 |
| [2](02-one-table.md) | 一张表能走多远 | 把扁平 DRC 表导入并查出结果 |
| [3](03-split-tables.md) | 拆表 | `rules`、`runs`、`violations` 与 JOIN |
| [4](04-many-to-many.md) | 多对多 | `signoff.db` 的中间表 |
| [5](05-grouping-and-pivot.md) | 汇总与透视 | 按规则、图层、cell 统计 |
| [6](06-changing-data-safely.md) | 改数据不出事故 | 事务、保存点与灾难演练 |
| [7](07-constraints-index-view.md) | 约束、索引与 VIEW | 让数据库自己拒绝坏数据 |
| [8](08-capstone-drc.md) | 综合实战 | 一次完整的 nightly 导入与看板 |
| [附录](appendix-cheatsheet.md) | 速查 | Excel、SQL、`ycSQLite` 对照表 |

## 教程资产

- `data/`：建表和样例数据。每个文件都是一段可以重复执行的 SQL。
- `setup.il`：建库、装数据、显示查询结果。
- `reset.il`：删除教程数据库。
- `img/`：章节示意图。

`setup.il` 和 `reset.il` 是教程辅助脚本，不是 `ycSQLite` 的公开 API。正式项目里，表结构由你自己的脚本或工具维护。

## 记法约定

- 代码块按章顺序粘贴到 CIW。前一块定义的 `db`、`t_sql` 等变量，后一块可以继续用。
- `; =>` 后面是期望输出。表格输出由教程辅助函数 `ycSQLiteTutorialShow` 打印。
- 长 SQL 用 `strcat` 拼成一条字符串，只是为了在文档里换行；你也可以写成一行。
- 字符串用单引号，例如 `'M1'`；列名和表名不加引号。
- `NULL` 表示“没有值”，不是 `0`，也不是空字符串。
- SQL 语句以分号结束。最后一条语句的分号可以省略，但教程统一写分号。

## 从哪开始

第一次读，按 0 到 8 章顺序走。每章开头都会说明从哪个数据库状态开始；如果跳读，先执行该章开头的 `setup` 命令。

[开始读第 0 章](00-how-to-read.md)
