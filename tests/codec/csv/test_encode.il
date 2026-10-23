; --- 空表与基本行 ---
_Assert(ycCsv::Encode(ycCsv::Table(nil)) == ""  "encode: empty table")
_Assert(ycCsv::Encode(ycCsv::Table(list(list("a" "b")))) == "a,b\n"  "encode: one row")
_Assert(ycCsv::Encode(ycCsv::Table(list(list("a" "b"))) ?finalNewline nil) == "a,b"  "encode: no final newline")
_Assert(
    ycCsv::Encode(ycCsv::Table(list(list("a" "b") list("c" "d")))) == "a,b\nc,d\n"
    "encode: two rows"
)
_Assert(
    ycCsv::Encode(ycCsv::Table(list(list("a" "b") list("c" "d"))) ?finalNewline nil) == "a,b\nc,d"
    "encode: two rows without final newline"
)

; --- 空字段与空行 ---
_Assert(ycCsv::Encode(ycCsv::Table(list(list("")))) == "\n"  "encode: single empty field row")
_Assert(
    ycCsv::Encode(ycCsv::Table(list(list(""))) ?finalNewline nil) == "\"\""
    "encode: final empty row without newline is quoted"
)
_Assert(ycCsv::Encode(ycCsv::Table(list(list("" "x")))) == ",x\n"  "encode: leading empty field")
_Assert(ycCsv::Encode(ycCsv::Table(list(list("x" "")))) == "x,\n"  "encode: trailing empty field")
_Assert(ycCsv::Encode(ycCsv::Table(list(list("" "")))) == ",\n"  "encode: two empty fields")
_Assert(
    ycCsv::Encode(ycCsv::Table(list(list("" "x") list("a" ""))) ?finalNewline nil) == ",x\na,"
    "encode: empty fields without final newline"
)
_Assert(
    ycCsv::Encode(ycCsv::Table(list(list("a") list(""))) ?finalNewline nil) == "a\n\"\""
    "encode: last empty row without newline is quoted"
)
_Assert(
    ycCsv::Encode(ycCsv::Table(list(list("") list("a"))) ?finalNewline nil) == "\na"
    "encode: non-final empty row stays blank"
)

; --- 引号 ---
_Assert(
    ycCsv::Encode(ycCsv::Table(list(list("a,b" "c")))) == "\"a,b\",c\n"
    "encode: delimiter triggers quote"
)
_Assert(
    ycCsv::Encode(ycCsv::Table(list(list("a\"b" "c")))) == "\"a\"\"b\",c\n"
    "encode: quote is doubled"
)
_Assert(
    ycCsv::Encode(ycCsv::Table(list(list(strcat("a" intToChar(10) "b") "c"))))
        == strcat("\"a" intToChar(10) "b\",c" intToChar(10))
    "encode: LF triggers quote"
)
_Assert(
    ycCsv::Encode(ycCsv::Table(list(list(strcat("a" intToChar(13) "b") "c"))))
        == strcat("\"a" intToChar(13) "b\",c" intToChar(10))
    "encode: CR triggers quote"
)
_Assert(
    ycCsv::Encode(ycCsv::Table(list(list(" a " "b")))) == " a ,b\n"
    "encode: spaces do not trigger quote"
)
_Assert(
    ycCsv::Encode(ycCsv::Table(list(list("a\tb" "c")))) == "a\tb,c\n"
    "encode: tab is content for CSV"
)
_Assert(
    ycCsv::Encode(ycCsv::Table(list(list(""))) ?quoteAll t) == "\"\"\n"
    "encode: quoteAll quotes empty field"
)

; --- 表头 ---
_Assert(
    ycCsv::Encode(ycCsv::Table(nil ?header list("a" "b"))) == "a,b\n"
    "encode: header only"
)
_Assert(
    ycCsv::Encode(ycCsv::Table(nil ?header list("a" "b")) ?finalNewline nil) == "a,b"
    "encode: header only without final newline"
)
_Assert(
    ycCsv::Encode(ycCsv::Table(list(list("1" "2")) ?header list("a" "b"))) == "a,b\n1,2\n"
    "encode: header and row"
)
_Assert(
    ycCsv::Encode(ycCsv::Table(list(list("x")) ?header list(""))) == "\nx\n"
    "encode: empty header name"
)
_Assert(
    ycCsv::Encode(ycCsv::Table(nil ?header list("")) ?finalNewline nil) == "\"\""
    "encode: header-only empty name without newline is quoted"
)
_Assert(
    ycCsv::Encode(ycCsv::Table(list(list("a" "b"))) ?quoteAll t) == "\"a\",\"b\"\n"
    "encode: quoteAll"
)
_Assert(
    ycCsv::Encode(ycCsv::Table(list(list("1")) ?header list("a")) ?quoteAll t) == "\"a\"\n\"1\"\n"
    "encode: quoteAll header"
)

; --- TSV 与自定义分隔符 ---
_Assert(
    ycCsv::Encode(ycCsv::Table(list(list("a" "b"))) ?format "tsv") == "a\tb\n"
    "encode: TSV"
)
_Assert(
    ycCsv::Encode(ycCsv::Table(list(list("a\tb" "c"))) ?format "tsv") == "\"a\tb\"\tc\n"
    "encode: TSV tab triggers quote"
)
_Assert(
    ycCsv::Encode(ycCsv::Table(list(list("a" "b"))) ?delimiter ";") == "a;b\n"
    "encode: custom delimiter"
)
_Assert(
    ycCsv::Encode(ycCsv::Table(list(list("a;b" "c"))) ?delimiter ";") == "\"a;b\";c\n"
    "encode: custom delimiter triggers quote"
)
_Assert(
    ycCsv::Encode(ycCsv::Table(list(list("a,b" "c"))) ?delimiter ";") == "a,b;c\n"
    "encode: comma is content with semicolon delimiter"
)
_Assert(
    ycCsv::Encode(ycCsv::Table(list(list("a" "b"))) ?format "tsv" ?delimiter ",") == "a,b\n"
    "encode: delimiter overrides format default"
)

; --- EOL 与末尾换行 ---
_Assert(
    ycCsv::Encode(ycCsv::Table(list(list("a" "b") list("c" "d"))) ?eol "\r\n")
        == "a,b\r\nc,d\r\n"
    "encode: CRLF"
)
_Assert(
    ycCsv::Encode(ycCsv::Table(list(list("a" "b"))) ?eol "\r\n" ?finalNewline nil) == "a,b"
    "encode: CRLF without final newline"
)
_AssertError(lambda(() ycCsv::Encode(ycCsv::Table(nil) ?eol "\r"))  "encode: CR-only eol errors")
_AssertError(lambda(() ycCsv::Encode(ycCsv::Table(nil) ?eol ""))  "encode: empty eol errors")
_AssertError(lambda(() ycCsv::Encode(ycCsv::Table(nil) ?eol 1))  "encode: fixnum eol errors")
_AssertError(lambda(() ycCsv::Encode(ycCsv::Table(nil) ?eol 1.5))  "encode: flonum eol errors")
_AssertError(lambda(() ycCsv::Encode(ycCsv::Table(nil) ?eol 'lf))  "encode: symbol eol errors")
_AssertError(lambda(() ycCsv::Encode(ycCsv::Table(nil) ?eol nil))  "encode: nil eol errors")

; --- 选项与类型负例 ---
_AssertError(lambda(() ycCsv::Encode(nil))  "encode: nil table errors")
_AssertError(lambda(() ycCsv::Encode(list(list("a"))))  "encode: row list is not a table")
_AssertError(lambda(() ycCsv::Encode("a"))  "encode: string table errors")
_AssertError(lambda(() ycCsv::Encode(1))  "encode: fixnum table errors")
_AssertError(lambda(() ycCsv::Encode(1.5))  "encode: flonum table errors")
_AssertError(lambda(() ycCsv::Encode('a))  "encode: symbol table errors")
_AssertError(lambda(() ycCsv::Encode(ycCsv::Table(nil) ?format "xml"))  "encode: unknown format errors")
_AssertError(lambda(() ycCsv::Encode(ycCsv::Table(nil) ?format nil))  "encode: nil format errors")
_AssertError(lambda(() ycCsv::Encode(ycCsv::Table(nil) ?format 1))  "encode: fixnum format errors")
_AssertError(lambda(() ycCsv::Encode(ycCsv::Table(nil) ?format 1.5))  "encode: flonum format errors")
_AssertError(lambda(() ycCsv::Encode(ycCsv::Table(nil) ?format 'csv))  "encode: symbol format errors")
_AssertError(lambda(() ycCsv::Encode(ycCsv::Table(nil) ?delimiter ""))  "encode: empty delimiter errors")
_AssertError(lambda(() ycCsv::Encode(ycCsv::Table(nil) ?delimiter "ab"))  "encode: multi-byte delimiter errors")
_AssertError(lambda(() ycCsv::Encode(ycCsv::Table(nil) ?delimiter 1))  "encode: fixnum delimiter errors")
_AssertError(lambda(() ycCsv::Encode(ycCsv::Table(nil) ?delimiter 'x))  "encode: symbol delimiter errors")
_AssertError(lambda(() ycCsv::Encode(ycCsv::Table(nil) ?delimiter "\""))  "encode: quote delimiter errors")
_AssertError(lambda(() ycCsv::Encode(ycCsv::Table(nil) ?delimiter "\n"))  "encode: LF delimiter errors")
_AssertError(lambda(() ycCsv::Encode(ycCsv::Table(nil) ?delimiter "\r"))  "encode: CR delimiter errors")

; --- 往返 ---
let((t_tab t_out)
    t_tab = ycCsv::Table(
        list(
            list("a,b" "c\"d" "e\nf" "" " g ")
            list("" "x" "y" "z" "w")
        )
        ?header list("h1" "h2" "h3" "h4" "h5")
    )
    t_out = ycCsv::Decode(ycCsv::Encode(t_tab ?eol "\r\n") ?header t)
    _AssertRows(t_out->header() list("h1" "h2" "h3" "h4" "h5")  "roundtrip: header")
    _AssertRows(t_out->row(1) t_tab->row(1)  "roundtrip: first row")
    _AssertRows(t_out->row(2) t_tab->row(2)  "roundtrip: second row")
    _AssertRows(ycCsv::Decode(ycCsv::Encode(t_tab) ?header t)->rows() t_tab->rows()  "roundtrip: rows")
)
let((t_tab t_out)
    t_tab = ycCsv::Table(list(list("") list("a") list("")))
    t_out = ycCsv::Decode(ycCsv::Encode(t_tab ?finalNewline nil))
    _AssertRows(t_out->rows() t_tab->rows()  "roundtrip: empty rows without final newline")
)
let((t_tab t_out)
    t_tab = ycCsv::Table(list(list("中" "a\tb")))
    t_out = ycCsv::Decode(ycCsv::Encode(t_tab ?format "tsv") ?format "tsv")
    _AssertRows(t_out->rows() t_tab->rows()  "roundtrip: unicode and TSV tab")
)
let((t_tab t_out)
    t_tab = ycCsv::Table(list(list("\"" "a")))
    t_out = ycCsv::Decode(ycCsv::Encode(t_tab))
    _AssertRows(t_out->rows() t_tab->rows()  "roundtrip: quote-only field")
)

_TestEncodeDone = t

; END
