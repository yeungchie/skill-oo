# ycSQLite

[返回首页](../../README.md)

Cadence SKILL++ 的 SQLite 客户端封装库：默认客户端可用时直接使用，也可配置一次外部客户端后复用。

从零开始学数据库，见 [SQLite 教程](tutorial/README.md)。

## 概要

+ SQLite 由外部客户端进程提供；模块不内置 SQLite，也不依赖 SKILL 引擎的原生数据库接口。
+ 模块随附的 `sqlite3.sh` 不是 SQLite 引擎，只是启动系统 `sqlite3` 的包装脚本；真正执行 SQL 的仍是外部 `sqlite3` 客户端。
+ 可用 `YC_SKILL_OO_SQLITE_CLIENT` 环境变量或 `ycSQLite::Configure` 指定客户端。
+ 一个 `Database` 对应一个长驻会话；查询、执行与事务共享同一连接。
+ `":memory:"` 创建临时内存数据库：不生成文件，关闭 `Database` 后内容消失。
+ `Database` 支持 `ycWith`：正常退出和体内出错都会关闭会话。
+ 支持位置参数 `?`；参数值由模块安全转义。
+ 最后一条语句末尾的分号可以省略；语句之间仍需用分号分隔。
+ SQLite 类型会被保留：`NULL`、整数、浮点、文本与 `BLOB` 分别映射为 `nil`、fixnum 或字符串、flonum、字符串与 `ycSQLite::Blob`。
+ 超出 32 位的整数以十进制字符串返回，避免静默截断；`BLOB` 默认以十六进制文本保存。
+ 外键约束默认开启：`Open` 的 `?foreignKeys` 默认 `t`，显式传 `nil` 可关闭；该选项设置会话启动状态，之后仍可用 `PRAGMA foreign_keys` 改变当前会话。
+ SQL 能力取决于所配置客户端的版本；模块只透传，不模拟客户端缺失的 SQL 特性。
+ 自定义客户端需兼容 `sqlite3` 的命令行会话约定：SQL 结果写标准输出，诊断写标准错误；模块按行解析输出，并据此识别执行错误。客户端应尽快写出诊断；诊断严重滞后时，模块每次请求最多多等约 0.3 秒。
+ 一次调用包含多条语句时，某条语句出错后是否继续执行后续语句取决于客户端对输入行的处理，模块不保证。

## 快速上手

下面的例子使用文件数据库 `./app.sqlite`；如果只需要临时数据，可以把路径换成 `":memory:"`，它不会创建文件，关闭会话后内容会消失。

```lisp
; 打开数据库文件；文件不存在时会创建
db = ycSQLite::Open("./app.sqlite")

; 创建表：id 是自增主键，body 保存文本
db->execute("create table if not exists note(id integer primary key, body text);")

; 插入一行；? 是占位符，?params 按顺序提供实际值
db->execute(
    "insert into note(body) values (?);"
    ?params list("hello")
)

; 查询表中所有记录，并按 id 升序排列
rows = db->query("select id, body from note order by id;")
rows->rowCount()
; => 1（一行记录）

; 取第一行，再按列名读取 body
row = car(rows->rows())
row->get("body")
; => "hello"

; 关闭数据库会话，释放后台客户端进程
db->close()

; with：离开作用域自动关闭
ycWith(db2 ycSQLite::Open("./app.sqlite")
    db2->query("select 1;")
)
```

## API 参考

### ycSQLite::Open <sub>`function`</sub>

```text
ycSQLite::Open(
    t_path
    [ ?timeout n_timeout ]
    [ ?busyTimeout n_busyTimeout ]
    [ ?foreignKeys g_enable ]
)
=> ycSQLite::Database
```

**描述**

打开数据库并启动长驻会话。`t_path` 是文件路径时使用文件数据库；文件不存在时会创建。`":memory:"` 是 SQLite 的特殊路径，表示只在当前 `Database` 会话内存在的内存数据库：不会生成文件，`close()` 后其中的表和数据全部消失。需要临时计算、演示或验证 SQL 时使用它；需要长期保存数据时使用普通文件路径。外键约束默认开启；声明了 `references` 的表会按 SQLite 外键规则校验。批量导入或兼容旧数据时可传 `?foreignKeys nil` 关闭。客户端使用 `DefaultClient()`；未配置或验证失败时以 `error()` 中断。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| t_path | `str` |  | 文件路径，或 `":memory:"`（临时内存数据库，关闭后丢失） |
| ?timeout n_timeout | `int / nil` | `nil` | 会话请求等待秒数 |
| ?busyTimeout n_busyTimeout | `int / nil` | `nil` | `busy_timeout` 毫秒数 |
| ?foreignKeys g_enable | `t / nil` | `t` | 会话启动时的外键开关；`nil` 关闭 |

**返回值**

`ycSQLite::Database` — 已启动的数据库对象。

**例程**

```lisp
db = ycSQLite::Open("./app.sqlite" ?busyTimeout 1000)
db->path()
; => "./app.sqlite"
db->close()

; 内存数据库：不创建文件，关闭后数据消失
mem = ycSQLite::Open(":memory:")
mem->execute("create table temp_value(x integer);")
car(mem->query("select count(*) from temp_value;")->rows())->get(0)
; => 0（表中没有记录）
mem->close()

; 外键默认开启：孤儿行会被拒绝
fk = ycSQLite::Open(":memory:")
fk->execute("create table parent(id integer primary key);")
fk->execute("create table child(pid integer references parent(id));")
fk->execute("insert into child(pid) values (1);")
; => 以 error() 中断（外键约束失败）
fk->close()

; 批量导入或兼容旧数据时，可显式关闭
raw = ycSQLite::Open(":memory:" ?foreignKeys nil)
raw->execute("create table parent(id integer primary key);")
raw->execute("create table child(pid integer references parent(id));")
raw->execute("insert into child(pid) values (1);")
; => 成功（未校验外键）
raw->close()
```

### ycSQLite::Database <sub>`class`</sub>

长驻 SQLite 会话。实例由 `ycSQLite::Open` 构造；实现 `ycWith` 的进入/退出协议，离开作用域时自动关闭会话。

**方法**

> 必须使用 `->` 符号调用方法。

#### path <sub>`method`</sub>

```text
db->path()
=> str
```

返回数据库路径。

```lisp
ycSQLite::Open(":memory:")->path()
; => ":memory:"
```

#### client <sub>`method`</sub>

```text
db->client()
=> ycSQLite::Client
```

返回该数据库使用的客户端。

```lisp
ycSQLite::Open(":memory:")->client()->version()
; => "3.x.y"
```

#### isPersistent <sub>`method`</sub>

```text
db->isPersistent()
=> t
```

返回是否使用长驻会话；当前实现恒为 `t`。

```lisp
ycSQLite::Open(":memory:")->isPersistent()
; => t
```

#### isClosed <sub>`method`</sub>

```text
db->isClosed()
=> t / nil
```

返回会话是否已经关闭。

```lisp
db = ycSQLite::Open(":memory:")
db->isClosed()
; => nil
db->close()
db->isClosed()
; => t
```

#### close <sub>`method`</sub>

```text
db->close()
=> t
```

关闭会话；可重复调用。关闭后再查询或执行以 `error()` 中断。

```lisp
db = ycSQLite::Open(":memory:")
db->close()
db->close()
; => t
```

#### query <sub>`method`</sub>

```text
db->query(
    t_sql
    [ ?params l_params ]
)
=> ycSQLite::Result
```

执行只读查询。SQL 必须是单条语句，且以 `SELECT`、`WITH` 或 `VALUES` 开头；前导注释允许出现，分号可以出现在字符串字面量或注释里，但第一条语句结束后不能再有其他语句。违反时以 `error()` 中断，后续语句不会执行。`WITH` 与 `VALUES` 需要客户端支持；旧客户端会直接返回语法错误。结果列名与行内容会被完整返回。

```lisp
; 建表：a 是整数列，b 是文本列
db = ycSQLite::Open(":memory:")
db->execute("create table t(a integer, b text);")

; 插入一行；两个 ? 依次绑定 1 和 "x"
db->execute("insert into t values (?, ?);" ?params list(1 "x"))

; 查询结果按行返回，每行是值列表
db->query("select a, b from t;")->toList()
; => ((1 "x"))

; 多语句会被拒绝，后面的 DELETE 不会执行
db->query("select 1; delete from t;")
; => 以 error() 中断（只允许单条查询语句）
db->close()
```

#### execute <sub>`method`</sub>

```text
db->execute(
    t_sql
    [ ?params l_params ]
)
=> ycSQLite::Result
```

执行一条或多条 DDL/DML 并返回本次调用改动的数据行数与最近插入 rowid。`t_sql` 可以包含多条以分号分隔的语句；`changes` 是这些语句改动的数据行总数，`CREATE`、`DROP`、`ALTER`、`PRAGMA` 等非 DML 语句与没有匹配行的 DML 不计数。`lastInsertRowid` 是会话中最近一次 `INSERT` 生成的 rowid。SQL 不得包含独占行首的客户端点命令；违反时以 `error()` 中断，语句不会发送。字符串、标识符与注释内的 `.` 不受限制。参数数量或类型不匹配、SQL 执行失败时以 `error()` 中断；会话累计改动数超出 fixnum 范围时同样以 `error()` 中断，重新打开数据库可重置计数。

```lisp
db = ycSQLite::Open(":memory:")

; 建表：id 是自增主键，name 是文本列
db->execute("create table t(id integer primary key, name text);")

; 插入一行；? 绑定字符串 "a"
res = db->execute("insert into t(name) values (?);" ?params list("a"))
res->changes()
; => 1（影响一行）
res->lastInsertRowid()
; => 1（新行的 id）

; 先插入再建表：建表不改变数据行数
db->execute("create table log(msg text);")->changes()
; => 0
db->close()
```

#### executeScript <sub>`method`</sub>

```text
db->executeScript(t_sql)
=> t
```

执行多语句脚本，不返回结果集。SQL 不得包含独占行首的客户端点命令；违反时以 `error()` 中断，脚本不会发送。字符串、标识符与注释内的 `.` 不受限制。

```lisp
db = ycSQLite::Open(":memory:")

; 一次执行多条 SQL：先建表，再插入一行
db->executeScript("create table t(a); insert into t values (1);")

; 统计表中记录数
db->query("select count(*) from t;")->toList()
; => ((1))
db->close()
```

#### transaction <sub>`method`</sub>

```text
db->transaction(g_body)
=> any
```

在事务中调用回调。回调接收当前 `Database`；返回值为回调结果。回调抛错时回滚并重新抛出错误；嵌套调用使用保存点。

```lisp
db = ycSQLite::Open(":memory:")
db->execute("create table t(a);")

; 回调内的两条插入属于同一个事务：
; 回调正常结束则一起提交，回调报错则整体回滚
db->transaction(lambda((d)
    d->execute("insert into t values (1);")
    d->execute("insert into t values (2);")
    2
))
; => 2
db->close()
```

#### tables <sub>`method`</sub>

```text
db->tables()
=> list[str]
```

返回用户表名列表，不包含视图与 SQLite 内部表。

```lisp
db = ycSQLite::Open(":memory:")

; 建表后查询当前数据库中的用户表
db->execute("create table t(a);")
db->tables()
; => ("t")
db->close()
```

#### columns <sub>`method`</sub>

```text
db->columns(t_table)
=> ycSQLite::Result
```

返回表的 `PRAGMA table_info` 结果；列名与值均为字符串。表不存在时以 `error()` 中断。

```lisp
db = ycSQLite::Open(":memory:")

; 建表：id 是整数主键，name 是文本列
db->execute("create table t(id integer primary key, name text);")

; 每行描述一列；取第一行（id 列）的 name 字段
car(db->columns("t")->rows())->get("name")
; => "id"
db->close()
```

#### schema <sub>`method`</sub>

```text
db->schema(
    [ ?table t_table ]
)
=> str / nil
```

返回指定表/视图的 `sqlite_master.sql`；省略 `?table` 时按名称顺序拼接全部表的 DDL。目标不存在时返回 `nil`。

```lisp
db = ycSQLite::Open(":memory:")

; 建表后读取它的 CREATE TABLE 语句
db->execute("create table t(a);")
db->schema(?table "t")
; => "CREATE TABLE t(a)"
db->close()
```

#### exists <sub>`method`</sub>

```text
db->exists(t_table)
=> t / nil
```

判断表或视图是否存在。

```lisp
db = ycSQLite::Open(":memory:")

; 建表后判断表和缺失名称是否存在
db->execute("create table t(a);")
db->exists("t")
; => t
db->exists("missing")
; => nil
db->close()
```

### ycSQLite::Result <sub>`class`</sub>

查询或执行返回的不可变结果集。

**方法**

> 必须使用 `->` 符号调用方法。

#### columns <sub>`method`</sub>

```text
r->columns()
=> list[str] / nil
```

返回列名；`execute` 结果没有列名时返回 `nil`。

```lisp
db = ycSQLite::Open(":memory:")
; 查询返回一列 a
db->query("select 1 as a;")->columns()
; => ("a")
db->close()
```

#### rows <sub>`method`</sub>

```text
r->rows()
=> list[ycSQLite::Row]
```

返回行对象列表浅拷贝。

```lisp
db = ycSQLite::Open(":memory:")
; 结果中的每一行是 ycSQLite::Row 对象
db->query("select 1 as a;")->rows()
; => (<ycSQLite::Row columns=1>)
db->close()
```

#### rowCount <sub>`method`</sub>

```text
r->rowCount()
=> int
```

返回数据行数。

```lisp
db = ycSQLite::Open(":memory:")
; 条件永假，返回 0 行
db->query("select 1 where 0;")->rowCount()
; => 0
db->close()
```

#### isEmpty <sub>`method`</sub>

```text
r->isEmpty()
=> t / nil
```

判断结果是否没有数据行。

```lisp
db = ycSQLite::Open(":memory:")
; 条件永假，结果为空
db->query("select 1 where 0;")->isEmpty()
; => t
db->close()
```

#### changes <sub>`method`</sub>

```text
r->changes()
=> int
```

返回所属 `execute` 调用改动的数据行总数；一次调用包含多条语句时累加各语句的结果，非 DML 语句不计数。触发器与级联外键产生的数据行改动也计入。该值来自会话的改动计数，事务中随后回滚的改动同样计入，因此它表示执行过的 DML 行数，而不是最终落盘的行数。会话累计改动数超出 fixnum 表示范围时无法计算差值，以 `error()` 中断。查询结果上的 `changes` 恒为 `0`。

```lisp
db = ycSQLite::Open(":memory:")
; 建表不会改变数据行数
db->execute("create table t(a);")->changes()
; => 0
db->close()
```

#### lastInsertRowid <sub>`method`</sub>

```text
r->lastInsertRowid()
=> int / str / nil
```

返回会话中最近一次 `INSERT` 生成的 rowid；一次 `execute` 包含多条语句时，取最后一条插入语句的值。超出 fixnum 范围时返回十进制字符串。

```lisp
db = ycSQLite::Open(":memory:")
; 插入后读取新行的 id
db->execute("create table t(id integer primary key);")
db->execute("insert into t default values;")->lastInsertRowid()
; => 1
db->close()
```

#### toList <sub>`method`</sub>

```text
r->toList()
=> list[list]
```

返回每行的值列表。

```lisp
db = ycSQLite::Open(":memory:")
; 两列一行，结果是一个二元素列表组成的列表
db->query("select 1 as a, 2 as b;")->toList()
; => ((1 2))
db->close()
```

### ycSQLite::Row <sub>`class`</sub>

结果行。实例由查询结果构造。

**方法**

> 必须使用 `->` 符号调用方法。

#### size <sub>`method`</sub>

```text
row->size()
=> int
```

返回列数。

```lisp
db = ycSQLite::Open(":memory:")
; 查询返回两列
car(db->query("select 1 as a, 2 as b;")->rows())->size()
; => 2
db->close()
```

#### get <sub>`method`</sub>

```text
row->get(g_key)
=> any
```

按 0-based 索引或列名读取值；索引越界或列名不存在时以 `error()` 中断。

```lisp
db = ycSQLite::Open(":memory:")
; 按索引 0 和列名 b 读取同一行
row = car(db->query("select 1 as a, 'x' as b;")->rows())
row->get(0)
; => 1
row->get("b")
; => "x"
db->close()
```

#### has <sub>`method`</sub>

```text
row->has(g_key)
=> t / nil
```

判断索引或列名是否存在。

```lisp
db = ycSQLite::Open(":memory:")
; 判断列名 a 是否存在
row = car(db->query("select 1 as a;")->rows())
row->has("a")
; => t
row->has("missing")
; => nil
db->close()
```

#### toList <sub>`method`</sub>

```text
row->toList()
=> list
```

按列顺序返回值列表。

```lisp
db = ycSQLite::Open(":memory:")
; 按列顺序取值
car(db->query("select 1 as a, 'x' as b;")->rows())->toList()
; => (1 "x")
db->close()
```

#### toAlist <sub>`method`</sub>

```text
row->toAlist()
=> list
```

返回 `(("列名" 值) ...)` 形式的关联列表；每一项是列名与值的二元列表。

```lisp
db = ycSQLite::Open(":memory:")
; 关联列表便于按列名查找
car(db->query("select 1 as a, 'x' as b;")->rows())->toAlist()
; => (("a" 1) ("b" "x"))
db->close()
```

### ycSQLite::Blob <sub>`function`</sub> <sub>`class`</sub>

```text
ycSQLite::Blob(
    t_hex
)
=> ycSQLite::Blob
```

**描述**

由十六进制文本构造不可变 BLOB。文本长度必须为偶数且只含十六进制字符；非法输入以 `error()` 中断。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| t_hex | `str` |  | 十六进制文本 |

**返回值**

`ycSQLite::Blob` — 新的 BLOB 对象。

**方法**

> 必须使用 `->` 符号调用方法。

#### hex <sub>`method`</sub>

```text
b->hex()
=> str
```

返回十六进制文本。

```lisp
ycSQLite::Blob("00ff")->hex()
; => "00ff"
```

#### size <sub>`method`</sub>

```text
b->size()
=> int
```

返回字节数。

```lisp
ycSQLite::Blob("00ff")->size()
; => 2
```

#### toList <sub>`method`</sub>

```text
b->toList()
=> list[int]
```

返回字节值列表。

```lisp
ycSQLite::Blob("00ff")->toList()
; => (0 255)
```

### ycSQLite::Client <sub>`function`</sub> <sub>`class`</sub>

```text
ycSQLite::Client(
    [ ?command l_command ]
    [ ?executable t_executable ]
    [ ?unsetEnv l_unsetEnv ]
    [ ?timeout n_timeout ]
)
=> ycSQLite::Client
```

**描述**

构造一个尚未验证的客户端配置。`?command` 是完整命令列表；`?executable` 是单个可执行文件路径或命令名，二者互斥。`?unsetEnv` 指定从子进程环境中移除的变量名。客户端验证由 `validate()` 完成。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| ?command l_command | `list[str] / nil` | `nil` | 完整基础命令列表 |
| ?executable t_executable | `str / nil` | `"sqlite3"` | 客户端路径或命令名 |
| ?unsetEnv l_unsetEnv | `list[str] / nil` | `nil` | 需要移除的环境变量名 |
| ?timeout n_timeout | `int / nil` | `nil` | 验证与会话等待秒数 |

**返回值**

`ycSQLite::Client` — 未验证的客户端对象。

**方法**

> 必须使用 `->` 符号调用方法。

#### command <sub>`method`</sub>

```text
c->command()
=> list[str]
```

返回基础命令列表的浅拷贝。

```lisp
ycSQLite::Client(?executable "sqlite3" ?unsetEnv list("LD_LIBRARY_PATH"))->command()
; => ("env" "-u" "LD_LIBRARY_PATH" "sqlite3")
```

#### timeout <sub>`method`</sub>

```text
c->timeout()
=> int / nil
```

返回构造时设置的等待秒数。

```lisp
ycSQLite::Client(?timeout 10)->timeout()
; => 10
```

#### validate <sub>`method`</sub>

```text
c->validate()
=> ycSQLite::Client
```

执行版本、内存数据库、`stdbuf` 与会话往返验证。失败时只记录诊断，不抛错；重复调用复用已有结果。

```lisp
c = ycSQLite::Client(?executable "sqlite3" ?unsetEnv list("LD_LIBRARY_PATH"))
c->validate()->isValid()
; => t
```

#### isValid <sub>`method`</sub>

```text
c->isValid()
=> t / nil
```

返回客户端是否已经验证通过。

```lisp
c = ycSQLite::Client(?executable "sqlite3" ?unsetEnv list("LD_LIBRARY_PATH"))
c->isValid()
; => nil
c->validate()
c->isValid()
; => t
```

#### version <sub>`method`</sub>

```text
c->version()
=> str / nil
```

返回客户端报告的 SQLite 版本串。

```lisp
ycSQLite::Client(?executable "sqlite3" ?unsetEnv list("LD_LIBRARY_PATH"))->validate()->version()
; => "3.x.y"（实际值取决于客户端）
```

#### versionTuple <sub>`method`</sub>

```text
c->versionTuple()
=> list[int] / nil
```

返回主版本、次版本与补丁版本。只取版本串的前三段：多出的第四段（如 `3.45.1.1`）与后缀（如 `3.50.0-prelease`）会被忽略。

```lisp
ycSQLite::Client(?executable "sqlite3" ?unsetEnv list("LD_LIBRARY_PATH"))->validate()->versionTuple()
; => (3 7 17)（示例值）
```

#### features <sub>`method`</sub>

```text
c->features()
=> list[sym]
```

返回验证得到的能力符号；典型值包括 `'session`、`'memory` 与 `'csv`。

```lisp
ycSQLite::Client(?executable "sqlite3" ?unsetEnv list("LD_LIBRARY_PATH"))->validate()->features()
; => (session memory csv)（示例值）
```

#### supports <sub>`method`</sub>

```text
c->supports(s_feature)
=> t / nil
```

查询是否支持指定能力。

```lisp
c = ycSQLite::Client(?executable "sqlite3" ?unsetEnv list("LD_LIBRARY_PATH"))->validate()
c->supports('session)
; => t
```

#### diagnostics <sub>`method`</sub>

```text
c->diagnostics()
=> str
```

返回最近一次验证的诊断；成功时为空串。

```lisp
ycSQLite::Client(?executable "/no/such/sqlite3")->validate()->diagnostics()
; => 非空诊断文本
```

#### sessionCommand <sub>`method`</sub>

```text
c->sessionCommand(t_path)
=> list[str]
```

返回长驻会话的启动命令，供高级调用方检查或自定义启动方式。

```lisp
ycSQLite::Client(?executable "sqlite3")
    ->sessionCommand("./app.sqlite")
; => ("stdbuf" "-oL" "-eL" "sqlite3" "-batch" "./app.sqlite")（示例值）
```

### ycSQLite::Configure <sub>`function`</sub>

```text
ycSQLite::Configure(
    [ ?client g_client ]
    [ ?command l_command ]
    [ ?executable t_executable ]
    [ ?unsetEnv l_unsetEnv ]
    [ ?timeout n_timeout ]
)
=> ycSQLite::Client
```

**描述**

设置并验证全局默认客户端。`?client` 直接使用已构造对象；其余参数创建新客户端。未提供任何参数时使用环境变量或默认客户端配置。验证失败时以 `error()` 中断。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| ?client g_client | `ycSQLite::Client / nil` | `nil` | 已构造客户端 |
| ?command l_command | `list[str] / nil` | `nil` | 完整基础命令列表 |
| ?executable t_executable | `str / nil` | `nil` | 客户端路径或命令名 |
| ?unsetEnv l_unsetEnv | `list[str] / nil` | `nil` | 需要移除的环境变量名 |
| ?timeout n_timeout | `int / nil` | `nil` | 验证与会话等待秒数 |

**返回值**

`ycSQLite::Client` — 已设置并验证的全局客户端。

**例程**

```lisp
ycSQLite::Configure(
    ?executable "sqlite3"
    ?unsetEnv list("LD_LIBRARY_PATH")
)
; => <ycSQLite::Client valid=t version="3.x.y">
```

### ycSQLite::DefaultClient <sub>`function`</sub>

```text
ycSQLite::DefaultClient()
=> ycSQLite::Client
```

**描述**

返回全局默认客户端。首次调用时按“显式配置、`YC_SKILL_OO_SQLITE_CLIENT`、默认客户端配置”的顺序解析并缓存。后续 `Open` 与 SQL 调用直接复用，不需要再次指定客户端。

**参数**

无。

**返回值**

`ycSQLite::Client` — 默认客户端对象。

**例程**

```lisp
ycSQLite::Configure(
    ?executable "sqlite3"
    ?unsetEnv list("LD_LIBRARY_PATH")
)
ycSQLite::DefaultClient()->command()
; => ("env" "-u" "LD_LIBRARY_PATH" "sqlite3")
```

### ycSQLite::ProbeClient <sub>`function`</sub>

```text
ycSQLite::ProbeClient(
    [ ?command l_command ]
    [ ?executable t_executable ]
    [ ?unsetEnv l_unsetEnv ]
    [ ?timeout n_timeout ]
)
=> ycSQLite::Client
```

**描述**

构造并验证客户端，但不修改全局默认配置。适合在正式使用前检查环境。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| ?command l_command | `list[str] / nil` | `nil` | 完整基础命令列表 |
| ?executable t_executable | `str / nil` | `"sqlite3"` | 客户端路径或命令名 |
| ?unsetEnv l_unsetEnv | `list[str] / nil` | `nil` | 需要移除的环境变量名 |
| ?timeout n_timeout | `int / nil` | `nil` | 验证等待秒数 |

**返回值**

`ycSQLite::Client` — 验证结果；失败原因见 `diagnostics()`。

**例程**

```lisp
info = ycSQLite::ProbeClient(
    ?executable "sqlite3"
    ?unsetEnv list("LD_LIBRARY_PATH")
)
info->isValid()
; => t
info->version()
; => "3.x.y"
```

## 数据库概念

| 概念 | 含义 |
| --- | --- |
| 数据库文件 | 一个 `.sqlite` 或 `.db` 文件；`ycSQLite::Open` 打开它，文件不存在时创建 |
| 表 | 由若干列组成的二维数据集合，类似一张带固定列名的表 |
| 行 | 表中的一条记录 |
| 列 | 记录中的一个字段，例如 `id`、`name` |
| 外键 | 一个表中的列引用另一个表的主键；是否校验由会话的外键开关决定，`Open` 默认开启 |
| SQL | 操作数据库的语句；建表、插入、查询、更新、删除都通过 SQL 完成 |

+ `query` 用于读取数据，SQL 通常以 `SELECT` 开头；`execute` 用于建表、插入、更新和删除。
+ `?` 是参数占位符，按出现顺序与 `?params` 列表对应，不需要把值直接拼进 SQL 文本。
+ 事务把一组修改当作一个整体：全部成功才提交，中途失败则撤销。
+ `BLOB` 用于保存二进制数据，模块以十六进制文本表示。

[返回首页](../../README.md)
