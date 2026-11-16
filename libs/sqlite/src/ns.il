unless(findNamespace("ycSQLite")
    makeNamespace("ycSQLite")
)
addToNamespace("ycSQLite"
    mapcar('symbolToString '(
        ; sql.il
        _HexValue  ; proc
        _HexDecode  ; proc
        _IsBlob  ; proc
        _StrPos  ; proc
        _ParseInteger  ; proc
        _QuoteIdentifier  ; proc
        _SqlLiteral  ; proc
        _BindSql  ; proc
        _SplitBy  ; proc
        _SplitLines  ; proc
        _SqlScan  ; proc
        _CheckNoDotCommands  ; proc
        _CheckQuery  ; proc
        _EncodedColumn  ; proc
        _EncodedSelect  ; proc
        _ParseHeader  ; proc
        _ParseTableInfo  ; proc
        _ParseRows  ; proc
        _DecodeValue  ; proc
        _ParseChanges  ; proc

        ; blob.il
        _BlobData  ; class
        _CheckHex  ; proc
        _InstallBlob  ; proc
        Blob  ; proc, class

        ; row.il
        _RowData  ; class
        _CheckRowParts  ; proc
        _InstallRow  ; proc
        Row  ; proc, class

        ; result.il
        _ResultData  ; class
        _CheckResultParts  ; proc
        _InstallResult  ; proc
        Result  ; proc, class

        ; client.il
        _DefaultClient  ; var
        _WrapperPath  ; var
        _ClientData  ; class
        _CheckCommandList  ; proc
        _CommandText  ; proc
        _ErrText  ; proc
        _RunCommand  ; proc
        _SessionProbe  ; proc
        _ParseVersion  ; proc
        _ValidateClient  ; proc
        _CommandExists  ; proc
        _InstallClient  ; proc
        Client  ; proc, class
        Configure  ; proc
        DefaultClient  ; proc
        ProbeClient  ; proc

        ; database.il
        _DatabaseData  ; class
        _DbError  ; proc
        _CheckDatabase  ; proc
        _SessionAlive  ; proc
        _SessionErrorLine  ; proc
        _StripBarrier  ; proc
        _SessionSend  ; proc
        _StartSession  ; proc
        _Query  ; proc
        _Pragma  ; proc
        _CloseDatabase  ; proc
        _Transaction  ; proc
        _InstallDatabase  ; proc
        Database  ; class
        Open  ; proc
    ))
)
unuseNamespace("ycSQLite")

; END
