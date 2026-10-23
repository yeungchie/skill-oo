_TestNamingDone = nil

_Assert(ycString::Words("HTMLParser") == list("HTML" "Parser")  "words: acronym boundary")
_Assert(ycString::Words("camelCase") == list("camel" "Case")  "words: camel boundary")
_Assert(ycString::Words("foo_bar-baz") == list("foo" "bar" "baz")  "words: separators")
_Assert(ycString::Words("foo2Bar") == list("foo2" "Bar")  "words: digit to upper")
_Assert(ycString::Words("  ") == nil  "words: no words")
_Assert(ycString::Words("中文 abc") == list("中文" "abc")  "words: cjk kept")

_Assert(ycString::JoinWords(list("a" "b")) == "a_b"  "JoinWords: snake default")
_Assert(ycString::JoinWords(list("a" "b") ?style "kebab") == "a-b"  "JoinWords: kebab")
_Assert(ycString::JoinWords(list("HTML" "Parser") ?style "camel") == "htmlParser"  "JoinWords: camel")
_Assert(ycString::JoinWords(list("HTML" "Parser") ?style "pascal") == "HtmlParser"  "JoinWords: pascal")
_AssertErrorMsg(
    lambda(() ycString::JoinWords(list("a") ?style "dot"))
    "ycString::JoinWords: unknown style"
    "JoinWords: unknown style"
)

_Assert(ycString::ToSnake("HTMLParser") == "html_parser"  "toSnake: acronym")
_Assert(ycString::ToKebab("HTMLParser") == "html-parser"  "toKebab: kebab case")
_Assert(ycString::ToCamel("html_parser") == "htmlParser"  "toCamel: from snake")
_Assert(ycString::ToPascal("html_parser") == "HtmlParser"  "toPascal: from snake")
_Assert(ycString::Sanitize("1st place") == "_1st_place"  "sanitize: digit prefix")
_AssertErrorMsg(
    lambda(() ycString::Sanitize("!!!"))
    "ycString::Sanitize: no valid characters"
    "sanitize: no valid chars"
)

_TestNamingDone = t

; END
