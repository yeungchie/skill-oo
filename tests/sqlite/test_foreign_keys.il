let((db n)
    ; 默认开启：合法引用通过，孤儿行被拒绝，级联删除生效。
    db = ycSQLite::Open(":memory:")
    db->execute("create table parent(id integer primary key);")
    db->execute("create table child(id integer primary key, pid integer references parent(id) on delete cascade);")
    db->execute("insert into parent(id) values (1);")
    n = db->execute("insert into child(pid) values (1);")->changes()
    _Assert(n == 1
        "foreign keys: default session accepts a valid reference")
    _AssertErrorMsg(lambda(() db->execute("insert into child(pid) values (2);"))
        "constraint failed"
        "foreign keys: default session rejects an orphan row")
    db->execute("delete from parent where id = 1;")
    _Assert(car(db->query("select count(*) from child;")->rows())->get(0) == 0
        "foreign keys: default session applies on delete cascade")
    db->close()

    ; 显式 nil：关闭外键校验，也不执行级联动作。
    db = ycSQLite::Open(":memory:" ?foreignKeys nil)
    db->execute("create table parent(id integer primary key);")
    db->execute("create table child(id integer primary key, pid integer references parent(id) on delete cascade);")
    db->execute("insert into parent(id) values (1);")
    n = db->execute("insert into child(pid) values (2);")->changes()
    _Assert(n == 1
        "foreign keys: explicit nil accepts an orphan row")
    db->execute("delete from parent where id = 1;")
    _Assert(car(db->query("select count(*) from child;")->rows())->get(0) == 1
        "foreign keys: explicit nil does not cascade")
    db->close()

    ; 显式 t：开启外键校验。
    db = ycSQLite::Open(":memory:" ?foreignKeys t)
    db->execute("create table parent(id integer primary key);")
    db->execute("create table child(pid integer references parent(id));")
    _AssertErrorMsg(lambda(() db->execute("insert into child(pid) values (1);"))
        "constraint failed"
        "foreign keys: explicit t rejects an orphan row")
    db->close()

    ; 显式传入共享缺省标记：与省略参数相同。
    db = ycSQLite::Open(":memory:" ?foreignKeys 'ycLang:::NoneArg)
    db->execute("create table parent(id integer primary key);")
    db->execute("create table child(pid integer references parent(id));")
    _AssertError(lambda(() db->execute("insert into child(pid) values (1);"))
        "foreign keys: NoneArg keeps the default enabled")
    db->close()

    ; 启动选项不是硬锁：会话内仍可用 PRAGMA 改变当前状态。
    db = ycSQLite::Open(":memory:")
    db->execute("create table parent(id integer primary key);")
    db->execute("create table child(pid integer references parent(id));")
    db->execute("pragma foreign_keys = off;")
    _Assert(db->execute("insert into child(pid) values (1);")->changes() == 1
        "foreign keys: session pragma can disable enforcement")
    db->close()

    _AssertErrorMsg(lambda(() ycSQLite::Open(":memory:" ?foreignKeys "yes"))
        "ycSQLite::Open: ?foreignKeys must be t or nil"
        "foreign keys: non-boolean string is rejected")
    _AssertErrorMsg(lambda(() ycSQLite::Open(":memory:" ?foreignKeys 1))
        "ycSQLite::Open: ?foreignKeys must be t or nil"
        "foreign keys: non-boolean integer is rejected")
)

_TestChildDone = t

; END
