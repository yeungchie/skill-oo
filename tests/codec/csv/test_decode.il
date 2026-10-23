; --- 空输入与基本行 ---
let((t_tab)
    t_tab = ycCsv::Decode("")
    _assert(t_tab->rowCount() == 0  "decode: empty input has no rows")
    _assert(t_tab->header() == nil  "decode: empty input has no header")
    _assert(t_tab->columnCount() == 0  "decode: empty input has no columns")
)
_assertRows(ycCsv::Decode("a,b\n")->rows() list(list("a" "b"))  "decode: one row")
_assert(ycCsv::Decode("a,b\n")->rowCount() == 1  "decode: trailing newline adds no row")
_assertRows(ycCsv::Decode("a,b")->rows() list(list("a" "b"))  "decode: no final newline")
_assertRows(
    ycCsv::Decode("a,b\nc,d")->rows()
    list(list("a" "b") list("c" "d"))
    "decode: two rows without final newline"
)
_assertRows(
    ycCsv::Decode("a,b\nc,d\n")->rows()
    list(list("a" "b") list("c" "d"))
    "decode: two rows with final newline"
)

; --- 空字段与空行 ---
_assertRows(ycCsv::Decode(",\n")->rows() list(list("" ""))  "decode: two empty fields")
_assertRows(ycCsv::Decode("a,\n")->rows() list(list("a" ""))  "decode: trailing empty field")
_assertRows(ycCsv::Decode(",a\n")->rows() list(list("" "a"))  "decode: leading empty field")
_assertRows(ycCsv::Decode("a,,b\n")->rows() list(list("a" "" "b"))  "decode: middle empty field")
_assertRows(ycCsv::Decode("\n")->rows() list(list(""))  "decode: blank line is one empty field")
_assertRows(ycCsv::Decode("a\n\n")->rows() list(list("a") list(""))  "decode: trailing blank line is a record")
_assertRows(ycCsv::Decode("\"\"\"\"\n")->rows() list(list("\""))  "decode: four quotes are one quote")
_assertRows(
    ycCsv::Decode("a\n\nb\n")->rows()
    list(list("a") list("") list("b"))
    "decode: blank line preserved strictly"
)
_assertRows(
    ycCsv::Decode("a\n\nb\n" ?skipEmpty t)->rows()
    list(list("a") list("b"))
    "decode: skipEmpty drops blank record"
)
_assertRows(ycCsv::Decode("\n\n" ?skipEmpty t)->rows() nil  "decode: skipEmpty all blank")
_assert(ycCsv::Decode("a,,b\n" ?skipEmpty t)->rowCount() == 1  "decode: skipEmpty keeps multi-field empty row")

; --- CRLF 与 CR ---
_assertRows(
    ycCsv::Decode("a,b\r\nc,d\r\n")->rows()
    list(list("a" "b") list("c" "d"))
    "decode: CRLF"
)
_assertRows(
    ycCsv::Decode("a,b\rc,d\r")->rows()
    list(list("a" "b") list("c" "d"))
    "decode: CR line endings"
)
_assertRows(
    ycCsv::Decode("a\r\nb\nc\rd")->rows()
    list(list("a") list("b") list("c") list("d"))
    "decode: mixed line endings"
)
_assertRows(
    ycCsv::Decode("a,b\r\n\r\nc\n")->rows()
    list(list("a" "b") list("") list("c"))
    "decode: CRLF blank line"
)

; --- 引号 ---
_assertRows(ycCsv::Decode("\"a,b\",c\n")->rows() list(list("a,b" "c"))  "decode: quoted delimiter")
_assertRows(ycCsv::Decode("\"a\"\"b\",c\n")->rows() list(list("a\"b" "c"))  "decode: doubled quote")
_assertRows(ycCsv::Decode("\"\",x\n")->rows() list(list("" "x"))  "decode: quoted empty field")
_assertRows(ycCsv::Decode("\"\"\n")->rows() list(list(""))  "decode: quoted empty record")
_assertRows(
    ycCsv::Decode("\"a\nb\",c\n")->rows()
    list(list(strcat("a" intToChar(10) "b") "c"))
    "decode: newline inside quoted field"
)
_assertRows(
    ycCsv::Decode("\"a\r\nb\",c\n")->rows()
    list(list(strcat("a" intToChar(13) intToChar(10) "b") "c"))
    "decode: CRLF inside quoted field preserved"
)
_assertRows(ycCsv::Decode(" a , b \n")->rows() list(list(" a " " b "))  "decode: spaces preserved")
_assertError(lambda(() ycCsv::Decode("\"a\" ,b\n"))  "decode: space after closing quote errors")
_assertError(lambda(() ycCsv::Decode("a\"b\n"))  "decode: quote in unquoted field errors")

; --- 引号错误 ---
_assertErrorMsg(lambda(() ycCsv::Decode("\"a\"x\n")) "line 1"  "decode: text after closing quote errors")
_assertError(lambda(() ycCsv::Decode("\"a" ))  "decode: unterminated quote errors")
_assertError(lambda(() ycCsv::Decode("\"a\n"))  "decode: unterminated quote across line errors")
_assertError(lambda(() ycCsv::Decode("\"\"\""))  "decode: odd quote run errors")
_assertErrorMsg(lambda(() ycCsv::Decode("a,b\n\"c\n")) "line 2"  "decode: unterminated quote line number")

; --- BOM ---
let((t_bom t_tab)
    t_bom = strcat(intToChar(239) intToChar(187) intToChar(191))
    t_tab = ycCsv::Decode(strcat(t_bom "a,b\n"))
    _assertRows(t_tab->rows() list(list("a" "b"))  "decode: BOM stripped by default")
    t_tab = ycCsv::Decode(strcat(t_bom "a,b\n") ?stripBom nil)
    _assert(car(t_tab->row(1)) == strcat(t_bom "a")  "decode: stripBom nil keeps BOM")
    _assertRows(ycCsv::Decode(t_bom)->rows() nil  "decode: BOM-only input is empty")
    t_tab = ycCsv::Decode(strcat(t_bom "a,b\n1,2\n") ?header t)
    _assert(car(t_tab->header()) == "a"  "decode: BOM stripped before header")
)

; --- TSV 与自定义分隔符 ---
_assertRows(ycCsv::Decode("a\tb\n" ?format "tsv")->rows() list(list("a" "b"))  "decode: TSV")
_assertRows(ycCsv::Decode("\"a\tb\"\tc\n" ?format "tsv")->rows() list(list("a\tb" "c"))  "decode: TSV quoted tab")
_assertRows(ycCsv::Decode("a;b\n" ?delimiter ";")->rows() list(list("a" "b"))  "decode: custom delimiter")
_assertRows(ycCsv::Decode("\"a;b\";c\n" ?delimiter ";")->rows() list(list("a;b" "c"))  "decode: quoted custom delimiter")
_assertRows(
    ycCsv::Decode("a\tb\n" ?format "tsv" ?delimiter ",")->rows()
    list(list("a\tb"))
    "decode: delimiter overrides format default"
)
_assertRows(
    ycCsv::Decode("a,b\n" ?format "tsv" ?delimiter ",")->rows()
    list(list("a" "b"))
    "decode: csv delimiter with tsv format"
)

; --- 格式与选项负例 ---
_assertError(lambda(() ycCsv::Decode("a" ?format "xml"))  "decode: unknown format errors")
_assertError(lambda(() ycCsv::Decode("a" ?format 1))  "decode: fixnum format errors")
_assertError(lambda(() ycCsv::Decode("a" ?format 1.5))  "decode: flonum format errors")
_assertError(lambda(() ycCsv::Decode("a" ?format 'csv))  "decode: symbol format errors")
_assertError(lambda(() ycCsv::Decode("a" ?format "CSV"))  "decode: uppercase format errors")
_assertError(lambda(() ycCsv::Decode("a" ?format nil))  "decode: nil format errors")
_assertError(lambda(() ycCsv::Decode(1))  "decode: fixnum input errors")
_assertError(lambda(() ycCsv::Decode('a))  "decode: symbol input errors")
_assertError(lambda(() ycCsv::Decode("a" ?delimiter ""))  "decode: empty delimiter errors")
_assertError(lambda(() ycCsv::Decode("a" ?delimiter "ab"))  "decode: multi-byte delimiter errors")
_assertError(lambda(() ycCsv::Decode("a" ?delimiter 1))  "decode: fixnum delimiter errors")
_assertError(lambda(() ycCsv::Decode("a" ?delimiter 'x))  "decode: symbol delimiter errors")
_assertError(lambda(() ycCsv::Decode("a" ?delimiter "\""))  "decode: quote delimiter errors")
_assertError(lambda(() ycCsv::Decode("a" ?delimiter "\n"))  "decode: LF delimiter errors")
_assertError(lambda(() ycCsv::Decode("a" ?delimiter "\r"))  "decode: CR delimiter errors")
_assertError(lambda(() ycCsv::Decode("a" ?header "a"))  "decode: string header errors")
_assertError(lambda(() ycCsv::Decode("a" ?header 1))  "decode: fixnum header errors")
_assertError(lambda(() ycCsv::Decode("a" ?header 1.5))  "decode: flonum header errors")
_assertError(lambda(() ycCsv::Decode("a" ?header 'a))  "decode: symbol header errors")

; --- 表头 ---
let((t_tab)
    t_tab = ycCsv::Decode("a,b\n1,2\n3,4\n" ?header t)
    _assertRows(t_tab->header() list("a" "b")  "decode: header t names")
    _assert(t_tab->rowCount() == 2  "decode: header t row count")
    _assert(t_tab->value(1 "a") == "1"  "decode: header t first value")
    _assert(t_tab->value(2 "b") == "4"  "decode: header t second value")
    _assert(t_tab->columnCount() == 2  "decode: header t column count")
)
let((t_tab)
    t_tab = ycCsv::Decode("a,b\n" ?header t)
    _assert(t_tab->rowCount() == 0  "decode: header only row count")
    _assertRows(t_tab->header() list("a" "b")  "decode: header only names")
    _assert(t_tab->columnCount() == 2  "decode: header only column count")
)
let((t_tab)
    t_tab = ycCsv::Decode("" ?header t)
    _assert(t_tab->header() == nil  "decode: empty header t input has no header")
    _assert(t_tab->rowCount() == 0  "decode: empty header t input has no rows")
)
let((t_tab)
    t_tab = ycCsv::Decode("a,b\n1,2\n" ?header list("x" "y"))
    _assertRows(t_tab->header() list("x" "y")  "decode: header list names")
    _assert(t_tab->value(1 "x") == "a"  "decode: header list value")
    _assert(t_tab->value(1 "y") == "b"  "decode: header list second value")
    _assert(t_tab->value(2 "x") == "1"  "decode: header list second row value")
)
let((t_tab)
    t_tab = ycCsv::Decode("" ?header list("x" "y"))
    _assert(t_tab->header() != nil  "decode: header list empty input keeps header")
    _assert(t_tab->rowCount() == 0  "decode: header list empty input has no rows")
)
let((t_tab)
    t_tab = ycCsv::Decode("a,b,c\n1,2\n" ?header t)
    _assert(t_tab->cell(1 3) == ycCodec::Missing  "decode: short row has Missing")
)
let((t_tab)
    t_tab = ycCsv::Decode("\na,b\n1,2\n" ?header t ?skipEmpty t)
    _assertRows(t_tab->header() list("a" "b")  "decode: skipEmpty skips before header")
    _assert(t_tab->rowCount() == 1  "decode: skipEmpty header data row count")
)
_assertError(lambda(() ycCsv::Decode("a,a\n1,2\n" ?header t))  "decode: duplicate header errors")
_assertErrorMsg(
    lambda(() ycCsv::Decode("a,b\n1,2,3\n" ?header t))
    "line 2"
    "decode: overlong row error includes line"
)
_assertErrorMsg(
    lambda(() ycCsv::Decode("a,b\r\n1,2,3\r\n" ?header t))
    "line 2"
    "decode: overlong row error line with CRLF"
)
_assertErrorMsg(
    lambda(() ycCsv::Decode("a\rb\r\"c\n"))
    "line 3"
    "decode: unterminated quote line with CR"
)
_assertError(lambda(() ycCsv::Decode("a,b\n1,2,3\n" ?header list("x" "y")))  "decode: header list overlong row errors")
_assertError(lambda(() ycCsv::Decode("" ?header list("a" "a")))  "decode: duplicate header list errors")
_assertError(lambda(() ycCsv::Decode("" ?header list("a" 1)))  "decode: header list non-string errors")
_assertError(lambda(() ycCsv::Decode("" ?header list("a" 1.5)))  "decode: header list flonum errors")
_assertError(lambda(() ycCsv::Decode("" ?header list("a" 'b)))  "decode: header list symbol errors")

_TestDecodeDone = t

; END
