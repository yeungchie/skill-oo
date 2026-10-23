_TestEncodeDone = nil

_Assert(ycUtf8::Encode(nil) == ""  "encode: nil")
_Assert(ycUtf8::Encode(list(97 98 99)) == "abc"  "encode: ascii")
_Assert(ycUtf8::Encode(list(20013)) == "中"  "encode: cjk")
_Assert(
    ycUtf8::Encode(list(128512))
        == strcat(intToChar(240) intToChar(159) intToChar(152) intToChar(128))
    "encode: emoji"
)
_Assert(ycUtf8::Encode(list(127)) == strcat(intToChar(127))  "encode: u+007f")
_Assert(ycUtf8::Encode(list(128)) == strcat(intToChar(194) intToChar(128))  "encode: u+0080")
_Assert(ycUtf8::Encode(list(2047)) == strcat(intToChar(223) intToChar(191))  "encode: u+07ff")
_Assert(
    ycUtf8::Encode(list(2048)) == strcat(intToChar(224) intToChar(160) intToChar(128))
    "encode: u+0800"
)
_Assert(
    ycUtf8::Encode(list(65535))
        == strcat(intToChar(239) intToChar(191) intToChar(191))
    "encode: u+ffff"
)
_Assert(
    ycUtf8::Encode(list(65536))
        == strcat(intToChar(240) intToChar(144) intToChar(128) intToChar(128))
    "encode: u+10000"
)
_Assert(
    ycUtf8::Encode(list(1114111))
        == strcat(intToChar(244) intToChar(143) intToChar(191) intToChar(191))
    "encode: u+10ffff"
)
_AssertErrorMsg(lambda(() ycUtf8::Encode(list(0))) "ycUtf8::Encode: codepoint at index 1"  "encode: nul rejected")
_AssertError(lambda(() ycUtf8::Encode(list(-1)))  "encode: negative")
_AssertError(lambda(() ycUtf8::Encode(list(55296)))  "encode: surrogate")
_AssertError(lambda(() ycUtf8::Encode(list(1114112)))  "encode: above max")
_AssertError(lambda(() ycUtf8::Encode(list(97.5)))  "encode: float")
_AssertErrorMsg(lambda(() ycUtf8::Encode(list(97 "x"))) "ycUtf8::Encode: invalid codepoint at index 2"  "encode: element index")
_AssertError(lambda(() ycUtf8::Encode("abc"))  "encode: non-list")
_Assert(
    ycUtf8::Decode(ycUtf8::Encode(list(127 128 2047 2048 65535 65536 1114111 128512)))
        == list(127 128 2047 2048 65535 65536 1114111 128512)
    "encode: roundtrip"
)

_TestEncodeDone = t

; END
