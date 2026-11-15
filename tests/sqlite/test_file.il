let((tmp path db)
    tmp = "ycSQLiteFileTmpTest"
    path = strcat(tmp "/a.sqlite")
    system(strcat("rm -rf " tmp " && mkdir -p " tmp))
    db = ycSQLite::Open(path ?busyTimeout 1000)
    db->execute("create table t(id integer primary key, name text);")
    db->execute("insert into t(name) values ('persist');")
    _Assert(!db->isClosed()
        "file: opened database is active")
    db->close()
    _Assert(db->isClosed()
        "file: close marks file database closed")

    db = ycSQLite::Open(path)
    _Assert(car(db->query("select count(*) from t;")->rows())->get(0) == 1
        "file: data persists across reopen")
    _Assert(index(db->schema(?table "t") "CREATE TABLE t") != nil
        "file: schema persists across reopen")
    _Assert(db->exists("t")
        "file: table exists after reopen")
    db->close()
    system(strcat("rm -rf " tmp))
)

_TestChildDone = t

; END
