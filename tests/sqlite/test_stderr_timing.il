let((saved client db res next)
    saved = ycSQLite::DefaultClient()
    client = ycSQLite::Client(
        ?command list("bash" strcat(_TestDir "delay_stderr.sh"))
    )
    ycSQLite::Configure(?client client)
    unwindProtect(
        progn(
            db = ycSQLite::Open(":memory:")
            db->execute("create table t(name text not null);")
            res = errset(db->execute(
                "insert into t(name) values (null);"
            ) nil)
            next = errset(db->query("select 1 as v;") nil)
            _Assert(!res && next
                "stderr timing: delayed diagnostics are still reported by execute")
            db->close()
        )
        ycSQLite::Configure(?client saved)
    )
)

_TestChildDone = t

; END
