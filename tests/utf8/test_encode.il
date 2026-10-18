_TestEncodeDone = nil

_assert(ycUtf8::encode(nil) == ""  "encode: nil")
_assert(ycUtf8::encode(list(97 98 99)) == "abc"  "encode: ascii")
_assert(ycUtf8::encode(list(20013)) == "中"  "encode: cjk")
_assert(
    ycUtf8::encode(list(128512))
        == strcat(intToChar(240) intToChar(159) intToChar(152) intToChar(128))
    "encode: emoji"
)
_assert(ycUtf8::encode(list(127)) == strcat(intToChar(127))  "encode: u+007f")
_assert(ycUtf8::encode(list(128)) == strcat(intToChar(194) intToChar(128))  "encode: u+0080")
_assert(ycUtf8::encode(list(2047)) == strcat(intToChar(223) intToChar(191))  "encode: u+07ff")
_assert(
    ycUtf8::encode(list(2048)) == strcat(intToChar(224) intToChar(160) intToChar(128))
    "encode: u+0800"
)
_assert(
    ycUtf8::encode(list(65535))
        == strcat(intToChar(239) intToChar(191) intToChar(191))
    "encode: u+ffff"
)
_assert(
    ycUtf8::encode(list(65536))
        == strcat(intToChar(240) intToChar(144) intToChar(128) intToChar(128))
    "encode: u+10000"
)
_assert(
    ycUtf8::encode(list(1114111))
        == strcat(intToChar(244) intToChar(143) intToChar(191) intToChar(191))
    "encode: u+10ffff"
)
_assertErrorMsg(lambda(() ycUtf8::encode(list(0))) "cannot be represented"  "encode: nul rejected")
_assertError(lambda(() ycUtf8::encode(list(-1)))  "encode: negative")
_assertError(lambda(() ycUtf8::encode(list(55296)))  "encode: surrogate")
_assertError(lambda(() ycUtf8::encode(list(1114112)))  "encode: above max")
_assertError(lambda(() ycUtf8::encode(list(97.5)))  "encode: float")
_assertErrorMsg(lambda(() ycUtf8::encode(list(97 "x"))) "at index 2"  "encode: element index")
_assertError(lambda(() ycUtf8::encode("abc"))  "encode: non-list")
_assert(
    ycUtf8::decode(ycUtf8::encode(list(127 128 2047 2048 65535 65536 1114111 128512)))
        == list(127 128 2047 2048 65535 65536 1114111 128512)
    "encode: roundtrip"
)

_TestEncodeDone = t

; END
