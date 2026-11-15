let((db wrapper c r row alist seq blob emptyResult count)
    wrapper = strcat(_TestDir "../../libs/sqlite/src/sqlite3.sh")

    c = ycSQLite::Client(?timeout 3)
    _Assert(c->timeout() == 3
        "edges: client timeout accessor")
    _AssertSameStrs(c->command() list("sqlite3")
        "edges: client default command")
    _Assert(c->features() == nil
        "edges: client features are empty before validation")
    _AssertSameStrs(
        c->sessionCommand(":memory:")
        list("stdbuf" "-oL" "-eL" "sqlite3" "-batch" ":memory:")
        "edges: sessionCommand returns the expected command"
    )
    _AssertError(lambda(() c->sessionCommand(""))
        "edges: sessionCommand rejects an empty path")
    _AssertError(lambda(() ycSQLite::Client(?command list("sh") ?executable "sqlite3"))
        "edges: command and executable are mutually exclusive")
    _AssertError(lambda(() ycSQLite::Client(?executable 1))
        "edges: executable must be a string")
    _AssertError(lambda(() ycSQLite::Client(?unsetEnv "LD_LIBRARY_PATH"))
        "edges: unsetEnv must be a list")
    _AssertError(lambda(() ycSQLite::Client(?unsetEnv list(1)))
        "edges: unsetEnv elements must be strings")
    _AssertError(lambda(() ycSQLite::Client(?timeout "1"))
        "edges: timeout must be an integer")
    _Assert(ycSQLite::Configure(?client ycSQLite::Client(?command list("sh" wrapper)))->isValid()
        "edges: Configure accepts an explicit client")

    db = ycSQLite::Open(":memory:")
    _Assert(db->path() == ":memory:"
        "edges: database path accessor")
    _Assert(className(db->client()) == 'ycSQLite::Client
        "edges: database client accessor")
    _Assert(db->isPersistent()
        "edges: database reports a persistent session")
    _Assert(db->tables() == nil && db->schema() == nil
        "edges: empty database has no user schema")

    db->execute("create table t(id integer primary key, name text);")
    _Assert(member("t" db->tables()) != nil
        "edges: tables lists a created table")
    r = db->execute("insert into t(name) values ('a');")
    _Assert(r->changes() == 1
        "edges: execute reports insert changes")
    r = db->execute("update t set name = 'b' where name = 'a';")
    _Assert(r->changes() == 1
        "edges: execute reports update changes")
    r = db->execute("delete from t;")
    _Assert(r->changes() == 1
        "edges: execute reports delete changes")

    _Assert(car(db->query("select 1 as \"?\", ? as x;"
                ?params list(2))->rows())->get(1) == 2
        "edges: parameter scanner ignores double-quoted question marks")
    _Assert(car(db->query("select 1 as `?`, ? as x;"
                ?params list(3))->rows())->get(1) == 3
        "edges: parameter scanner ignores backtick-quoted question marks")
    _Assert(car(db->query("select 1 as [?], ? as x;"
                ?params list(4))->rows())->get(1) == 4
        "edges: parameter scanner ignores bracket-quoted question marks")
    _Assert(car(db->query("select ? as x /* ? */;"
                ?params list(5))->rows())->get(0) == 5
        "edges: parameter scanner ignores block comments")
    _Assert(car(db->query("select 'a''?b' as s, ? as x;"
                ?params list(6))->rows())->get(1) == 6
        "edges: parameter scanner handles escaped quotes")
    _AssertError(lambda(() db->query("select 'unterminated;"))
        "edges: unterminated single quote errors")
    _AssertError(lambda(() db->query("select 1 /* unterminated;"))
        "edges: unterminated block comment errors")
    _AssertError(lambda(() db->query("select 1;" ?params list(1)))
        "edges: extra parameters error")

    db->execute("create table n(v);")
    db->execute("insert into n values (-2147483647), (2147483647), (-2147483649), (-9223372036854775808);")
    r = db->query("select v from n order by rowid;")
    _Assert(car(r->rows())->get(0) == -2147483647
        "edges: lower 32-bit integer stays a fixnum")
    _Assert(cadr(r->rows())->get(0) == 2147483647
        "edges: upper 32-bit integer stays a fixnum")
    _Assert(caddr(r->rows())->get(0) == "-2147483649"
        "edges: integer below 32-bit range becomes a string")
    _Assert(nth(3 r->rows())->get(0) == "-9223372036854775808"
        "edges: minimum 64-bit integer stays a string")

    db->execute("create table rr(v real);")
    db->execute("insert into rr values (1.25);")
    _Assert(car(db->query("select v from rr;")->rows())->get(0) == 1.25
        "edges: exact real value stays a flonum")

    blob = ycSQLite::Blob("")
    _Assert(blob->hex() == "" && blob->size() == 0 && blob->toList() == nil
        "edges: empty BLOB exposes empty values")
    _AssertError(lambda(() ycSQLite::Blob(1))
        "edges: BLOB input must be a string")

    row = ycSQLite::Row(list(10 "x") list("n" "s"))
    _Assert(row->size() == 2
        "edges: row size is column count")
    seq = row->toList()
    _Assert(car(seq) == 10 && cadr(seq) == "x"
        "edges: row toList preserves values")
    alist = row->toAlist()
    _Assert(cadr(car(alist)) == 10 && cadr(cadr(alist)) == "x"
        "edges: row toAlist pairs columns with values")
    _AssertError(lambda(() ycSQLite::Row("x" list("a")))
        "edges: row values must be a list")
    _AssertError(lambda(() ycSQLite::Row(list(1) list(2)))
        "edges: row columns must be strings")
    _AssertError(lambda(() ycSQLite::Row(list(1) list("a" "b")))
        "edges: row values and columns must have equal size")

    r = ycSQLite::Result(
        ?columns list("n" "s")
        ?rows list(row)
        ?changes 2
        ?lastInsertRowid 9
    )
    _Assert(r->rowCount() == 1
        "edges: result rowCount")
    _Assert(car(car(r->toList())) == 10 && cadr(car(r->toList())) == "x"
        "edges: result toList preserves row values")
    emptyResult = ycSQLite::Result()
    _Assert(emptyResult->columns() == nil && emptyResult->rows() == nil
        "edges: empty result has no column or row metadata")
    _Assert(emptyResult->rowCount() == 0 && emptyResult->isEmpty()
        "edges: empty result has zero rows")
    _Assert(emptyResult->changes() == 0 && emptyResult->lastInsertRowid() == nil
        "edges: empty result has neutral DML metadata")
    _AssertError(lambda(() ycSQLite::Result(?columns "x"))
        "edges: result columns must be a list")
    _AssertError(lambda(() ycSQLite::Result(?rows list(1)))
        "edges: result rows must be Row objects")
    _AssertError(lambda(() ycSQLite::Result(?changes -1))
        "edges: result changes must be non-negative")

    db->execute("create table tx(id integer primary key, name text);")
    count = db->transaction(lambda((d)
        d->execute("insert into tx(name) values ('outer');")
        d->transaction(lambda((d2)
            d2->execute("insert into tx(name) values ('inner');")
            t
        ))
        car(d->query("select count(*) from tx;")->rows())->get(0)
    ))
    _Assert(count == 2
        "edges: nested transaction callback sees both inserts")
    _Assert(car(db->query("select count(*) from tx;")->rows())->get(0) == 2
        "edges: nested transaction commits the outer savepoint")

    db->execute("create table \"odd name\"(id integer);")
    _Assert(db->exists("odd name")
        "edges: exists handles a quoted table name")
    _Assert(car(db->columns("odd name")->rows())->get("name") == "id"
        "edges: columns handles a quoted table name")
    _Assert(index(db->schema(?table "odd name") "CREATE TABLE") != nil
        "edges: schema handles a quoted table name")

    db->close()
)

_TestChildDone = t

; END
