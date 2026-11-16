let((saved client db res next msg i stripped)
    stripped = ycSQLite::_StripBarrier(strcat(
        "Error: near line 5: no such function: __YC_SQLITE_BARRIER_1__\n"
        "  select __YC_SQLITE_BARRIER_1__();\n"
        "         ^--- error here\n"
        "Error: near line 6: NOT NULL constraint failed: t.name"
    ))
    _Assert(ycSQLite::_StrPos(stripped "__YC_SQLITE_BARRIER") == nil
        "stderr timing: barrier diagnostics are stripped by prefix")
    _Assert(stripped == strcat(
            "         ^--- error here\n"
            "Error: near line 6: NOT NULL constraint failed: t.name"
        )
        "stderr timing: real diagnostics survive barrier stripping")
    _Assert(ycSQLite::_StripBarrier(
            "Error: near line 9: no such function: __YC_SQLITE_BARRIER_42__")
        == ""
        "stderr timing: a stale barrier line is removed")
    _Assert(ycSQLite::_StripBarrier("Error: near line 9: boom")
        == "Error: near line 9: boom"
        "stderr timing: normal diagnostics are preserved")

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
            ; 目标客户端在屏障预算内报出错误，因此本用例要求 execute 本次就失败；
            ; 诊断显著滞后时错误可能延后到下一次调用（见 README 的自定义客户端说明）。
            _Assert(!res && next
                "stderr timing: delayed diagnostics are still reported by execute")
            i = 1
            msg = ""
            next = t
            while(i <= 10 && next
                next = errset(db->query("select 1 as v;") nil)
                unless(next
                    msg = lsprintf("%A" errset.errset)
                )
                i++
            )
            _Assert(next
                if(msg != ""
                    strcat("stderr timing: ten consecutive queries stay usable: "
                        msg)
                    "stderr timing: ten consecutive queries stay usable"
                ))
            _Assert(ycSQLite::_StrPos(msg "__YC_SQLITE_BARRIER") == nil
                "stderr timing: diagnostics never expose the internal barrier")
            db->close()
        )
        ycSQLite::Configure(?client saved)
    )
)

_TestChildDone = t

; END
