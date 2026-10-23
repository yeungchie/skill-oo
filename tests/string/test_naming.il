_TestNamingDone = nil

_assert(ycString::Words("HTMLParser") == list("HTML" "Parser")  "words: acronym boundary")
_assert(ycString::Words("camelCase") == list("camel" "Case")  "words: camel boundary")
_assert(ycString::Words("foo_bar-baz") == list("foo" "bar" "baz")  "words: separators")
_assert(ycString::Words("foo2Bar") == list("foo2" "Bar")  "words: digit to upper")
_assert(ycString::Words("  ") == nil  "words: no words")
_assert(ycString::Words("中文 abc") == list("中文" "abc")  "words: cjk kept")

_assert(ycString::JoinWords(list("a" "b")) == "a_b"  "joinWords: snake default")
_assert(ycString::JoinWords(list("a" "b") ?style "kebab") == "a-b"  "joinWords: kebab")
_assert(ycString::JoinWords(list("HTML" "Parser") ?style "camel") == "htmlParser"  "joinWords: camel")
_assert(ycString::JoinWords(list("HTML" "Parser") ?style "pascal") == "HtmlParser"  "joinWords: pascal")
_assertErrorMsg(
    lambda(() ycString::JoinWords(list("a") ?style "dot"))
    "ycString::JoinWords: unknown style"
    "joinWords: unknown style"
)

_assert(ycString::ToSnake("HTMLParser") == "html_parser"  "toSnake: acronym")
_assert(ycString::ToKebab("HTMLParser") == "html-parser"  "toKebab: kebab case")
_assert(ycString::ToCamel("html_parser") == "htmlParser"  "toCamel: from snake")
_assert(ycString::ToPascal("html_parser") == "HtmlParser"  "toPascal: from snake")
_assert(ycString::Sanitize("1st place") == "_1st_place"  "sanitize: digit prefix")
_assertErrorMsg(
    lambda(() ycString::Sanitize("!!!"))
    "ycString::Sanitize: no valid characters"
    "sanitize: no valid chars"
)

_TestNamingDone = t

; END
