let((db res before)
    db = ycSQLite::Open(":memory:")
    db->execute("create table t(id integer primary key, name text not null);")
    db->execute("create table u(id integer primary key, tag text);")

    ; --- changes accumulation ---
    res = db->execute(strcat(
        "insert into t(id, name) values (1, 'a');"
        "insert into t(id, name) values (2, 'b');"
        "update t set name = name where id = 1;"
        "delete from t where id = 2;"
    ))
    _Assert(res->changes() == 4
        "multistatement: changes sum inserts, update and delete")
    _Assert(car(car(db->query("select count(*) from t;")->toList())) == 1
        "multistatement: all four statements ran")

    res = db->execute(strcat(
        "insert into t(id, name) values (3, 'c');"
        "create table d(x);"
        "delete from t where 0;"
    ))
    _Assert(res->changes() == 1
        "multistatement: DDL and zero-row DML do not reset earlier changes")
    _Assert(db->exists("d")
        "multistatement: DDL between DML statements took effect")

    _Assert(db->execute(
        "insert or ignore into t(id, name) values (1, 'dup');"
        )->changes() == 0
        "multistatement: ignored duplicate reports zero changes")
    _Assert(db->execute(strcat(
        "insert or ignore into t(id, name) values (1, 'dup');"
        "insert into t(id, name) values (4, 'e');"
        ))->changes() == 1
        "multistatement: ignored duplicate does not hide a later insert")
    _Assert(db->execute("create table e(x);")->changes() == 0
        "multistatement: DDL-only call reports zero changes")
    _Assert(db->execute("update t set name = name where 0;")->changes() == 0
        "multistatement: zero-row update reports zero changes")
    _Assert(db->execute(strcat(
        "insert into t(id, name) values (5, 'f');"
        "delete from t where id = 5;"
        ))->changes() == 2
        "multistatement: insert followed by delete sums two changes")

    ; --- lastInsertRowid ---
    res = db->execute(strcat(
        "insert into u(id, tag) values (10, 'a');"
        "insert into u(id, tag) values (20, 'b');"
    ))
    _Assert(res->lastInsertRowid() == 20
        "multistatement: lastInsertRowid is the last inserted row")
    res = db->execute(strcat(
        "update u set tag = tag;"
        "delete from u where id = 10;"
    ))
    _Assert(res->lastInsertRowid() == 20
        "multistatement: update and delete keep the previous lastInsertRowid")
    _Assert(db->execute(
        "insert into u(id, tag) values (30, 'c');"
        )->lastInsertRowid() == 30
        "multistatement: a later insert advances lastInsertRowid")
    _Assert(db->execute(
        "insert or ignore into u(id, tag) values (30, 'dup');"
        )->lastInsertRowid() == 30
        "multistatement: ignored insert keeps lastInsertRowid")

    ; --- dot command rejection ---
    before = car(car(db->query("select count(*) from t;")->toList()))
    _AssertErrorMsg(lambda(() db->execute(strcat(
            "insert into t(id, name) values (6, 'x');\n"
            ".quit"
        )))
        "dot commands are not allowed"
        "multistatement: execute rejects a line-leading dot command")
    _Assert(car(car(db->query("select count(*) from t;")->toList())) == before
        "multistatement: rejected execute did not run the earlier insert")
    _AssertErrorMsg(lambda(() db->executeScript(strcat(
            "insert into t(id, name) values (7, 'y');\n"
            ".shell echo x"
        )))
        "dot commands are not allowed"
        "multistatement: executeScript rejects a line-leading dot command")
    _Assert(car(car(db->query("select count(*) from t;")->toList())) == before
        "multistatement: rejected script did not run the earlier insert")
    _Assert(db->execute(
        "insert into t(id, name) values (8, '.quit');"
        )->changes() == 1
        "multistatement: dot text inside a literal is allowed")
    _Assert(db->execute(
        "insert into t(id, name) values (9, 'z'); -- .quit"
        )->changes() == 1
        "multistatement: dot text inside a trailing comment is allowed")

    ; --- mid-script syntax error ---
    ; 三条语句必须保持在同一行：sqlite3 客户端按行处理输入，
    ; 同一行内遇到语法错误会停止执行该行剩余部分；拆成多行时后续语句仍会执行。
    _AssertErrorMsg(lambda(() db->execute(strcat(
            "insert into t(id, name) values (10, 'x');"
            "bogus;"
            "insert into t(id, name) values (11, 'y');"
        )))
        "syntax error"
        "multistatement: execute reports a mid-script syntax error")
    _Assert(db->query("select 1 from t where id = 10;")->rowCount() == 1
        "multistatement: execute kept the statement before the error")
    _Assert(db->query("select 1 from t where id = 11;")->rowCount() == 0
        "multistatement: execute stopped at the syntax error")
    _Assert(car(car(db->query("select last_insert_rowid();")->toList())) == 10
        "multistatement: lastInsertRowid reflects the statement before the error")
    _Assert(db->execute(
        "insert into t(id, name) values (12, 'after');"
        )->changes() == 1
        "multistatement: session stays usable after a syntax error")

    _AssertErrorMsg(lambda(() db->executeScript(strcat(
            "insert into t(id, name) values (13, 'x');"
            "bogus;"
            "insert into t(id, name) values (14, 'y');"
        )))
        "syntax error"
        "multistatement: executeScript reports a mid-script syntax error")
    _Assert(db->query("select 1 from t where id = 13;")->rowCount() == 1
        "multistatement: script kept the statement before the error")
    _Assert(db->query("select 1 from t where id = 14;")->rowCount() == 0
        "multistatement: script stopped at the syntax error")
    _Assert(db->execute(
        "insert into t(id, name) values (15, 'after');"
        )->changes() == 1
        "multistatement: session stays usable after a script error")

    ; --- missing terminator and trailing comments ---
    _Assert(db->execute(strcat(
        "insert into t(id, name) values (16, 'p');"
        "insert into t(id, name) values (17, 'q')"
        ))->changes() == 2
        "multistatement: final semicolon is optional")
    _Assert(db->execute(
        "insert into t(id, name) values (18, 'r'); -- tail"
        )->changes() == 1
        "multistatement: trailing line comment is allowed")
    _Assert(db->execute(
        "insert into t(id, name) values (19, 's'); /* tail */"
        )->changes() == 1
        "multistatement: trailing block comment is allowed")
    _Assert(db->executeScript(strcat(
        "insert into t(id, name) values (20, 't');"
        "insert into t(id, name) values (21, 'u')"
        )) == t
        "multistatement: executeScript accepts a missing final semicolon")

    db->close()
)

_TestChildDone = t

; END
