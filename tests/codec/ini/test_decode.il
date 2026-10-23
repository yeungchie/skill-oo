;--------------------------
; Program  : ycIni tests(test_decode.il)
; Language : Cadence Skill
;--------------------------

let((t_v t_s)
    t_v = ycIni::Decode("")
    _assert(length(t_v) == 0  "decode: empty document")
    _assert(t_v["absent"] == ycCodec:::Missing  "decode: missing key is Missing")

    t_v = ycIni::Decode("\n \t\n# comment\n; comment\n")
    _assert(length(t_v) == 0  "decode: blank and comment only")

    t_v = ycIni::Decode("a = 1\nb = value\nc =\nd = x = y\n")
    _assert(t_v["a"] == "1"  "decode: root scalar")
    _assert(t_v["b"] == "value"  "decode: root value")
    _assert(t_v["c"] == ""  "decode: empty value")
    _assert(t_v["d"] == "x = y"  "decode: later delimiter stays in value")

    t_v = ycIni::Decode("  spaced  =  value  \n")
    _assert(t_v["spaced"] == "value"  "decode: trims key and value")
    _assert(t_v["  spaced  "] == ycCodec:::Missing  "decode: untrimmed key is absent")

    t_v = ycIni::Decode("s = \"quoted\"\n")
    _assert(t_v["s"] == "\"quoted\""  "decode: quotes are literal")
    t_v = ycIni::Decode(strcat("s = C:" intToChar(92) "Users" intToChar(92) "name\n"))
    _assert(t_v["s"] == strcat("C:" intToChar(92) "Users" intToChar(92) "name")  "decode: backslashes are literal")

    t_v = ycIni::Decode("# comment\na = 1\n  ; indented comment\n")
    _assert(t_v["a"] == "1"  "decode: leading-whitespace comments")
    t_v = ycIni::Decode("a = value ; not comment\nb = value # not comment\n")
    _assert(t_v["a"] == "value ; not comment"  "decode: semicolon is not inline comment")
    _assert(t_v["b"] == "value # not comment"  "decode: hash is not inline comment")

    t_v = ycIni::Decode("[server]\nhost = localhost\nport = 8080\n")
    _assert(t_v["server"]["host"] == "localhost"  "decode: section scalar")
    _assert(t_v["server"]["port"] == "8080"  "decode: section value is string")

    t_v = ycIni::Decode("root = r\n[one]\na = 1\n[two]\nb = 2\n")
    _assert(t_v["root"] == "r"  "decode: root beside sections")
    _assert(t_v["one"]["a"] == "1"  "decode: first section")
    _assert(t_v["two"]["b"] == "2"  "decode: second section")

    t_v = ycIni::Decode("[ empty ]\n")
    _assert(length(t_v["empty"]) == 0  "decode: empty section")
    t_v = ycIni::Decode("[s]\n")
    _assert(length(t_v["s"]) == 0  "decode: section with no keys")

    t_v = ycIni::Decode("  [ s ]  \n  key = v  \n")
    _assert(t_v["s"]["key"] == "v"  "decode: indented section and key")

    t_v = ycIni::Decode("[A]\nx = 1\n[a]\nx = 2\n")
    _assert(t_v["A"]["x"] == "1" && t_v["a"]["x"] == "2"  "decode: section names are case sensitive")

    t_v = ycIni::Decode("[a.b]\nx = 1\n")
    _assert(t_v["a.b"]["x"] == "1"  "decode: dotted section name is literal")
    _assert(t_v["a"] == ycCodec:::Missing  "decode: no implicit dotted nesting")

    t_v = ycIni::Decode("[a=b]\nk = v\n")
    _assert(t_v["a=b"]["k"] == "v"  "decode: equals in section name")
    t_v = ycIni::Decode("[a#b]\nk = v\n")
    _assert(t_v["a#b"]["k"] == "v"  "decode: hash in section name")
    t_v = ycIni::Decode("[a; b]\nk = v\n")
    _assert(t_v["a; b"]["k"] == "v"  "decode: semicolon in section name")
    t_v = ycIni::Decode("[a]   \n")
    _assert(length(t_v["a"]) == 0  "decode: trailing spaces after header")
    _assertError(lambda(() ycIni::Decode("[a] trailing   \n"))  "decode: trailing header text errors")

    t_v = ycIni::Decode("a = 1\na = 2\n" ?duplicates "first")
    _assert(t_v["a"] == "1"  "decode: duplicate root key first")
    t_v = ycIni::Decode("a = 1\na = 2\n" ?duplicates "last")
    _assert(t_v["a"] == "2"  "decode: duplicate root key last")

    t_v = ycIni::Decode("[s]\na = 1\n[s]\na = 2\n" ?duplicates "first")
    _assert(t_v["s"]["a"] == "1"  "decode: duplicate section first")
    t_v = ycIni::Decode("[s]\na = 1\n[s]\na = 2\n" ?duplicates "last")
    _assert(t_v["s"]["a"] == "2"  "decode: duplicate section last")
    t_v = ycIni::Decode("[s]\na = 1\n[s]\nb = 2\n" ?duplicates "first")
    _assert(t_v["s"]["a"] == "1" && t_v["s"]["b"] == "2"  "decode: first section merges new keys")

    t_v = ycIni::Decode("a:1\n[s]\nb:2\n" ?delimiter ":")
    _assert(t_v["a"] == "1"  "decode: custom delimiter root")
    _assert(t_v["s"]["b"] == "2"  "decode: custom delimiter section")
    t_v = ycIni::Decode("a:b:c\n" ?delimiter ":")
    _assert(t_v["a"] == "b:c"  "decode: custom delimiter keeps later colon")
    t_v = ycIni::Decode("a=b:c\n" ?delimiter ":")
    _assert(t_v["a=b"] == "c"  "decode: custom delimiter allows equals in key")
    t_v = ycIni::Decode("a = 1\n" ?delimiter "=")
    _assert(t_v["a"] == "1"  "decode: explicit default delimiter")

    t_s = strcat(intToChar(239) intToChar(187) intToChar(191) "a=1\r\n[s]\r\nb=2\r")
    t_v = ycIni::Decode(t_s)
    _assert(t_v["a"] == "1"  "decode: BOM and CRLF")
    _assert(t_v["s"]["b"] == "2"  "decode: CR line ending")
    t_v = ycIni::Decode("a=1\rb=2\r")
    _assert(t_v["a"] == "1" && t_v["b"] == "2"  "decode: lone CR line endings")

    t_v = ycIni::Decode("名字 = 值\n")
    _assert(t_v["名字"] == "值"  "decode: non-ASCII bytes preserved")
    t_v = ycIni::Decode("a = x\t y\n")
    _assert(t_v["a"] == "x\t y"  "decode: internal tab preserved")

    _assertError(lambda(() ycIni::Decode("a = 1\na = 2\n"))  "decode: duplicate key errors")
    _assertError(lambda(() ycIni::Decode("[s]\n[s]\n"))  "decode: duplicate section errors")
    _assertError(lambda(() ycIni::Decode("a = 1\n[a]\n"))  "decode: root key and section conflict")
    _assertError(lambda(() ycIni::Decode("a\n"))  "decode: missing delimiter errors")
    _assertError(lambda(() ycIni::Decode("= value\n"))  "decode: empty key errors")
    _assertError(lambda(() ycIni::Decode("[]\n"))  "decode: empty section name errors")
    _assertError(lambda(() ycIni::Decode("[a\n"))  "decode: unterminated header errors")
    _assertError(lambda(() ycIni::Decode("[a]x\n"))  "decode: trailing header text errors")
    _assertError(lambda(() ycIni::Decode("[a] ; comment\n"))  "decode: inline comment after header errors")
    _assertError(lambda(() ycIni::Decode("[a[b]]\n"))  "decode: nested bracket in section name errors")
    _assertError(lambda(() ycIni::Decode("[a]b]\n"))  "decode: closing bracket after header errors")
    _assertError(lambda(() ycIni::Decode("[a]\n[]\n"))  "decode: later empty section errors")

    _assertError(lambda(() ycIni::Decode(strcat("a = " intToChar(127) "\n")))  "decode: DEL in value errors")
    _assertError(lambda(() ycIni::Decode(strcat("a = " intToChar(1) "\n")))  "decode: control in value errors")
    _assertError(lambda(() ycIni::Decode(strcat("a" intToChar(127) " = v\n")))  "decode: DEL in key errors")
    _assertError(lambda(() ycIni::Decode(strcat("[" intToChar(127) "]\n")))  "decode: DEL in section errors")
    t_v = ycIni::Decode(strcat("a" intToChar(9) "b = v\n"))
    _assert(t_v["a\tb"] == "v"  "decode: internal tab in key is legal")
    t_v = ycIni::Decode(strcat("a = v" intToChar(9) "x\n"))
    _assert(t_v["a"] == strcat("v" intToChar(9) "x")  "decode: internal tab in value is legal")

    _assertError(lambda(() ycIni::Decode(1))  "decode: non-string input errors")
    _assertError(lambda(() ycIni::Decode("a = 1" ?delimiter ""))  "decode: empty delimiter errors")
    _assertError(lambda(() ycIni::Decode("a = 1" ?delimiter "::"))  "decode: multi-byte delimiter errors")
    _assertError(lambda(() ycIni::Decode("a = 1" ?delimiter " "))  "decode: space delimiter errors")
    _assertError(lambda(() ycIni::Decode("a = 1" ?delimiter "\t"))  "decode: tab delimiter errors")
    _assertError(lambda(() ycIni::Decode("a = 1" ?delimiter "#"))  "decode: hash delimiter errors")
    _assertError(lambda(() ycIni::Decode("a = 1" ?delimiter ";"))  "decode: semicolon delimiter errors")
    _assertError(lambda(() ycIni::Decode("a = 1" ?delimiter "["))  "decode: bracket delimiter errors")
    _assertError(lambda(() ycIni::Decode("a = 1" ?delimiter "]"))  "decode: closing bracket delimiter errors")
    _assertError(lambda(() ycIni::Decode("a = 1" ?delimiter 1))  "decode: non-string delimiter errors")
    _assertError(lambda(() ycIni::Decode("a = 1" ?duplicates "bogus"))  "decode: invalid duplicate policy errors")
    _assertError(lambda(() ycIni::Decode("a = 1" ?duplicates 1))  "decode: non-string duplicate policy errors")

    _assertErrorMsg(lambda(() ycIni::Decode("a = 1\nbad\n")) "line 2"  "decode: error line number")
    _assertErrorMsg(lambda(() ycIni::Decode("a = 1\nbad\n")) "ycIni::Decode:"  "decode: error context")
    _assertErrorMsg(lambda(() ycIni::Decode("a = 1" ?delimiter "::")) "delimiter"  "decode: delimiter error message")
)
_TestDecodeDone = t

; END
