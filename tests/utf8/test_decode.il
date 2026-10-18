_TestDecodeDone = nil

_assert(ycUtf8::decode("") == nil  "decode: empty")
_assert(ycUtf8::decode("abc") == list(97 98 99)  "decode: ascii")
_assert(ycUtf8::decode("中") == list(20013)  "decode: cjk")
_assert(ycUtf8::decode(strcat(intToChar(195) intToChar(169))) == list(233)  "decode: 2-byte")
_assert(ycUtf8::decode(strcat(intToChar(226) intToChar(130) intToChar(172))) == list(8364)  "decode: 3-byte")
_assert(ycUtf8::decode(strcat(intToChar(240) intToChar(159) intToChar(152) intToChar(128))) == list(128512)  "decode: 4-byte")
_assert(ycUtf8::decode(strcat(intToChar(127))) == list(127)  "decode: u+007f")
_assert(ycUtf8::decode(strcat(intToChar(194) intToChar(128))) == list(128)  "decode: u+0080")
_assert(ycUtf8::decode(strcat(intToChar(223) intToChar(191))) == list(2047)  "decode: u+07ff")
_assert(ycUtf8::decode(strcat(intToChar(224) intToChar(160) intToChar(128))) == list(2048)  "decode: u+0800")
_assert(ycUtf8::decode(strcat(intToChar(239) intToChar(191) intToChar(191))) == list(65535)  "decode: u+ffff")
_assert(ycUtf8::decode(strcat(intToChar(240) intToChar(144) intToChar(128) intToChar(128))) == list(65536)  "decode: u+10000")
_assert(ycUtf8::decode(strcat(intToChar(244) intToChar(143) intToChar(191) intToChar(191))) == list(1114111)  "decode: u+10ffff")

_assertError(lambda(() ycUtf8::decode(strcat(intToChar(128))))  "decode: stray continuation")
_assertErrorMsg(lambda(() ycUtf8::decode(strcat("a" intToChar(128)))) "invalid UTF-8 at byte 2"  "decode: error position")
_assertError(lambda(() ycUtf8::decode(strcat(intToChar(228) intToChar(184))))  "decode: truncated")
_assertError(lambda(() ycUtf8::decode(strcat(intToChar(192) intToChar(128))))  "decode: overlong")
_assertError(lambda(() ycUtf8::decode(strcat(intToChar(237) intToChar(160) intToChar(128))))  "decode: surrogate")
_assertError(lambda(() ycUtf8::decode(strcat(intToChar(244) intToChar(144) intToChar(128) intToChar(128))))  "decode: above max")
_assertError(lambda(() ycUtf8::decode(strcat(intToChar(248) intToChar(136) intToChar(128) intToChar(128) intToChar(128))))  "decode: 5-byte")

_assert(ycUtf8::decode(strcat(intToChar(128)) ?strict nil) == list(65533)  "decode: lenient stray")
_assert(
    ycUtf8::decode(strcat(intToChar(192) intToChar(128)) ?strict nil) == list(65533 65533)
    "decode: lenient overlong bytes"
)
_assert(
    ycUtf8::decode(strcat(intToChar(228) intToChar(184)) ?strict nil) == list(65533 65533)
    "decode: lenient truncated bytes"
)
_assert(
    ycUtf8::decode(strcat(intToChar(237) intToChar(160) intToChar(128)) ?strict nil)
        == list(65533 65533 65533)
    "decode: lenient surrogate bytes"
)

_assert(ycUtf8::charCount("") == 0  "charCount: empty")
_assert(ycUtf8::charCount("abc") == 3  "charCount: ascii")
_assert(ycUtf8::charCount("中") == 1  "charCount: cjk")
_assert(ycUtf8::charCount("a中b") == 3  "charCount: mixed")
_assert(ycUtf8::charCount(strcat("a" intToChar(128)) ?strict nil) == 2  "charCount: lenient")
_assertError(lambda(() ycUtf8::charCount(strcat(intToChar(128))))  "charCount: strict invalid")

_assert(ycUtf8::slice("a中b" 2 1) == "中"  "slice: middle")
_assert(ycUtf8::slice("a中b" 3 9) == "b"  "slice: clips length")
_assert(ycUtf8::slice("a中b" 1 0) == ""  "slice: zero length")
_assert(ycUtf8::slice("a中b" 4 1) == nil  "slice: start beyond")
_assert(ycUtf8::slice("" 1 0) == nil  "slice: empty string")
_assertError(lambda(() ycUtf8::slice("a" 0 1))  "slice: start zero errors")
_assertError(lambda(() ycUtf8::slice("a" 1 -1))  "slice: negative length errors")
_assert(
    ycUtf8::slice(strcat("a" intToChar(128) "b") 2 1 ?strict nil)
        == strcat(intToChar(239) intToChar(191) intToChar(189))
    "slice: lenient replacement"
)

_assert(ycUtf8::isValid("")  "isValid: empty")
_assert(ycUtf8::isValid("abc")  "isValid: ascii")
_assert(ycUtf8::isValid("中")  "isValid: cjk")
_assert(!ycUtf8::isValid(strcat(intToChar(128)))  "isValid: stray continuation")
_assert(!ycUtf8::isValid(strcat(intToChar(228) intToChar(184)))  "isValid: truncated")
_assert(!ycUtf8::isValid(strcat(intToChar(192) intToChar(128)))  "isValid: overlong")
_assert(!ycUtf8::isValid(strcat(intToChar(237) intToChar(160) intToChar(128)))  "isValid: surrogate")

_TestDecodeDone = t

; END
