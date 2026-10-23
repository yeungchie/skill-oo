_TestDecodeDone = nil

_Assert(ycUtf8::Decode("") == nil  "decode: empty")
_Assert(ycUtf8::Decode("abc") == list(97 98 99)  "decode: ascii")
_Assert(ycUtf8::Decode("中") == list(20013)  "decode: cjk")
_Assert(ycUtf8::Decode(strcat(intToChar(195) intToChar(169))) == list(233)  "decode: 2-byte")
_Assert(ycUtf8::Decode(strcat(intToChar(226) intToChar(130) intToChar(172))) == list(8364)  "decode: 3-byte")
_Assert(ycUtf8::Decode(strcat(intToChar(240) intToChar(159) intToChar(152) intToChar(128))) == list(128512)  "decode: 4-byte")
_Assert(ycUtf8::Decode(strcat(intToChar(127))) == list(127)  "decode: u+007f")
_Assert(ycUtf8::Decode(strcat(intToChar(194) intToChar(128))) == list(128)  "decode: u+0080")
_Assert(ycUtf8::Decode(strcat(intToChar(223) intToChar(191))) == list(2047)  "decode: u+07ff")
_Assert(ycUtf8::Decode(strcat(intToChar(224) intToChar(160) intToChar(128))) == list(2048)  "decode: u+0800")
_Assert(ycUtf8::Decode(strcat(intToChar(239) intToChar(191) intToChar(191))) == list(65535)  "decode: u+ffff")
_Assert(ycUtf8::Decode(strcat(intToChar(240) intToChar(144) intToChar(128) intToChar(128))) == list(65536)  "decode: u+10000")
_Assert(ycUtf8::Decode(strcat(intToChar(244) intToChar(143) intToChar(191) intToChar(191))) == list(1114111)  "decode: u+10ffff")
_Assert(ycUtf8::Decode(strcat(intToChar(239) intToChar(187) intToChar(191))) == list(65279)  "decode: bom kept")

_AssertError(lambda(() ycUtf8::Decode(strcat(intToChar(128))))  "decode: stray continuation")
_AssertErrorMsg(lambda(() ycUtf8::Decode(strcat("a" intToChar(128)))) "ycUtf8::Decode: invalid UTF-8 at byte 2"  "decode: error position")
_AssertError(lambda(() ycUtf8::Decode(strcat(intToChar(228) intToChar(184))))  "decode: truncated")
_AssertError(lambda(() ycUtf8::Decode(strcat(intToChar(192) intToChar(128))))  "decode: overlong")
_AssertError(lambda(() ycUtf8::Decode(strcat(intToChar(224) intToChar(128) intToChar(128))))  "decode: overlong 3-byte")
_AssertError(lambda(() ycUtf8::Decode(strcat(intToChar(240) intToChar(128) intToChar(128) intToChar(128))))  "decode: overlong 4-byte")
_AssertError(lambda(() ycUtf8::Decode(strcat(intToChar(237) intToChar(160) intToChar(128))))  "decode: surrogate")
_AssertError(lambda(() ycUtf8::Decode(strcat(intToChar(244) intToChar(144) intToChar(128) intToChar(128))))  "decode: above max")
_AssertError(lambda(() ycUtf8::Decode(strcat(intToChar(248) intToChar(136) intToChar(128) intToChar(128) intToChar(128))))  "decode: 5-byte")
_AssertErrorMsg(lambda(() ycUtf8::Decode(123)) "argument #1 should be a string"  "decode: non-string")

_Assert(ycUtf8::Decode(strcat(intToChar(128)) ?strict nil) == list(65533)  "decode: lenient stray")
_Assert(
    ycUtf8::Decode(strcat(intToChar(192) intToChar(128)) ?strict nil) == list(65533 65533)
    "decode: lenient overlong bytes"
)
_Assert(
    ycUtf8::Decode(strcat(intToChar(228) intToChar(184)) ?strict nil) == list(65533 65533)
    "decode: lenient truncated bytes"
)
_Assert(
    ycUtf8::Decode(strcat(intToChar(237) intToChar(160) intToChar(128)) ?strict nil)
        == list(65533 65533 65533)
    "decode: lenient surrogate bytes"
)

_Assert(ycUtf8::CharCount("") == 0  "CharCount: empty")
_Assert(ycUtf8::CharCount("abc") == 3  "CharCount: ascii")
_Assert(ycUtf8::CharCount("中") == 1  "CharCount: cjk")
_Assert(ycUtf8::CharCount("a中b") == 3  "CharCount: mixed")
_Assert(ycUtf8::CharCount(strcat("a" intToChar(128)) ?strict nil) == 2  "CharCount: lenient")
_AssertError(lambda(() ycUtf8::CharCount(strcat(intToChar(128))))  "CharCount: strict invalid")
_AssertErrorMsg(lambda(() ycUtf8::CharCount(123)) "argument #1 should be a string"  "CharCount: non-string")

_Assert(ycUtf8::Slice("a中b" 2 1) == "中"  "slice: middle")
_Assert(ycUtf8::Slice("a中b" 3 9) == "b"  "slice: clips length")
_Assert(ycUtf8::Slice("a中b" 1 0) == ""  "slice: zero length")
_Assert(ycUtf8::Slice("a中b" 4 1) == nil  "slice: start beyond")
_Assert(ycUtf8::Slice("" 1 0) == nil  "slice: empty string")
_AssertErrorMsg(lambda(() ycUtf8::Slice("a" 0 1)) "ycUtf8::Slice: start must be an integer >= 1"  "slice: start zero errors")
_AssertErrorMsg(lambda(() ycUtf8::Slice("a" 1 -1)) "ycUtf8::Slice: length must be an integer >= 0"  "slice: negative length errors")
_AssertErrorMsg(lambda(() ycUtf8::Slice(123 1 1)) "argument #1 should be a string"  "slice: non-string")
_Assert(
    ycUtf8::Slice(strcat("a" intToChar(128) "b") 2 1 ?strict nil)
        == strcat(intToChar(239) intToChar(191) intToChar(189))
    "slice: lenient replacement"
)
_Assert(ycUtf8::Slice(strcat("a" intToChar(128)) 1 1) == "a"  "slice: strict ignores bytes after window")
_AssertErrorMsg(lambda(() ycUtf8::Slice(strcat("a" intToChar(128)) 4 1)) "ycUtf8::Slice: invalid UTF-8 at byte 2"  "slice: strict scans prefix")
_Assert(ycUtf8::Slice(strcat("a" intToChar(128)) 4 1 ?strict nil) == nil  "slice: lenient start beyond")

_Assert(ycUtf8::IsValid("")  "isValid: empty")
_Assert(ycUtf8::IsValid("abc")  "isValid: ascii")
_Assert(ycUtf8::IsValid("中")  "isValid: cjk")
_Assert(!ycUtf8::IsValid(strcat(intToChar(128)))  "isValid: stray continuation")
_Assert(!ycUtf8::IsValid(strcat(intToChar(228) intToChar(184)))  "isValid: truncated")
_Assert(!ycUtf8::IsValid(strcat(intToChar(192) intToChar(128)))  "isValid: overlong")
_Assert(!ycUtf8::IsValid(strcat(intToChar(237) intToChar(160) intToChar(128)))  "isValid: surrogate")
_AssertErrorMsg(lambda(() ycUtf8::IsValid(123)) "argument #1 should be a string"  "isValid: non-string")

_TestDecodeDone = t

; END
