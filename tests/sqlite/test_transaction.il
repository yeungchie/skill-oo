let((db n rollback nested)
    db = ycSQLite::Open(":memory:")
    db->execute("create table t(id integer primary key, name text);")

    n = db->transaction(lambda((d)
        d->execute("insert into t(name) values ('commit');")
        car(d->query("select count(*) from t;")->rows())->get(0)
    ))
    _Assert(n == 1
        "transaction: callback sees its own insert")
    _Assert(car(db->query("select count(*) from t;")->rows())->get(0) == 1
        "transaction: successful transaction commits")

    rollback = errset(db->transaction(lambda((d)
        d->execute("insert into t(name) values ('rollback');")
        error("forced rollback")
    ) nil))
    _Assert(!rollback
        "transaction: callback error is rethrown")
    _Assert(car(db->query("select count(*) from t;")->rows())->get(0) == 1
        "transaction: failed transaction rolls back")

    nested = db->transaction(lambda((d)
        d->execute("insert into t(name) values ('outer');")
        errset(d->transaction(lambda((d2)
            d2->execute("insert into t(name) values ('inner');")
            error("inner rollback")
        ) nil))
        car(d->query("select count(*) from t;")->rows())->get(0)
    ))
    _Assert(nested == 2
        "transaction: nested rollback keeps outer insert")
    _Assert(car(db->query("select count(*) from t;")->rows())->get(0) == 2
        "transaction: outer savepoint commits")

    _Assert(db->transaction(lambda((d) nil)) == nil
        "transaction: nil callback result is preserved")
    _AssertError(lambda(() db->transaction(1))
        "transaction: non-function callback errors")
    db->close()
)

_TestChildDone = t

; END
