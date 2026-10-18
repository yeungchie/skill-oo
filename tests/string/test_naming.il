_TestNamingDone = nil

_assert(ycString::words("HTMLParser") == list("HTML" "Parser")  "words: acronym boundary")
_assert(ycString::words("camelCase") == list("camel" "Case")  "words: camel boundary")
_assert(ycString::words("foo_bar-baz") == list("foo" "bar" "baz")  "words: separators")
_assert(ycString::words("foo2Bar") == list("foo2" "Bar")  "words: digit to upper")
_assert(ycString::words("  ") == nil  "words: no words")
_assert(ycString::words("中文 abc") == list("中文" "abc")  "words: cjk kept")

_assert(ycString::joinWords(list("a" "b")) == "a_b"  "joinWords: snake default")
_assert(ycString::joinWords(list("a" "b") ?style "kebab") == "a-b"  "joinWords: kebab")
_assert(ycString::joinWords(list("HTML" "Parser") ?style "camel") == "htmlParser"  "joinWords: camel")
_assert(ycString::joinWords(list("HTML" "Parser") ?style "pascal") == "HtmlParser"  "joinWords: pascal")
_assertErrorMsg(
    lambda(() ycString::joinWords(list("a") ?style "dot"))
    "ycString::joinWords: unknown style"
    "joinWords: unknown style"
)

_assert(ycString::toSnake("HTMLParser") == "html_parser"  "toSnake: acronym")
_assert(ycString::toKebab("HTMLParser") == "html-parser"  "toKebab: kebab case")
_assert(ycString::toCamel("html_parser") == "htmlParser"  "toCamel: from snake")
_assert(ycString::toPascal("html_parser") == "HtmlParser"  "toPascal: from snake")
_assert(ycString::sanitize("1st place") == "_1st_place"  "sanitize: digit prefix")
_assertErrorMsg(
    lambda(() ycString::sanitize("!!!"))
    "ycString::sanitize: no valid characters"
    "sanitize: no valid chars"
)

_TestNamingDone = t

; END
