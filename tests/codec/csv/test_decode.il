; --- 空输入与基本行 ---
let((tab)
    tab = ycCsv::Decode("")
    _Assert(tab->rowCount() == 0  "decode: empty input has no rows")
    _Assert(tab->header() == nil  "decode: empty input has no header")
    _Assert(tab->columnCount() == 0  "decode: empty input has no columns")
)
_AssertRows(ycCsv::Decode("a,b\n")->rows() list(list("a" "b"))  "decode: one row")
_Assert(ycCsv::Decode("a,b\n")->rowCount() == 1  "decode: trailing newline adds no row")
_AssertRows(ycCsv::Decode("a,b")->rows() list(list("a" "b"))  "decode: no final newline")
_AssertRows(
    ycCsv::Decode("a,b\nc,d")->rows()
    list(list("a" "b") list("c" "d"))
    "decode: two rows without final newline"
)
_AssertRows(
    ycCsv::Decode("a,b\nc,d\n")->rows()
    list(list("a" "b") list("c" "d"))
    "decode: two rows with final newline"
)

; --- 空字段与空行 ---
_AssertRows(ycCsv::Decode(",\n")->rows() list(list("" ""))  "decode: two empty fields")
_AssertRows(ycCsv::Decode("a,\n")->rows() list(list("a" ""))  "decode: trailing empty field")
_AssertRows(ycCsv::Decode(",a\n")->rows() list(list("" "a"))  "decode: leading empty field")
_AssertRows(ycCsv::Decode("a,,b\n")->rows() list(list("a" "" "b"))  "decode: middle empty field")
_AssertRows(ycCsv::Decode("\n")->rows() list(list(""))  "decode: blank line is one empty field")
_AssertRows(ycCsv::Decode("a\n\n")->rows() list(list("a") list(""))  "decode: trailing blank line is a record")
_AssertRows(ycCsv::Decode("\"\"\"\"\n")->rows() list(list("\""))  "decode: four quotes are one quote")
_AssertRows(
    ycCsv::Decode("a\n\nb\n")->rows()
    list(list("a") list("") list("b"))
    "decode: blank line preserved strictly"
)
_AssertRows(
    ycCsv::Decode("a\n\nb\n" ?skipEmpty t)->rows()
    list(list("a") list("b"))
    "decode: skipEmpty drops blank record"
)
_AssertRows(ycCsv::Decode("\n\n" ?skipEmpty t)->rows() nil  "decode: skipEmpty all blank")
_Assert(ycCsv::Decode("a,,b\n" ?skipEmpty t)->rowCount() == 1  "decode: skipEmpty keeps multi-field empty row")

; --- CRLF 与 CR ---
_AssertRows(
    ycCsv::Decode("a,b\r\nc,d\r\n")->rows()
    list(list("a" "b") list("c" "d"))
    "decode: CRLF"
)
_AssertRows(
    ycCsv::Decode("a,b\rc,d\r")->rows()
    list(list("a" "b") list("c" "d"))
    "decode: CR line endings"
)
_AssertRows(
    ycCsv::Decode("a\r\nb\nc\rd")->rows()
    list(list("a") list("b") list("c") list("d"))
    "decode: mixed line endings"
)
_AssertRows(
    ycCsv::Decode("a,b\r\n\r\nc\n")->rows()
    list(list("a" "b") list("") list("c"))
    "decode: CRLF blank line"
)

; --- 引号 ---
_AssertRows(ycCsv::Decode("\"a,b\",c\n")->rows() list(list("a,b" "c"))  "decode: quoted delimiter")
_AssertRows(ycCsv::Decode("\"a\"\"b\",c\n")->rows() list(list("a\"b" "c"))  "decode: doubled quote")
_AssertRows(ycCsv::Decode("\"\",x\n")->rows() list(list("" "x"))  "decode: quoted empty field")
_AssertRows(ycCsv::Decode("\"\"\n")->rows() list(list(""))  "decode: quoted empty record")
_AssertRows(
    ycCsv::Decode("\"a\nb\",c\n")->rows()
    list(list(strcat("a" intToChar(10) "b") "c"))
    "decode: newline inside quoted field"
)
_AssertRows(
    ycCsv::Decode("\"a\r\nb\",c\n")->rows()
    list(list(strcat("a" intToChar(13) intToChar(10) "b") "c"))
    "decode: CRLF inside quoted field preserved"
)
_AssertRows(ycCsv::Decode(" a , b \n")->rows() list(list(" a " " b "))  "decode: spaces preserved")
_AssertError(lambda(() ycCsv::Decode("\"a\" ,b\n"))  "decode: space after closing quote errors")
_AssertError(lambda(() ycCsv::Decode("a\"b\n"))  "decode: quote in unquoted field errors")

; --- 引号错误 ---
_AssertErrorMsg(lambda(() ycCsv::Decode("\"a\"x\n")) "line 1"  "decode: text after closing quote errors")
_AssertError(lambda(() ycCsv::Decode("\"a" ))  "decode: unterminated quote errors")
_AssertError(lambda(() ycCsv::Decode("\"a\n"))  "decode: unterminated quote across line errors")
_AssertError(lambda(() ycCsv::Decode("\"\"\""))  "decode: odd quote run errors")
_AssertErrorMsg(lambda(() ycCsv::Decode("a,b\n\"c\n")) "line 2"  "decode: unterminated quote line number")

; --- BOM ---
let((bom tab)
    bom = strcat(intToChar(239) intToChar(187) intToChar(191))
    tab = ycCsv::Decode(strcat(bom "a,b\n"))
    _AssertRows(tab->rows() list(list("a" "b"))  "decode: BOM stripped by default")
    tab = ycCsv::Decode(strcat(bom "a,b\n") ?stripBom nil)
    _Assert(car(tab->row(1)) == strcat(bom "a")  "decode: stripBom nil keeps BOM")
    _AssertRows(ycCsv::Decode(bom)->rows() nil  "decode: BOM-only input is empty")
    tab = ycCsv::Decode(strcat(bom "a,b\n1,2\n") ?header t)
    _Assert(car(tab->header()) == "a"  "decode: BOM stripped before header")
)

; --- TSV 与自定义分隔符 ---
_AssertRows(ycCsv::Decode("a\tb\n" ?format "tsv")->rows() list(list("a" "b"))  "decode: TSV")
_AssertRows(ycCsv::Decode("\"a\tb\"\tc\n" ?format "tsv")->rows() list(list("a\tb" "c"))  "decode: TSV quoted tab")
_AssertRows(ycCsv::Decode("a;b\n" ?delimiter ";")->rows() list(list("a" "b"))  "decode: custom delimiter")
_AssertRows(ycCsv::Decode("\"a;b\";c\n" ?delimiter ";")->rows() list(list("a;b" "c"))  "decode: quoted custom delimiter")
_AssertRows(
    ycCsv::Decode("a\tb\n" ?format "tsv" ?delimiter ",")->rows()
    list(list("a\tb"))
    "decode: delimiter overrides format default"
)
_AssertRows(
    ycCsv::Decode("a,b\n" ?format "tsv" ?delimiter ",")->rows()
    list(list("a" "b"))
    "decode: csv delimiter with tsv format"
)

; --- 格式与选项负例 ---
_AssertError(lambda(() ycCsv::Decode("a" ?format "xml"))  "decode: unknown format errors")
_AssertError(lambda(() ycCsv::Decode("a" ?format 1))  "decode: fixnum format errors")
_AssertError(lambda(() ycCsv::Decode("a" ?format 1.5))  "decode: flonum format errors")
_AssertError(lambda(() ycCsv::Decode("a" ?format 'csv))  "decode: symbol format errors")
_AssertError(lambda(() ycCsv::Decode("a" ?format "CSV"))  "decode: uppercase format errors")
_AssertError(lambda(() ycCsv::Decode("a" ?format nil))  "decode: nil format errors")
_AssertError(lambda(() ycCsv::Decode(1))  "decode: fixnum input errors")
_AssertError(lambda(() ycCsv::Decode('a))  "decode: symbol input errors")
_AssertError(lambda(() ycCsv::Decode("a" ?delimiter ""))  "decode: empty delimiter errors")
_AssertError(lambda(() ycCsv::Decode("a" ?delimiter "ab"))  "decode: multi-byte delimiter errors")
_AssertError(lambda(() ycCsv::Decode("a" ?delimiter "中"))  "decode: multibyte character delimiter errors")
_AssertError(lambda(() ycCsv::Decode("a" ?delimiter 1))  "decode: fixnum delimiter errors")
_AssertError(lambda(() ycCsv::Decode("a" ?delimiter 'x))  "decode: symbol delimiter errors")
_AssertError(lambda(() ycCsv::Decode("a" ?delimiter "\""))  "decode: quote delimiter errors")
_AssertError(lambda(() ycCsv::Decode("a" ?delimiter "\n"))  "decode: LF delimiter errors")
_AssertError(lambda(() ycCsv::Decode("a" ?delimiter "\r"))  "decode: CR delimiter errors")
_AssertError(lambda(() ycCsv::Decode("a" ?header "a"))  "decode: string header errors")
_AssertError(lambda(() ycCsv::Decode("a" ?header 1))  "decode: fixnum header errors")
_AssertError(lambda(() ycCsv::Decode("a" ?header 1.5))  "decode: flonum header errors")
_AssertError(lambda(() ycCsv::Decode("a" ?header 'a))  "decode: symbol header errors")

; --- 表头 ---
let((tab)
    tab = ycCsv::Decode("a,b\n1,2\n3,4\n" ?header t)
    _AssertRows(tab->header() list("a" "b")  "decode: header t names")
    _Assert(tab->rowCount() == 2  "decode: header t row count")
    _Assert(tab->value(1 "a") == "1"  "decode: header t first value")
    _Assert(tab->value(2 "b") == "4"  "decode: header t second value")
    _Assert(tab->columnCount() == 2  "decode: header t column count")
)
let((tab)
    tab = ycCsv::Decode("a,b\n" ?header t)
    _Assert(tab->rowCount() == 0  "decode: header only row count")
    _AssertRows(tab->header() list("a" "b")  "decode: header only names")
    _Assert(tab->columnCount() == 2  "decode: header only column count")
)
let((tab)
    tab = ycCsv::Decode("" ?header t)
    _Assert(tab->header() == nil  "decode: empty header t input has no header")
    _Assert(tab->rowCount() == 0  "decode: empty header t input has no rows")
)
let((tab)
    tab = ycCsv::Decode("a,b\n1,2\n" ?header list("x" "y"))
    _AssertRows(tab->header() list("x" "y")  "decode: header list names")
    _Assert(tab->value(1 "x") == "a"  "decode: header list value")
    _Assert(tab->value(1 "y") == "b"  "decode: header list second value")
    _Assert(tab->value(2 "x") == "1"  "decode: header list second row value")
)
let((tab)
    tab = ycCsv::Decode("" ?header list("x" "y"))
    _Assert(tab->header() != nil  "decode: header list empty input keeps header")
    _Assert(tab->rowCount() == 0  "decode: header list empty input has no rows")
)
let((tab)
    tab = ycCsv::Decode("a,b,c\n1,2\n" ?header t)
    _Assert(tab->cell(1 3) == ycCodec::Missing  "decode: short row has Missing")
)
let((tab)
    tab = ycCsv::Decode("\na,b\n1,2\n" ?header t ?skipEmpty t)
    _AssertRows(tab->header() list("a" "b")  "decode: skipEmpty skips before header")
    _Assert(tab->rowCount() == 1  "decode: skipEmpty header data row count")
)
_AssertError(lambda(() ycCsv::Decode("a,a\n1,2\n" ?header t))  "decode: duplicate header errors")
_AssertErrorMsg(
    lambda(() ycCsv::Decode("a,b\n1,2,3\n" ?header t))
    "line 2"
    "decode: overlong row error includes line"
)
_AssertErrorMsg(
    lambda(() ycCsv::Decode("a,b\r\n1,2,3\r\n" ?header t))
    "line 2"
    "decode: overlong row error line with CRLF"
)
_AssertErrorMsg(
    lambda(() ycCsv::Decode("a\rb\r\"c\n"))
    "line 3"
    "decode: unterminated quote line with CR"
)
_AssertError(lambda(() ycCsv::Decode("a,b\n1,2,3\n" ?header list("x" "y")))  "decode: header list overlong row errors")
_AssertError(lambda(() ycCsv::Decode("" ?header list("a" "a")))  "decode: duplicate header list errors")
_AssertError(lambda(() ycCsv::Decode("" ?header list("a" 1)))  "decode: header list non-string errors")
_AssertError(lambda(() ycCsv::Decode("" ?header list("a" 1.5)))  "decode: header list flonum errors")
_AssertError(lambda(() ycCsv::Decode("" ?header list("a" 'b)))  "decode: header list symbol errors")

_TestChildDone = t

; END
