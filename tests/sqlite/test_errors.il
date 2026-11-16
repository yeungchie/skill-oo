let((db)
    db = ycSQLite::Open(":memory:")
    db->execute("create table t(id integer primary key, name text unique);")
    db->execute("insert into t(name) values ('a');")

    _AssertErrorMsg(lambda(() db->query("select * from missing;"))
        "no such table"
        "errors: missing table query names the table")
    _AssertErrorMsg(lambda(() db->query("select from;"))
        "syntax error"
        "errors: syntax error message is reported")
    let((res msg)
        res = errset(db->execute("insert into t(name) values ('a');") nil)
        when(!res
            msg = car(car(cdr(cdr(cdr(cdr(errset.errset))))))
        )
        _Assert(!res && msg && index(lowerCase(msg) "unique")
            "errors: constraint violation message reports the unique failure")
    )
    _AssertErrorMsg(lambda(() db->execute("select * from missing;"))
        "no such table"
        "errors: execute reports the SQL error reason")
    _Assert(db->execute("select 'Error: fake' as x;")->changes() == 0
        "errors: user output that looks like an error is not treated as one")
    _AssertErrorMsg(lambda(() db->execute(".quit"))
        "dot commands are not allowed"
        "errors: execute rejects a dot command")
    _AssertErrorMsg(lambda(() db->execute("select 1;\n.quit"))
        "dot commands are not allowed"
        "errors: execute rejects a dot command after a statement")
    _AssertErrorMsg(lambda(() db->executeScript("select 1;\n.shell echo x"))
        "dot commands are not allowed"
        "errors: executeScript rejects a dot command")
    _Assert(car(db->query("select 5 as v;")->rows())->get(0) == 5
        "errors: rejected dot command keeps the session alive")
    _Assert(car(db->query("select '.quit' as v;")->rows())->get(0) == ".quit"
        "errors: dot command text inside a quoted literal is allowed")
    _Assert(db->executeScript("select 'a\n.quit' as v;") == t
        "errors: dot command text inside a multi-line literal is allowed")
    _Assert(db->executeScript("select 1;\n-- .quit\nselect 2;") == t
        "errors: dot command text inside a line comment is allowed")
    _Assert(db->executeScript("select 1;\n/*\n.quit\n*/\nselect 2;") == t
        "errors: dot command text inside a block comment is allowed")
    _Assert(db->execute("select\n.5;")->changes() == 0
        "errors: a continuation line may start with a dot")
    _Assert(db->execute(
        "create table rb(a); begin; insert into rb values (1); rollback;"
        )->changes() == 1
        "errors: rolled-back changes stay counted")
    _Assert(car(db->query("select count(*) from rb;")->rows())->get(0) == 0
        "errors: rolled-back insert left no rows")
    _Assert(db->execute(
        "create table p2(v text); insert into p2 values (?);"
        ?params list("a\n.quit")
        )->changes() == 1
        "errors: dot text in a bound parameter is allowed")
    _Assert(car(db->query("select v from p2;")->rows())->get(0) == "a\n.quit"
        "errors: bound parameter with a dot line round-trips")
    _AssertError(lambda(() ycSQLite::Open(""))
        "errors: empty database path errors")
    _AssertError(lambda(() ycSQLite::Open(42))
        "errors: non-string database path errors")
    _AssertError(lambda(() ycSQLite::Open(":memory:" ?timeout 0))
        "errors: non-positive timeout errors")
    _AssertError(lambda(() ycSQLite::Open(":memory:" ?busyTimeout -1))
        "errors: negative busyTimeout errors")
    db->close()
    _Assert(db->isClosed()
        "errors: close marks database closed")
    _Assert(db->close()
        "errors: close is idempotent")
    _AssertError(lambda(() db->query("select 1;"))
        "errors: query after close errors")
    _AssertError(lambda(() db->execute("select 1;"))
        "errors: execute after close errors")
    _AssertError(lambda(() db->executeScript("select 1;"))
        "errors: executeScript after close errors")

    ; --- session error line formats ---
    _Assert(ycSQLite::_SessionErrorLine(
        "Error: near line 3: column a is not unique")
        == "Error: near line 3: column a is not unique"
        "errors: legacy client error line is recognized")
    _Assert(ycSQLite::_SessionErrorLine(
        "Runtime error near line 15: UNIQUE constraint failed: t.a (19)")
        == "Runtime error near line 15: UNIQUE constraint failed: t.a (19)"
        "errors: runtime error line is recognized")
    _Assert(ycSQLite::_SessionErrorLine(
        "Parse error near line 1: no such table: missing")
        == "Parse error near line 1: no such table: missing"
        "errors: parse error line is recognized")
    _Assert(ycSQLite::_SessionErrorLine("1|2|3") == nil
        "errors: ordinary output is not an error")
)

_TestChildDone = t

; END
