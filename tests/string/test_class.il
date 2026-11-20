_TestClassDone = nil

; ---- 构造与取值 ----
let((s)
    s = ycString::String("abc")
    _Assert(className(s) == 'ycString::String  "String: constructor returns ycString::String")
    _Assert(s->str() == "abc"  "String: str returns the original value")
    _Assert(printself(s) == "ycString::String(\"abc\")"  "String: printself format")
)
_Assert(ycString::String("")->str() == ""  "String: empty input")
_Assert(makeInstance('ycString::String)->str() == ""  "String: direct makeInstance starts empty")
_AssertErrorMsg(
    lambda(() makeInstance('ycString::String ?value 123))
    "?value must be a string"
    "String: direct makeInstance rejects a non-string value"
)
_AssertErrorMsg(
    lambda(() ycString::String(123))
    "argument #1 should be a string"
    "String: constructor rejects a non-string"
)
_Assert(printself(ycString::String("a\nb")) == "ycString::String(\"a\\nb\")"  "String: printself escapes the value")

let((a b)
    a = ycString::String("same")
    b = ycString::String("same")
    _Assert(a != b  "String: equal values are distinct instances")
    _Assert(a->str() == b->str()  "String: equal values compare through str")
)

; ---- 不可变与返回新对象 ----
let((s r)
    s = ycString::String("  Ab  ")
    r = s->trim()
    _Assert(className(r) == 'ycString::String  "String: trim returns a String")
    _Assert(r->str() == "Ab"  "String: trim value")
    _Assert(s->str() == "  Ab  "  "String: trim leaves the original unchanged")
    _Assert(s != r  "String: trim returns a different object")
)

let((s r)
    s = ycString::String("abcabc")
    r = s->replace("a" "X")
    _Assert(r->str() == "XbcXbc"  "String: replace value")
    _Assert(s->str() == "abcabc"  "String: replace leaves the original unchanged")
    _Assert(s != r  "String: replace returns a different object")
)

; ---- 修剪 ----
_Assert(ycString::String("  ab  ")->trim()->str() == "ab"  "String: trim default chars")
_Assert(ycString::String("xxabxx")->trim(?chars "x")->str() == "ab"  "String: trim custom chars")
_Assert(ycString::String("  ab  ")->trimStart()->str() == "ab  "  "String: trimStart")
_Assert(ycString::String("  ab  ")->trimEnd()->str() == "  ab"  "String: trimEnd")

; ---- 补宽与宽度 ----
_Assert(ycString::String("ab")->pad(5 ?fill "-")->str() == "ab---"  "String: pad end")
_Assert(ycString::String("ab")->pad(5 ?side "start" ?fill "-")->str() == "---ab"  "String: pad start")
_Assert(ycString::String("中")->pad(4 ?unit "char" ?fill "-")->str() == "中---"  "String: pad char unit")
_Assert(ycString::String("ab")->pad(1)->str() == "ab"  "String: pad never truncates")
_Assert(ycString::String("中文")->width() == 4  "String: width display")
_Assert(ycString::String("中文")->width(?unit "char") == 2  "String: width char")
_Assert(ycString::String("")->width() == 0  "String: width empty")

; ---- 切分与查询 ----
_Assert(ycString::String("  a\tb\n c ")->split() == list("a" "b" "c")  "String: split whitespace")
_Assert(ycString::String("a,,b")->split(?sep ",") == list("a" "" "b")  "String: split literal keeps empties")
_Assert(ycString::String("a,,b")->split(?sep "," ?keepEmpty nil) == list("a" "b")  "String: split drops empties")
_Assert(ycString::String("a1b2c")->split(?sep "[0-9]" ?regex t) == list("a" "b" "c")  "String: split regex")
_Assert(ycString::String("-")->join(list("a" "b"))->str() == "a-b"  "String: join uses the value as separator")
_Assert(ycString::String("")->join(list("a" "b"))->str() == "ab"  "String: join with an empty separator")
_Assert(ycString::String(",")->join(nil)->str() == ""  "String: join an empty list")
_AssertErrorMsg(
    lambda(() ycString::String("-")->join(list("a" 2)))
    "item #2 is not a string"
    "String: join rejects a non-string item"
)
_Assert(ycString::String("abc")->startsWith("ab") == t  "String: startsWith hit")
_Assert(ycString::String("abc")->startsWith("bc") == nil  "String: startsWith miss")
_Assert(ycString::String("abc")->startsWith("") == t  "String: startsWith empty prefix")
_Assert(ycString::String("abc")->endsWith("bc") == t  "String: endsWith hit")
_Assert(ycString::String("abc")->endsWith("ab") == nil  "String: endsWith miss")
_Assert(ycString::String("abc")->endsWith("") == t  "String: endsWith empty suffix")
_Assert(ycString::String("banana")->count("a") == 3  "String: count literal")
_Assert(ycString::String("banana")->count("a+" ?regex t) == 3  "String: count regex")
_Assert(ycString::String("HTMLParser")->words() == list("HTML" "Parser")  "String: words")

; ---- 替换、转义与命名 ----
_Assert(ycString::String("baaacaa")->replace("a+" "X" ?regex t)->str() == "bXcX"  "String: replace regex")
_Assert(ycString::String("abc")->replace("x" "y")->str() == "abc"  "String: replace no match")
_Assert(ycString::String("a\nb")->escape()->str() == "a\\nb"  "String: escape")
_Assert(ycString::String("a\nb")->escape(?quote t)->str() == "\"a\\nb\""  "String: escape quote")
_Assert(ycString::String("a\\nb")->unescape()->str() == "a\nb"  "String: unescape")
_Assert(ycString::String("HTMLParser")->sanitize()->str() == "html_parser"  "String: sanitize snake")
_Assert(ycString::String("HTMLParser")->sanitize(?style "camel")->str() == "htmlParser"  "String: sanitize camel")
_Assert(ycString::String("HTMLParser")->toSnake()->str() == "html_parser"  "String: toSnake")
_Assert(ycString::String("HTMLParser")->toKebab()->str() == "html-parser"  "String: toKebab")
_Assert(ycString::String("HTMLParser")->toCamel()->str() == "htmlParser"  "String: toCamel")
_Assert(ycString::String("HTMLParser")->toPascal()->str() == "HtmlParser"  "String: toPascal")

; ---- 自然序比较与链式组合 ----
_Assert(ycString::String("VDD2")->naturalLess("VDD10") == t  "String: naturalLess true")
_Assert(ycString::String("VDD10")->naturalLess("VDD2") == nil  "String: naturalLess false")
_Assert(ycString::String("a")->naturalLess("A") == nil  "String: naturalLess falls back to the raw string")
_Assert(ycString::String("  HTML Parser  ")->trim()->toSnake()->str() == "html_parser"  "String: chain trim and toSnake")
_Assert(ycString::String("  HTML Parser  ")->trim()->toKebab()->str() == "html-parser"  "String: chain trim and toKebab")
_Assert(ycString::String("  HTML Parser  ")->trim()->toCamel()->str() == "htmlParser"  "String: chain trim and toCamel")
_Assert(ycString::String("  HTML Parser  ")->trim()->toPascal()->str() == "HtmlParser"  "String: chain trim and toPascal")
_Assert(ycString::String(" a\tb\nc ")->trim()->split() == list("a" "b" "c")  "String: chain trim and split")
_Assert(ycString::String(" ab ")->trim()->pad(4 ?fill "_")->str() == "ab__"  "String: chain trim and pad")
_Assert(ycString::String("ab")->pad(5 ?fill "-")->replace("-" "_")->str() == "ab___"  "String: chain pad and replace")
_Assert(ycString::String("-")->join(list("a" "b"))->toPascal()->str() == "AB"  "String: chain join and toPascal")

; ---- 错误路径 ----
_AssertErrorMsg(
    lambda(() ycString::String("a")->pad(-1))
    "width must be a non-negative integer"
    "String: pad rejects a negative width"
)
_AssertErrorMsg(
    lambda(() ycString::String("a")->width(?unit "px"))
    "unknown unit"
    "String: width rejects an unknown unit"
)
_AssertErrorMsg(
    lambda(() ycString::String("a")->count(""))
    "search string must not be empty"
    "String: count rejects an empty search string"
)
_AssertErrorMsg(
    lambda(() ycString::String("!!!")->sanitize())
    "no valid characters"
    "String: sanitize rejects a string without valid characters"
)
_AssertErrorMsg(
    lambda(() ycString::String("a\\q")->unescape(?strict t))
    "unknown escape"
    "String: unescape strict rejects an unknown escape"
)

_TestChildDone = t
