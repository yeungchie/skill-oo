;--------------------------
; Program  : ycIni tests(test_decode.il)
; Language : Cadence Skill
;--------------------------

let((v item)
    v = ycIni::Decode("")
    _Assert(length(v) == 0  "decode: empty document")
    _Assert(v["absent"] == ycCodec::Missing  "decode: missing key is Missing")

    v = ycIni::Decode("\n \t\n# comment\n; comment\n")
    _Assert(length(v) == 0  "decode: blank and comment only")

    v = ycIni::Decode("a = 1\nb = value\nc =\nd = x = y\n")
    _Assert(v["a"] == "1"  "decode: root scalar")
    _Assert(v["b"] == "value"  "decode: root value")
    _Assert(v["c"] == ""  "decode: empty value")
    _Assert(v["d"] == "x = y"  "decode: later delimiter stays in value")

    v = ycIni::Decode("  spaced  =  value  \n")
    _Assert(v["spaced"] == "value"  "decode: trims key and value")
    _Assert(v["  spaced  "] == ycCodec::Missing  "decode: untrimmed key is absent")

    v = ycIni::Decode("s = \"quoted\"\n")
    _Assert(v["s"] == "\"quoted\""  "decode: quotes are literal")
    v = ycIni::Decode(strcat("s = C:" intToChar(92) "Users" intToChar(92) "name\n"))
    _Assert(v["s"] == strcat("C:" intToChar(92) "Users" intToChar(92) "name")  "decode: backslashes are literal")

    v = ycIni::Decode("# comment\na = 1\n  ; indented comment\n")
    _Assert(v["a"] == "1"  "decode: leading-whitespace comments")
    v = ycIni::Decode("a = value ; not comment\nb = value # not comment\n")
    _Assert(v["a"] == "value ; not comment"  "decode: semicolon is not inline comment")
    _Assert(v["b"] == "value # not comment"  "decode: hash is not inline comment")

    v = ycIni::Decode("[server]\nhost = localhost\nport = 8080\n")
    _Assert(v["server"]["host"] == "localhost"  "decode: section scalar")
    _Assert(v["server"]["port"] == "8080"  "decode: section value is string")

    v = ycIni::Decode("root = r\n[one]\na = 1\n[two]\nb = 2\n")
    _Assert(v["root"] == "r"  "decode: root beside sections")
    _Assert(v["one"]["a"] == "1"  "decode: first section")
    _Assert(v["two"]["b"] == "2"  "decode: second section")

    v = ycIni::Decode("[ empty ]\n")
    _Assert(length(v["empty"]) == 0  "decode: empty section")
    v = ycIni::Decode("[s]\n")
    _Assert(length(v["s"]) == 0  "decode: section with no keys")

    v = ycIni::Decode("  [ s ]  \n  key = v  \n")
    _Assert(v["s"]["key"] == "v"  "decode: indented section and key")

    v = ycIni::Decode("[A]\nx = 1\n[a]\nx = 2\n")
    _Assert(v["A"]["x"] == "1" && v["a"]["x"] == "2"  "decode: section names are case sensitive")

    v = ycIni::Decode("[a.b]\nx = 1\n")
    _Assert(v["a.b"]["x"] == "1"  "decode: dotted section name is literal")
    _Assert(v["a"] == ycCodec::Missing  "decode: no implicit dotted nesting")

    v = ycIni::Decode("[a=b]\nk = v\n")
    _Assert(v["a=b"]["k"] == "v"  "decode: equals in section name")
    v = ycIni::Decode("[a#b]\nk = v\n")
    _Assert(v["a#b"]["k"] == "v"  "decode: hash in section name")
    v = ycIni::Decode("[a; b]\nk = v\n")
    _Assert(v["a; b"]["k"] == "v"  "decode: semicolon in section name")
    v = ycIni::Decode("[a]   \n")
    _Assert(length(v["a"]) == 0  "decode: trailing spaces after header")
    _AssertError(lambda(() ycIni::Decode("[a] trailing   \n"))  "decode: trailing header text errors")

    v = ycIni::Decode("a = 1\na = 2\n" ?duplicates "first")
    _Assert(v["a"] == "1"  "decode: duplicate root key first")
    v = ycIni::Decode("a = 1\na = 2\n" ?duplicates "last")
    _Assert(v["a"] == "2"  "decode: duplicate root key last")

    v = ycIni::Decode("[s]\na = 1\n[s]\na = 2\n" ?duplicates "first")
    _Assert(v["s"]["a"] == "1"  "decode: duplicate section first")
    v = ycIni::Decode("[s]\na = 1\n[s]\na = 2\n" ?duplicates "last")
    _Assert(v["s"]["a"] == "2"  "decode: duplicate section last")
    v = ycIni::Decode("[s]\na = 1\n[s]\nb = 2\n" ?duplicates "first")
    _Assert(v["s"]["a"] == "1" && v["s"]["b"] == "2"  "decode: first section merges new keys")

    v = ycIni::Decode("a:1\n[s]\nb:2\n" ?delimiter ":")
    _Assert(v["a"] == "1"  "decode: custom delimiter root")
    _Assert(v["s"]["b"] == "2"  "decode: custom delimiter section")
    v = ycIni::Decode("a:b:c\n" ?delimiter ":")
    _Assert(v["a"] == "b:c"  "decode: custom delimiter keeps later colon")
    v = ycIni::Decode("a=b:c\n" ?delimiter ":")
    _Assert(v["a=b"] == "c"  "decode: custom delimiter allows equals in key")
    v = ycIni::Decode("a = 1\n" ?delimiter "=")
    _Assert(v["a"] == "1"  "decode: explicit default delimiter")

    item = strcat(intToChar(239) intToChar(187) intToChar(191) "a=1\r\n[s]\r\nb=2\r")
    v = ycIni::Decode(item)
    _Assert(v["a"] == "1"  "decode: BOM and CRLF")
    _Assert(v["s"]["b"] == "2"  "decode: CR line ending")
    v = ycIni::Decode("a=1\rb=2\r")
    _Assert(v["a"] == "1" && v["b"] == "2"  "decode: lone CR line endings")

    v = ycIni::Decode("名字 = 值\n")
    _Assert(v["名字"] == "值"  "decode: non-ASCII bytes preserved")
    v = ycIni::Decode("a = x\t y\n")
    _Assert(v["a"] == "x\t y"  "decode: internal tab preserved")

    _AssertError(lambda(() ycIni::Decode("a = 1\na = 2\n"))  "decode: duplicate key errors")
    _AssertError(lambda(() ycIni::Decode("[s]\n[s]\n"))  "decode: duplicate section errors")
    _AssertError(lambda(() ycIni::Decode("a = 1\n[a]\n"))  "decode: root key and section conflict")
    _AssertError(lambda(() ycIni::Decode("a\n"))  "decode: missing delimiter errors")
    _AssertError(lambda(() ycIni::Decode("= value\n"))  "decode: empty key errors")
    _AssertError(lambda(() ycIni::Decode("[]\n"))  "decode: empty section name errors")
    _AssertError(lambda(() ycIni::Decode("[a\n"))  "decode: unterminated header errors")
    _AssertError(lambda(() ycIni::Decode("[a]x\n"))  "decode: trailing header text errors")
    _AssertError(lambda(() ycIni::Decode("[a] ; comment\n"))  "decode: inline comment after header errors")
    _AssertError(lambda(() ycIni::Decode("[a[b]]\n"))  "decode: nested bracket in section name errors")
    _AssertError(lambda(() ycIni::Decode("[a]b]\n"))  "decode: closing bracket after header errors")
    _AssertError(lambda(() ycIni::Decode("[a]\n[]\n"))  "decode: later empty section errors")

    _AssertError(lambda(() ycIni::Decode(strcat("a = " intToChar(127) "\n")))  "decode: DEL in value errors")
    _AssertError(lambda(() ycIni::Decode(strcat("a = " intToChar(1) "\n")))  "decode: control in value errors")
    _AssertError(lambda(() ycIni::Decode(strcat("a" intToChar(127) " = v\n")))  "decode: DEL in key errors")
    _AssertError(lambda(() ycIni::Decode(strcat("[" intToChar(127) "]\n")))  "decode: DEL in section errors")
    v = ycIni::Decode(strcat("a" intToChar(9) "b = v\n"))
    _Assert(v["a\tb"] == "v"  "decode: internal tab in key is legal")
    v = ycIni::Decode(strcat("a = v" intToChar(9) "x\n"))
    _Assert(v["a"] == strcat("v" intToChar(9) "x")  "decode: internal tab in value is legal")

    _AssertError(lambda(() ycIni::Decode(1))  "decode: non-string input errors")
    _AssertError(lambda(() ycIni::Decode("a = 1" ?delimiter ""))  "decode: empty delimiter errors")
    _AssertError(lambda(() ycIni::Decode("a = 1" ?delimiter "::"))  "decode: multi-byte delimiter errors")
    _AssertError(lambda(() ycIni::Decode("a = 1" ?delimiter " "))  "decode: space delimiter errors")
    _AssertError(lambda(() ycIni::Decode("a = 1" ?delimiter "\t"))  "decode: tab delimiter errors")
    _AssertError(lambda(() ycIni::Decode("a = 1" ?delimiter "#"))  "decode: hash delimiter errors")
    _AssertError(lambda(() ycIni::Decode("a = 1" ?delimiter ";"))  "decode: semicolon delimiter errors")
    _AssertError(lambda(() ycIni::Decode("a = 1" ?delimiter "["))  "decode: bracket delimiter errors")
    _AssertError(lambda(() ycIni::Decode("a = 1" ?delimiter "]"))  "decode: closing bracket delimiter errors")
    _AssertError(lambda(() ycIni::Decode("a = 1" ?delimiter 1))  "decode: non-string delimiter errors")
    _AssertError(lambda(() ycIni::Decode("a = 1" ?duplicates "bogus"))  "decode: invalid duplicate policy errors")
    _AssertError(lambda(() ycIni::Decode("a = 1" ?duplicates 1))  "decode: non-string duplicate policy errors")

    _AssertErrorMsg(lambda(() ycIni::Decode("a = 1\nbad\n")) "line 2"  "decode: error line number")
    _AssertErrorMsg(lambda(() ycIni::Decode("a = 1\nbad\n")) "ycIni::Decode:"  "decode: error context")
    _AssertErrorMsg(lambda(() ycIni::Decode("a = 1" ?delimiter "::")) "delimiter"  "decode: delimiter error message")
)
_TestChildDone = t

; END
