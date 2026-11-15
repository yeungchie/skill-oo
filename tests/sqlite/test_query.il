let((db result row ins)
    db = ycSQLite::Open(":memory:")
    db->execute("create table t(id integer primary key, name text, val real);")

    ins = db->execute(
        "insert into t(name, val) values (?, ?);"
        ?params list("alpha" 1.5)
    )
    _Assert(ins->changes() == 1
        "query: execute reports one changed row")
    _Assert(ins->lastInsertRowid() == 1
        "query: execute reports last insert rowid")

    result = db->query("select id, name, val from t order by id;")
    _Assert(result->rowCount() == 1
        "query: returns one row")
    _AssertSameStrs(result->columns() list("id" "name" "val")
        "query: returns column names")
    row = car(result->rows())
    _Assert(row->get(0) == 1
        "query: row get accepts a zero-based index")
    _Assert(row->get("name") == "alpha"
        "query: row get accepts a column name")
    _Assert(row->has("val") && !row->has("missing")
        "query: row has distinguishes known and unknown columns")
    _AssertError(lambda(() row->get(99))
        "query: row index out of range errors")
    _AssertError(lambda(() row->get("missing"))
        "query: unknown row column errors")

    _Assert(db->query("select * from t where 0;")->isEmpty()
        "query: empty result is empty")
    _AssertSameStrs(
        db->query("select 1 as a, 2 as a;")->columns()
        list("a" "a:1")
        "query: duplicate columns are renamed by SQLite")

    db->executeScript("insert into t(name) values ('b'); insert into t(name) values ('c');")
    _Assert(car(db->query("select count(*) from t;")->rows())->get(0) == 3
        "query: executeScript runs multiple statements")

    _AssertError(lambda(() db->query("delete from t;"))
        "query: query rejects non-read-only SQL")
    _AssertError(lambda(() db->execute("insert into t(name) values (?);" ?params list()))
        "query: parameter count mismatch errors")
    _AssertError(lambda(() db->execute("insert into t(name) values (?);" ?params list(list(1))))
        "query: unsupported parameter type errors")
    _Assert(car(db->query("select '?' as q, ? as x;" ?params list(7))->rows())->get(0) == "?"
        "query: parameter scanner ignores question marks in strings")
    _Assert(car(db->query("select ? as x -- ?\n;" ?params list(8))->rows())->get(0) == 8
        "query: parameter scanner ignores question marks in comments")

    ; --- single-statement guard ---
    _AssertError(lambda(() db->query("select 1; select 2;"))
        "query: trailing statement is rejected")
    _AssertError(lambda(() db->query("select 1; delete from t;"))
        "query: trailing write statement is rejected")
    _AssertError(lambda(() db->query("select ';' as s; delete from t;"))
        "query: literal semicolon does not hide a second statement")
    _Assert(car(db->query("select count(*) from t;")->rows())->get(0) == 3
        "query: rejected trailing statement did not run")
    _Assert(car(db->query("select ';' as s;")->rows())->get(0) == ";"
        "query: semicolon inside a string literal is allowed")
    _Assert(car(db->query("select 1 as [a;b];")->rows())->get(0) == 1
        "query: semicolon inside a bracket identifier is allowed")
    _Assert(car(db->query("/* note */ select 7 as v;")->rows())->get(0) == 7
        "query: leading comment is allowed")
    _Assert(car(db->query("select 1 -- ;\n;")->rows())->get(0) == 1
        "query: semicolon inside a comment is ignored")
    _Assert(car(db->query("select 9")->rows())->get(0) == 9
        "query: statement terminator is optional")
    _Assert(car(db->query("select 10 -- tail")->rows())->get(0) == 10
        "query: trailing comment without terminator is allowed")
    _Assert(db->execute("create table nosemi(a)")->changes() == 0
        "query: execute accepts a statement without terminator")
    _Assert(db->execute("insert into nosemi values (1)")->changes() == 1
        "query: execute inserts without terminator")
    _Assert(db->executeScript("create table nosemi2(b)") == t
        "query: executeScript accepts a trailing statement without terminator")

    ; --- execute changes ---
    _Assert(db->execute("update t set name = name;")->changes() == 3
        "query: update reports all changed rows")
    _Assert(db->execute("create table t2(x);")->changes() == 0
        "query: DDL reports zero changes after DML")
    _Assert(db->execute("delete from t where 0;")->changes() == 0
        "query: zero-row DML reports zero changes")
    _Assert(db->execute("delete from t where id = 1;")->changes() == 1
        "query: delete reports one changed row")
    _Assert(db->execute("create table t3(y);")->changes() == 0
        "query: DDL keeps reporting zero changes")
    db->close()
)

_TestChildDone = t

; END
