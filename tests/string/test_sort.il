_TestSortDone = nil

; 数字段按数值比较
_Assert(ycString::NaturalLess("VDD1" "VDD2")  "natural: vdd1 before vdd2")
_Assert(ycString::NaturalLess("VDD2" "VDD10")  "natural: vdd2 before vdd10")
_Assert(!ycString::NaturalLess("VDD10" "VDD2")  "natural: vdd10 not before vdd2")
_Assert(!ycString::NaturalLess("file10" "file2")  "natural: file10 not before file2")

; 相等与前缀
_Assert(!ycString::NaturalLess("abc" "abc")  "natural: equal strings")
_Assert(ycString::NaturalLess("abc" "abcd")  "natural: shorter prefix first")
_Assert(!ycString::NaturalLess("abcd" "abc")  "natural: longer prefix last")

; 大小写：不敏感比较，平局按原串
_Assert(ycString::NaturalLess("A" "a")  "natural: uppercase tiebreak first")
_Assert(!ycString::NaturalLess("a" "A")  "natural: lowercase tiebreak last")
_Assert(ycString::NaturalLess("abc" "ABD")  "natural: case insensitive order")

; 前导零：数值相等时零少者在前
_Assert(ycString::NaturalLess("a1" "a01")  "natural: fewer zeros first")
_Assert(!ycString::NaturalLess("a01" "a1")  "natural: more zeros last")

; 任意长度数字不丢精度
_Assert(ycString::NaturalLess("n123456789012345678901" "n123456789012345678902")
    "natural: long digits keep precision")
_Assert(!ycString::NaturalLess("n123456789012345678902" "n123456789012345678901")
    "natural: long digits reversed")

; 无数字串按字母序
_Assert(ycString::NaturalLess("abc" "abd")  "natural: plain alphabetical")

let((in out)
    in = list("VDD10" "VDD2" "VDD1")
    out = ycString::NaturalSort(in)
    _Assert(out == list("VDD1" "VDD2" "VDD10")  "nsort: ascending natural order")
    _Assert(in == list("VDD10" "VDD2" "VDD1")  "nsort: input list untouched")
    _Assert(ycString::NaturalSort(in ?reverse t) == list("VDD10" "VDD2" "VDD1")
        "nsort: reverse option")
    _Assert(ycString::NaturalSort(list("b" "a" "b")) == list("a" "b" "b")
        "nsort: duplicates kept")
    _Assert(ycString::NaturalSort(nil) == nil  "nsort: empty list")
)

_AssertError(lambda(() ycString::NaturalLess(1 "a"))
    "natural: rejects number left operand"
)
_AssertError(lambda(() ycString::NaturalLess("a" 'b))
    "natural: rejects symbol right operand"
)
_AssertError(lambda(() ycString::NaturalSort("abc"))
    "nsort: rejects a bare string"
)
_AssertErrorMsg(lambda(() ycString::NaturalSort(list("a" 1)))
    "must be a string" "nsort: reports non-string item"
)

_TestChildDone = t

; END
