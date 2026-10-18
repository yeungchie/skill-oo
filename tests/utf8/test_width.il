_TestWidthDone = nil

_assert(ycUtf8::width("") == 0  "width: empty")
_assert(ycUtf8::width("abc") == 3  "width: ascii")
_assert(ycUtf8::width("中文") == 4  "width: cjk")
_assert(ycUtf8::width("Ａ") == 2  "width: fullwidth")
_assert(ycUtf8::width("ｱ") == 1  "width: halfwidth")
_assert(ycUtf8::width("§") == 1  "width: ambiguous default")
_assert(ycUtf8::width("§" ?ambiguous 2) == 2  "width: ambiguous wide")
_assert(ycUtf8::width("①" ?ambiguous 2) == 2  "width: circled digit wide")
_assert(ycUtf8::width(strcat("e" intToChar(204) intToChar(129))) == 1  "width: combining mark")
_assert(
    ycUtf8::width(strcat("a" intToChar(226) intToChar(128) intToChar(141) "b")) == 2
    "width: zero width joiner"
)
_assert(ycUtf8::width(strcat(intToChar(9) intToChar(10))) == 0  "width: controls")
_assert(
    ycUtf8::width(
        strcat(
            intToChar(225) intToChar(132) intToChar(128)
            intToChar(225) intToChar(133) intToChar(161)
        )
    ) == 2
    "width: conjoining jamo"
)
_assert(ycUtf8::width("😀") == 2  "width: emoji")
_assert(ycUtf8::width(strcat(intToChar(194) intToChar(173))) == 1  "width: soft hyphen")
_assert(
    ycUtf8::width(strcat(intToChar(194) intToChar(173)) ?ambiguous 2) == 1
    "width: soft hyphen stays narrow"
)
_assert(ycUtf8::width(strcat("a" intToChar(128)) ?strict nil) == 2  "width: lenient replacement")
_assertError(lambda(() ycUtf8::width("a" ?ambiguous 0))  "width: invalid ambiguous")
_assertError(lambda(() ycUtf8::width(strcat(intToChar(128))))  "width: strict invalid")

_assert(ycUtf8::charWidth(97) == 1  "charWidth: ascii")
_assert(ycUtf8::charWidth(20013) == 2  "charWidth: cjk")
_assert(ycUtf8::charWidth(167) == 1  "charWidth: ambiguous default")
_assert(ycUtf8::charWidth(167 ?ambiguous 2) == 2  "charWidth: ambiguous wide")
_assert(ycUtf8::charWidth(769) == 0  "charWidth: combining mark")
_assert(ycUtf8::charWidth(8205) == 0  "charWidth: zero width joiner")
_assert(ycUtf8::charWidth(173) == 1  "charWidth: soft hyphen")
_assert(ycUtf8::charWidth(0) == 0  "charWidth: control")
_assert(ycUtf8::charWidth(127) == 0  "charWidth: delete")
_assertError(lambda(() ycUtf8::charWidth(-1))  "charWidth: negative")
_assertError(lambda(() ycUtf8::charWidth(55296))  "charWidth: surrogate")
_assertError(lambda(() ycUtf8::charWidth(1114112))  "charWidth: above max")
_assertError(lambda(() ycUtf8::charWidth(97 ?ambiguous 3))  "charWidth: invalid ambiguous")

_TestWidthDone = t

; END
