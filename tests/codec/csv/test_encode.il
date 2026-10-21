; --- 空表与基本行 ---
_assert(ycCsv::encode(ycCsv::Table(nil)) == ""  "encode: empty table")
_assert(ycCsv::encode(ycCsv::Table(list(list("a" "b")))) == "a,b\n"  "encode: one row")
_assert(ycCsv::encode(ycCsv::Table(list(list("a" "b"))) ?finalNewline nil) == "a,b"  "encode: no final newline")
_assert(
    ycCsv::encode(ycCsv::Table(list(list("a" "b") list("c" "d")))) == "a,b\nc,d\n"
    "encode: two rows"
)
_assert(
    ycCsv::encode(ycCsv::Table(list(list("a" "b") list("c" "d"))) ?finalNewline nil) == "a,b\nc,d"
    "encode: two rows without final newline"
)

; --- 空字段与空行 ---
_assert(ycCsv::encode(ycCsv::Table(list(list("")))) == "\n"  "encode: single empty field row")
_assert(
    ycCsv::encode(ycCsv::Table(list(list(""))) ?finalNewline nil) == "\"\""
    "encode: final empty row without newline is quoted"
)
_assert(ycCsv::encode(ycCsv::Table(list(list("" "x")))) == ",x\n"  "encode: leading empty field")
_assert(ycCsv::encode(ycCsv::Table(list(list("x" "")))) == "x,\n"  "encode: trailing empty field")
_assert(ycCsv::encode(ycCsv::Table(list(list("" "")))) == ",\n"  "encode: two empty fields")
_assert(
    ycCsv::encode(ycCsv::Table(list(list("" "x") list("a" ""))) ?finalNewline nil) == ",x\na,"
    "encode: empty fields without final newline"
)
_assert(
    ycCsv::encode(ycCsv::Table(list(list("a") list(""))) ?finalNewline nil) == "a\n\"\""
    "encode: last empty row without newline is quoted"
)
_assert(
    ycCsv::encode(ycCsv::Table(list(list("") list("a"))) ?finalNewline nil) == "\na"
    "encode: non-final empty row stays blank"
)

; --- 引号 ---
_assert(
    ycCsv::encode(ycCsv::Table(list(list("a,b" "c")))) == "\"a,b\",c\n"
    "encode: delimiter triggers quote"
)
_assert(
    ycCsv::encode(ycCsv::Table(list(list("a\"b" "c")))) == "\"a\"\"b\",c\n"
    "encode: quote is doubled"
)
_assert(
    ycCsv::encode(ycCsv::Table(list(list(strcat("a" intToChar(10) "b") "c"))))
        == strcat("\"a" intToChar(10) "b\",c" intToChar(10))
    "encode: LF triggers quote"
)
_assert(
    ycCsv::encode(ycCsv::Table(list(list(strcat("a" intToChar(13) "b") "c"))))
        == strcat("\"a" intToChar(13) "b\",c" intToChar(10))
    "encode: CR triggers quote"
)
_assert(
    ycCsv::encode(ycCsv::Table(list(list(" a " "b")))) == " a ,b\n"
    "encode: spaces do not trigger quote"
)
_assert(
    ycCsv::encode(ycCsv::Table(list(list("a\tb" "c")))) == "a\tb,c\n"
    "encode: tab is content for CSV"
)
_assert(
    ycCsv::encode(ycCsv::Table(list(list(""))) ?quoteAll t) == "\"\"\n"
    "encode: quoteAll quotes empty field"
)

; --- 表头 ---
_assert(
    ycCsv::encode(ycCsv::Table(nil ?header list("a" "b"))) == "a,b\n"
    "encode: header only"
)
_assert(
    ycCsv::encode(ycCsv::Table(nil ?header list("a" "b")) ?finalNewline nil) == "a,b"
    "encode: header only without final newline"
)
_assert(
    ycCsv::encode(ycCsv::Table(list(list("1" "2")) ?header list("a" "b"))) == "a,b\n1,2\n"
    "encode: header and row"
)
_assert(
    ycCsv::encode(ycCsv::Table(list(list("x")) ?header list(""))) == "\nx\n"
    "encode: empty header name"
)
_assert(
    ycCsv::encode(ycCsv::Table(nil ?header list("")) ?finalNewline nil) == "\"\""
    "encode: header-only empty name without newline is quoted"
)
_assert(
    ycCsv::encode(ycCsv::Table(list(list("a" "b"))) ?quoteAll t) == "\"a\",\"b\"\n"
    "encode: quoteAll"
)
_assert(
    ycCsv::encode(ycCsv::Table(list(list("1")) ?header list("a")) ?quoteAll t) == "\"a\"\n\"1\"\n"
    "encode: quoteAll header"
)

; --- TSV 与自定义分隔符 ---
_assert(
    ycCsv::encode(ycCsv::Table(list(list("a" "b"))) ?format "tsv") == "a\tb\n"
    "encode: TSV"
)
_assert(
    ycCsv::encode(ycCsv::Table(list(list("a\tb" "c"))) ?format "tsv") == "\"a\tb\"\tc\n"
    "encode: TSV tab triggers quote"
)
_assert(
    ycCsv::encode(ycCsv::Table(list(list("a" "b"))) ?delimiter ";") == "a;b\n"
    "encode: custom delimiter"
)
_assert(
    ycCsv::encode(ycCsv::Table(list(list("a,b" "c"))) ?delimiter ";") == "a,b;c\n"
    "encode: comma is content with semicolon delimiter"
)
_assert(
    ycCsv::encode(ycCsv::Table(list(list("a" "b"))) ?format "tsv" ?delimiter ",") == "a,b\n"
    "encode: delimiter overrides format default"
)

; --- EOL 与末尾换行 ---
_assert(
    ycCsv::encode(ycCsv::Table(list(list("a" "b") list("c" "d"))) ?eol "\r\n")
        == "a,b\r\nc,d\r\n"
    "encode: CRLF"
)
_assert(
    ycCsv::encode(ycCsv::Table(list(list("a" "b"))) ?eol "\r\n" ?finalNewline nil) == "a,b"
    "encode: CRLF without final newline"
)
_assertError(lambda(() ycCsv::encode(ycCsv::Table(nil) ?eol "\r"))  "encode: CR-only eol errors")
_assertError(lambda(() ycCsv::encode(ycCsv::Table(nil) ?eol ""))  "encode: empty eol errors")
_assertError(lambda(() ycCsv::encode(ycCsv::Table(nil) ?eol 1))  "encode: fixnum eol errors")
_assertError(lambda(() ycCsv::encode(ycCsv::Table(nil) ?eol 1.5))  "encode: flonum eol errors")
_assertError(lambda(() ycCsv::encode(ycCsv::Table(nil) ?eol 'lf))  "encode: symbol eol errors")
_assertError(lambda(() ycCsv::encode(ycCsv::Table(nil) ?eol nil))  "encode: nil eol errors")

; --- 选项与类型负例 ---
_assertError(lambda(() ycCsv::encode(nil))  "encode: nil table errors")
_assertError(lambda(() ycCsv::encode(list(list("a"))))  "encode: row list is not a table")
_assertError(lambda(() ycCsv::encode("a"))  "encode: string table errors")
_assertError(lambda(() ycCsv::encode(1))  "encode: fixnum table errors")
_assertError(lambda(() ycCsv::encode(1.5))  "encode: flonum table errors")
_assertError(lambda(() ycCsv::encode('a))  "encode: symbol table errors")
_assertError(lambda(() ycCsv::encode(ycCsv::Table(nil) ?format "xml"))  "encode: unknown format errors")
_assertError(lambda(() ycCsv::encode(ycCsv::Table(nil) ?format nil))  "encode: nil format errors")
_assertError(lambda(() ycCsv::encode(ycCsv::Table(nil) ?format 1))  "encode: fixnum format errors")
_assertError(lambda(() ycCsv::encode(ycCsv::Table(nil) ?format 1.5))  "encode: flonum format errors")
_assertError(lambda(() ycCsv::encode(ycCsv::Table(nil) ?format 'csv))  "encode: symbol format errors")
_assertError(lambda(() ycCsv::encode(ycCsv::Table(nil) ?delimiter ""))  "encode: empty delimiter errors")
_assertError(lambda(() ycCsv::encode(ycCsv::Table(nil) ?delimiter "ab"))  "encode: multi-byte delimiter errors")
_assertError(lambda(() ycCsv::encode(ycCsv::Table(nil) ?delimiter 1))  "encode: fixnum delimiter errors")
_assertError(lambda(() ycCsv::encode(ycCsv::Table(nil) ?delimiter 'x))  "encode: symbol delimiter errors")
_assertError(lambda(() ycCsv::encode(ycCsv::Table(nil) ?delimiter "\""))  "encode: quote delimiter errors")
_assertError(lambda(() ycCsv::encode(ycCsv::Table(nil) ?delimiter "\n"))  "encode: LF delimiter errors")
_assertError(lambda(() ycCsv::encode(ycCsv::Table(nil) ?delimiter "\r"))  "encode: CR delimiter errors")

; --- 往返 ---
let((t_tab t_out)
    t_tab = ycCsv::Table(
        list(
            list("a,b" "c\"d" "e\nf" "" " g ")
            list("" "x" "y" "z" "w")
        )
        ?header list("h1" "h2" "h3" "h4" "h5")
    )
    t_out = ycCsv::decode(ycCsv::encode(t_tab ?eol "\r\n") ?header t)
    _assertRows(t_out->header() list("h1" "h2" "h3" "h4" "h5")  "roundtrip: header")
    _assertRows(t_out->row(1) t_tab->row(1)  "roundtrip: first row")
    _assertRows(t_out->row(2) t_tab->row(2)  "roundtrip: second row")
    _assertRows(ycCsv::decode(ycCsv::encode(t_tab) ?header t)->rows() t_tab->rows()  "roundtrip: rows")
)
let((t_tab t_out)
    t_tab = ycCsv::Table(list(list("") list("a") list("")))
    t_out = ycCsv::decode(ycCsv::encode(t_tab ?finalNewline nil))
    _assertRows(t_out->rows() t_tab->rows()  "roundtrip: empty rows without final newline")
)
let((t_tab t_out)
    t_tab = ycCsv::Table(list(list("中" "a\tb")))
    t_out = ycCsv::decode(ycCsv::encode(t_tab ?format "tsv") ?format "tsv")
    _assertRows(t_out->rows() t_tab->rows()  "roundtrip: unicode and TSV tab")
)
let((t_tab t_out)
    t_tab = ycCsv::Table(list(list("\"" "a")))
    t_out = ycCsv::decode(ycCsv::encode(t_tab))
    _assertRows(t_out->rows() t_tab->rows()  "roundtrip: quote-only field")
)

_TestEncodeDone = t

; END
