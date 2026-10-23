_TestWidthDone = nil

_Assert(ycUtf8::Width("") == 0  "width: empty")
_Assert(ycUtf8::Width("abc") == 3  "width: ascii")
_Assert(ycUtf8::Width("中文") == 4  "width: cjk")
_Assert(ycUtf8::Width("Ａ") == 2  "width: fullwidth")
_Assert(ycUtf8::Width("ｱ") == 1  "width: halfwidth")
_Assert(ycUtf8::Width("§") == 1  "width: ambiguous default")
_Assert(ycUtf8::Width("§" ?ambiguous 2) == 2  "width: ambiguous wide")
_Assert(ycUtf8::Width("①" ?ambiguous 2) == 2  "width: circled digit wide")
_Assert(ycUtf8::Width(strcat("e" intToChar(204) intToChar(129))) == 1  "width: combining mark")
_Assert(
    ycUtf8::Width(strcat("a" intToChar(226) intToChar(128) intToChar(141) "b")) == 2
    "width: zero width joiner"
)
_Assert(ycUtf8::Width(strcat(intToChar(9) intToChar(10))) == 0  "width: controls")
_Assert(
    ycUtf8::Width(
        strcat(
            intToChar(225) intToChar(132) intToChar(128)
            intToChar(225) intToChar(133) intToChar(161)
        )
    ) == 2
    "width: conjoining jamo"
)
_Assert(ycUtf8::Width("😀") == 2  "width: emoji")
_Assert(ycUtf8::Width(strcat(intToChar(194) intToChar(173))) == 1  "width: soft hyphen")
_Assert(
    ycUtf8::Width(strcat(intToChar(194) intToChar(173)) ?ambiguous 2) == 1
    "width: soft hyphen stays narrow"
)
_Assert(ycUtf8::Width(strcat("a" intToChar(128)) ?strict nil) == 2  "width: lenient replacement")
_AssertErrorMsg(lambda(() ycUtf8::Width("a" ?ambiguous 0)) "ycUtf8::Width: ambiguous must be 1 or 2"  "width: invalid ambiguous")
_AssertErrorMsg(lambda(() ycUtf8::Width(123 ?ambiguous 0)) "argument #1 should be a string"  "width: non-string")
_AssertError(lambda(() ycUtf8::Width(strcat(intToChar(128))))  "width: strict invalid")

_Assert(ycUtf8::CharWidth(97) == 1  "charWidth: ascii")
_Assert(ycUtf8::CharWidth(20013) == 2  "charWidth: cjk")
_Assert(ycUtf8::CharWidth(167) == 1  "charWidth: ambiguous default")
_Assert(ycUtf8::CharWidth(167 ?ambiguous 2) == 2  "charWidth: ambiguous wide")
_Assert(ycUtf8::CharWidth(769) == 0  "charWidth: combining mark")
_Assert(ycUtf8::CharWidth(8205) == 0  "charWidth: zero width joiner")
_Assert(ycUtf8::CharWidth(173) == 1  "charWidth: soft hyphen")
_Assert(ycUtf8::CharWidth(0) == 0  "charWidth: control")
_Assert(ycUtf8::CharWidth(127) == 0  "charWidth: delete")
_AssertError(lambda(() ycUtf8::CharWidth(-1))  "charWidth: negative")
_AssertError(lambda(() ycUtf8::CharWidth(55296))  "charWidth: surrogate")
_AssertError(lambda(() ycUtf8::CharWidth(1114112))  "charWidth: above max")
_AssertError(lambda(() ycUtf8::CharWidth(97 ?ambiguous 3))  "charWidth: invalid ambiguous")
_AssertErrorMsg(lambda(() ycUtf8::CharWidth("x")) "argument #1 should be an integer"  "charWidth: non-fixnum")

_TestWidthDone = t

; END
