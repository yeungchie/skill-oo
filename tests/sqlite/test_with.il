let((kept res)
    ycWith(db ycSQLite::Open(":memory:")
        kept = db
        _Assert(!db->isClosed()
            "with: database stays open inside scope")
    )
    _Assert(kept->isClosed()
        "with: normal exit closes database")

    kept = nil
    res = errset(
        ycWith(db ycSQLite::Open(":memory:")
            kept = db
            error("forced with error")
        )
        nil
    )
    _Assert(!res
        "with: body error is propagated")
    _Assert(kept->isClosed()
        "with: error exit closes database")
)

_TestChildDone = t

; END
