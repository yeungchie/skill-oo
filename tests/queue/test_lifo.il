; ---------- 1. 构造与默认 ----------

let((q)
    q = ycQueue::LIFO()
    _Assert(q->size() == 0  "lifo: new queue size is 0")
    _Assert(q->isEmpty() == t  "lifo: new queue is empty")
    _Assert(q->toList() == nil  "lifo: new queue toList is nil")
    _Assert(q->isFull() == nil  "lifo: unlimited queue is never full")
    _Assert(q->maxLimit() == nil  "lifo: default maxLimit is nil")
    _Assert(printself(q) == "<ycQueue::LIFO size=0>"  "lifo: printself format")
)

; ---------- 2. 直接 makeInstance ----------

let((q)
    q = makeInstance('ycQueue::LIFO)
    _Assert(q->size() == 0  "lifo: makeInstance size is 0")
    _Assert(q->maxLimit() == nil  "lifo: makeInstance maxLimit is nil")
    _Assert(q->isFull() == nil  "lifo: makeInstance is never full")
    q->put("x")
    _Assert(q->get() == "x"  "lifo: makeInstance put/get works")
)

; ---------- 3. 顺序与成员类型 ----------

let((q a b c)
    q = ycQueue::LIFO()
    q->put("a")->put("b")->put("c")
    a = q->get()
    b = q->get()
    c = q->get()
    _Assert(list(a b c) == list("c" "b" "a")  "lifo: get order is newest first")
    _Assert(q->isEmpty()  "lifo: drained queue is empty")
)

let((q)
    q = ycQueue::LIFO()
    q->put(1)->put("two")->put('three)
    _Assert(q->toList() == list('three "two" 1)  "lifo: mixed member types in reverse order")
)

let((q)
    q = ycQueue::LIFO()
    q->put(nil)
    _Assert(q->size() == 1  "lifo: nil member counts as one element")
    _Assert(q->get() == nil  "lifo: nil member is returned as nil")
    _Assert(q->isEmpty()  "lifo: nil member was removed by get")
)

let((q)
    q = ycQueue::LIFO()
    q->put('sym)
    _Assert(q->get() == 'sym  "lifo: symbol member")
)

let((q inner got)
    q = ycQueue::LIFO()
    inner = list(1 2)
    q->put(inner)
    got = q->get()
    _Assert(eq(got inner)  "lifo: list member keeps identity")
)

let((q obj got)
    q = ycQueue::LIFO()
    obj = ycQueue::LIFO()
    q->put(obj)
    got = q->get()
    _Assert(eq(got obj)  "lifo: object member keeps identity")
)

; ---------- 4. 链式返回 ----------

let((q)
    q = ycQueue::LIFO()
    _Assert(eq(q->put(1) q)  "lifo: put returns self")
    _Assert(q->clear()->put(1)->put(2)->put(3)->size() == 3  "lifo: put supports chaining")
    _Assert(eq(q->clear() q)  "lifo: clear returns self")
    _Assert(q->clear()->put(9)->size() == 1  "lifo: clear then put")
)

; ---------- 5. peek 索引 ----------

let((q)
    q = ycQueue::LIFO()
    q->put("a")->put("b")->put("c")
    _Assert(q->peek() == q->peek(?index 0)  "lifo: peek defaults to index 0")
    _Assert(q->peek() == "c"  "lifo: peek 0 is newest")
    _Assert(q->peek(?index 1) == "b"  "lifo: peek index 1")
    _Assert(q->peek(?index 2) == "a"  "lifo: peek index size-1")
    _Assert(q->peek(?index (3 - 1)) == "a"  "lifo: peek index size-1 expression")
    _Assert(q->peek(?index -1) == "a"  "lifo: peek index -1 is oldest")
    _Assert(q->peek(?index -2) == "b"  "lifo: peek index -2")
    _Assert(q->peek(?index -3) == "c"  "lifo: peek index -size")
    _AssertErrorMsg(lambda(() q->peek(?index 3)) "index 3 out of range (size 3)"
        "lifo: peek index size errors")
    _AssertErrorMsg(lambda(() q->peek(?index -4)) "index -4 out of range (size 3)"
        "lifo: peek index below -size errors")
    _Assert(q->peek() == "c" && q->peek() == "c"  "lifo: repeated peek returns same value")
    _Assert(q->size() == 3  "lifo: peek does not change size")
)

let((q)
    q = ycQueue::LIFO()
    _Assert(q->peek(?index 5 ?onEmpty 'none) == 'none  "lifo: empty peek ignores index range")
    _AssertErrorMsg(lambda(() q->peek()) "ycQueue::LIFO->peek: queue is empty"
        "lifo: empty peek without onEmpty errors")
)

let((q)
    q = ycQueue::LIFO()
    q->put("x")
    _Assert(q->peek(?onEmpty 'none) == "x"  "lifo: non-empty peek ignores onEmpty")
)

; ---------- 6. 空读契约 ----------

let((q obj)
    q = ycQueue::LIFO()
    _AssertErrorMsg(lambda(() q->get()) "ycQueue::LIFO->get: queue is empty"
        "lifo: empty get without onEmpty errors")
    _Assert(q->get(?onEmpty nil) == nil  "lifo: empty get onEmpty nil")
    _Assert(q->get(?onEmpty 0) == 0  "lifo: empty get onEmpty 0")
    _Assert(q->get(?onEmpty "") == ""  "lifo: empty get onEmpty empty string")
    _Assert(q->get(?onEmpty list(1 2)) == list(1 2)  "lifo: empty get onEmpty list")
    _Assert(q->get(?onEmpty 'error) == 'error  "lifo: empty get onEmpty symbol")
    obj = ycQueue::LIFO()
    _Assert(eq(q->get(?onEmpty obj) obj)  "lifo: empty get onEmpty object")
    _Assert(q->size() == 0  "lifo: empty get leaves size 0")
    _Assert(q->peek(?onEmpty nil) == nil  "lifo: empty peek onEmpty nil")
    q->put("x")
    _Assert(q->get(?onEmpty 'none) == "x"  "lifo: non-empty get ignores onEmpty")
)

; ---------- 7. 容量上限 ----------

let((q)
    q = ycQueue::LIFO(?maxLimit 2)
    _Assert(q->maxLimit() == 2  "lifo: maxLimit returns constructor value")
    _Assert(q->isFull() == nil  "lifo: bounded queue is not full initially")
    q->put("a")->put("b")
    _Assert(q->isFull() == t  "lifo: bounded queue reports full")
    _AssertErrorMsg(lambda(() q->put("c")) "queue is full (maxLimit 2)"
        "lifo: full queue rejects put")
    _Assert(q->size() == 2  "lifo: rejected put did not enqueue")
    _Assert(q->toList() == list("b" "a")  "lifo: rejected put kept order")
    q->get()
    _Assert(q->isFull() == nil  "lifo: get clears full state")
    _Assert(q->put("c")->size() == 2  "lifo: put works after get")
)

let((q)
    q = ycQueue::LIFO()
    _Assert(q->isFull() == nil  "lifo: unlimited queue isFull stays nil")
)

_AssertErrorMsg(lambda(() ycQueue::LIFO(?maxLimit 0)) "?maxLimit must be nil or a positive integer"
    "lifo: maxLimit 0 rejected")
_AssertErrorMsg(lambda(() ycQueue::LIFO(?maxLimit -1)) "?maxLimit must be nil or a positive integer"
    "lifo: negative maxLimit rejected")
_AssertErrorMsg(lambda(() ycQueue::LIFO(?maxLimit 1.5)) "?maxLimit must be nil or a positive integer"
    "lifo: float maxLimit rejected")
_AssertErrorMsg(lambda(() ycQueue::LIFO(?maxLimit "3")) "?maxLimit must be nil or a positive integer"
    "lifo: string maxLimit rejected")
_AssertErrorMsg(lambda(() ycQueue::LIFO(?maxLimit list(2))) "?maxLimit must be nil or a positive integer"
    "lifo: list maxLimit rejected")
_AssertErrorMsg(lambda(() ycQueue::LIFO(?maxLimit t)) "?maxLimit must be nil or a positive integer"
    "lifo: t maxLimit rejected")

; ---------- 8. clear 与 toList ----------

let((q)
    q = ycQueue::LIFO(?maxLimit 3)
    q->put(1)->put(2)
    q->clear()
    _Assert(q->size() == 0  "lifo: clear empties the queue")
    _Assert(q->maxLimit() == 3  "lifo: clear keeps maxLimit")
    _Assert(q->put(4)->size() == 1  "lifo: clear allows put")
)

let((q)
    q = ycQueue::LIFO()
    q->put("a")->put("b")
    _Assert(q->toList() == list("b" "a")  "lifo: toList order")
    _Assert(q->get() == "b" && q->get() == "a"  "lifo: toList order matches get order")
)

let((q l)
    q = ycQueue::LIFO()
    q->put("a")->put("b")
    l = q->toList()
    _Assert(!eq(l q->toList())  "lifo: toList returns a fresh copy")
    car(l) := "z"
    _Assert(q->peek() == "b"  "lifo: changing the copy does not affect the queue")
    _Assert(q->size() == 2  "lifo: toList copy does not change size")
)

let((q)
    q = ycQueue::LIFO()
    q->put(nil)->put(1)->put(nil)
    _Assert(q->toList() == list(nil 1 nil)  "lifo: toList keeps nil members")
)

let((q l)
    q = ycQueue::LIFO()
    q->put(1)->put(2)
    l = q->toList(?clear t)
    _Assert(l == list(2 1)  "lifo: toList with clear returns the list")
    _Assert(q->size() == 0  "lifo: toList with clear empties the queue")
    q->put(3)
    _Assert(length(l) == 2 && car(l) == 2  "lifo: handed-over list is not changed by later put")
)

let((q)
    q = ycQueue::LIFO()
    _Assert(q->toList() == nil  "lifo: empty toList is nil")
    _Assert(q->toList(?clear t) == nil  "lifo: empty toList with clear is nil")
)

; ---------- 9. 边界 ----------

let((q)
    q = ycQueue::LIFO()
    q->put(1)
    q->get()
    q->put(nil)
    _Assert(q->size() == 1  "lifo: refill after drain counts the nil member")
    _Assert(q->get() == nil  "lifo: refilled nil member reads back")
    _AssertErrorMsg(lambda(() q->get()) "queue is empty"  "lifo: drained refill queue errors")
)

let((q i ok)
    q = ycQueue::LIFO()
    for(i 1 100 q->put(i))
    _Assert(q->size() == 100  "lifo: 100 puts keep size")
    ok = t
    for(i 1 100
        unless(q->get() == 101 - i
            ok = nil
        )
    )
    _Assert(ok && q->size() == 0  "lifo: 100 gets return last-in-first-out")
)

let((q1 q2)
    q1 = ycQueue::LIFO()
    q2 = ycQueue::LIFO()
    q1->put(1)
    q2->put(2)
    _Assert(q1->get() == 1 && q2->get() == 2  "lifo: two instances are independent")
)

let((q res)
    q = ycQueue::LIFO()
    res = errset(progn(
        q->put('sym)
        q->put(ycQueue::LIFO())
        q->put(list(1 2))
        t
    ) nil)
    _Assert(res != nil && q->size() == 3  "lifo: put accepts any member type")
)

let((q)
    q = ycQueue::LIFO()
    _AssertErrorMsg(lambda(() q->size(1)) "too many arguments (0 expected, 1 given)"
        "lifo: size rejects extra arguments")
)

; ---------- 10. LIFO 顺序专项 ----------

let((q)
    q = ycQueue::LIFO()
    q->put(1)->put(2)->put(3)
    _Assert(q->toList() == list(3 2 1)  "lifo: toList is newest to oldest")
    _Assert(q->peek() == 3  "lifo: peek is the newest element")
    let((a b c)
        a = q->get()
        b = q->get()
        c = q->get()
        _Assert(list(a b c) == list(3 2 1)  "lifo: get is newest to oldest")
    )
    q->put(1)->put(2)->put(3)
    _Assert(q->peek(?index -1) == 1  "lifo: index -1 is the oldest element")
)

_TestChildDone = t

; END
