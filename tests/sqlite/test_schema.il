let((db cols)
    db = ycSQLite::Open(":memory:")
    db->execute("create table t(id integer primary key, name text);")
    db->execute("create view v as select id from t;")

    _Assert(member("t" db->tables()) != nil
        "schema: tables lists user tables")
    _Assert(member("v" db->tables()) == nil
        "schema: tables excludes views")
    _Assert(db->exists("t")
        "schema: exists finds a table")
    _Assert(db->exists("v")
        "schema: exists finds a view")
    _Assert(!db->exists("missing")
        "schema: exists rejects a missing name")
    cols = db->columns("t")
    _AssertSameStrs(cols->columns()
        list("cid" "name" "type" "notnull" "dflt_value" "pk")
        "schema: columns returns PRAGMA table_info shape")
    _Assert(car(cols->rows())->get("name") == "id"
        "schema: columns exposes names")
    _Assert(index(db->schema(?table "t") "CREATE TABLE t") != nil
        "schema: schema returns CREATE TABLE text")
    _Assert(index(db->schema(?table "v") "CREATE VIEW v") != nil
        "schema: schema returns CREATE VIEW text")
    _Assert(index(db->schema() "CREATE TABLE t") != nil
        "schema: schema without table returns all DDL")
    _Assert(db->schema(?table "missing") == nil
        "schema: missing table returns nil")
    _AssertError(lambda(() db->columns("missing"))
        "schema: columns on missing table errors")
    db->close()
)

_TestChildDone = t

; END
