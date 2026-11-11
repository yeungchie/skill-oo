; ---------- 1. 构造与默认 ----------

let((q)
    q = ycQueue::FIFO()
    _Assert(q->size() == 0  "fifo: new queue size is 0")
    _Assert(q->isEmpty() == t  "fifo: new queue is empty")
    _Assert(q->toList() == nil  "fifo: new queue toList is nil")
    _Assert(q->isFull() == nil  "fifo: unlimited queue is never full")
    _Assert(q->maxLimit() == nil  "fifo: default maxLimit is nil")
    _Assert(printself(q) == "<ycQueue::FIFO size=0>"  "fifo: printself format")
)

; ---------- 2. 直接 makeInstance ----------

let((q)
    q = makeInstance('ycQueue::FIFO)
    _Assert(q->size() == 0  "fifo: makeInstance size is 0")
    _Assert(q->maxLimit() == nil  "fifo: makeInstance maxLimit is nil")
    _Assert(q->isFull() == nil  "fifo: makeInstance is never full")
    q->put("x")
    _Assert(q->get() == "x"  "fifo: makeInstance put/get works")
    _AssertErrorMsg(lambda(() makeInstance('ycQueue::FIFO ?maxLimit 0)) "?maxLimit must be nil or a positive integer"
        "fifo: makeInstance validates maxLimit")
)

; ---------- 3. 顺序与成员类型 ----------

let((q a b c)
    q = ycQueue::FIFO()
    q->put("a")->put("b")->put("c")
    _Assert(printself(q) == "<ycQueue::FIFO size=3>"  "fifo: printself shows size 3")
    a = q->get()
    b = q->get()
    c = q->get()
    _Assert(list(a b c) == list("a" "b" "c")  "fifo: get order is oldest first")
    _Assert(q->isEmpty()  "fifo: drained queue is empty")
)

let((q)
    q = ycQueue::FIFO()
    q->put(1)->put("two")->put('three)
    _Assert(q->toList() == list(1 "two" 'three)  "fifo: mixed member types keep order")
)

let((q)
    q = ycQueue::FIFO()
    q->put(nil)
    _Assert(q->size() == 1  "fifo: nil member counts as one element")
    _Assert(q->get() == nil  "fifo: nil member is returned as nil")
    _Assert(q->isEmpty()  "fifo: nil member was removed by get")
)

let((q)
    q = ycQueue::FIFO()
    q->put('sym)
    _Assert(q->get() == 'sym  "fifo: symbol member")
)

let((q inner got)
    q = ycQueue::FIFO()
    inner = list(1 2)
    q->put(inner)
    got = q->get()
    _Assert(eq(got inner)  "fifo: list member keeps identity")
)

let((q obj got)
    q = ycQueue::FIFO()
    obj = ycQueue::FIFO()
    q->put(obj)
    got = q->get()
    _Assert(eq(got obj)  "fifo: object member keeps identity")
)

; ---------- 4. 链式返回 ----------

let((q)
    q = ycQueue::FIFO()
    _Assert(eq(q->put(1) q)  "fifo: put returns self")
    _Assert(q->clear()->put(1)->put(2)->put(3)->size() == 3  "fifo: put supports chaining")
    _Assert(eq(q->clear() q)  "fifo: clear returns self")
    _Assert(q->clear()->put(9)->size() == 1  "fifo: clear then put")
)

; ---------- 5. peek 索引 ----------

let((q)
    q = ycQueue::FIFO()
    q->put("a")->put("b")->put("c")
    _Assert(q->peek() == q->peek(?index 0)  "fifo: peek defaults to index 0")
    _Assert(q->peek() == "a"  "fifo: peek 0 is oldest")
    _Assert(q->peek(?index 1) == "b"  "fifo: peek index 1")
    _Assert(q->peek(?index 2) == "c"  "fifo: peek index size-1")
    _Assert(q->peek(?index (3 - 1)) == "c"  "fifo: peek index size-1 expression")
    _Assert(q->peek(?index -1) == "c"  "fifo: peek index -1 is newest")
    _Assert(q->peek(?index -2) == "b"  "fifo: peek index -2")
    _Assert(q->peek(?index -3) == "a"  "fifo: peek index -size")
    _AssertErrorMsg(lambda(() q->peek(?index 3)) "index 3 out of range (size 3)"
        "fifo: peek index size errors")
    _AssertErrorMsg(lambda(() q->peek(?index -4)) "index -4 out of range (size 3)"
        "fifo: peek index below -size errors")
    _AssertErrorMsg(lambda(() q->peek(?index 1.5)) "argument for keyword ?index should be an integer"
        "fifo: peek float index rejected")
    _AssertErrorMsg(lambda(() q->peek(?index "1")) "argument for keyword ?index should be an integer"
        "fifo: peek string index rejected")
    _AssertErrorMsg(lambda(() q->peek(?index list(1 2))) "argument for keyword ?index should be an integer"
        "fifo: peek list index rejected")
    _Assert(q->peek() == "a" && q->peek() == "a"  "fifo: repeated peek returns same value")
    _Assert(q->size() == 3  "fifo: peek does not change size")
)

let((q)
    q = ycQueue::FIFO()
    _Assert(q->peek(?index 5 ?onEmpty 'none) == 'none  "fifo: empty peek ignores index range")
    _AssertErrorMsg(lambda(() q->peek()) "ycQueue::FIFO->peek: queue is empty"
        "fifo: empty peek without onEmpty errors")
)

let((q)
    q = ycQueue::FIFO()
    q->put("x")
    _Assert(q->peek(?onEmpty 'none) == "x"  "fifo: non-empty peek ignores onEmpty")
)

; ---------- 6. 空读契约 ----------

let((q obj res)
    q = ycQueue::FIFO()
    _AssertErrorMsg(lambda(() q->get()) "ycQueue::FIFO->get: queue is empty"
        "fifo: empty get without onEmpty errors")
    _Assert(q->get(?onEmpty nil) == nil  "fifo: empty get onEmpty nil")
    _Assert(q->get(?onEmpty 0) == 0  "fifo: empty get onEmpty 0")
    _Assert(q->get(?onEmpty "") == ""  "fifo: empty get onEmpty empty string")
    _Assert(q->get(?onEmpty list(1 2)) == list(1 2)  "fifo: empty get onEmpty list")
    _Assert(q->get(?onEmpty 'error) == 'error  "fifo: empty get onEmpty symbol")
    obj = ycQueue::FIFO()
    _Assert(eq(q->get(?onEmpty obj) obj)  "fifo: empty get onEmpty object")
    _Assert(q->size() == 0  "fifo: empty get leaves size 0")
    _Assert(q->peek(?onEmpty nil) == nil  "fifo: empty peek onEmpty nil")
    q->put("x")
    _Assert(q->get(?onEmpty 'none) == "x"  "fifo: non-empty get ignores onEmpty")
)

; ---------- 7. 容量上限 ----------

let((q)
    q = ycQueue::FIFO(?maxLimit 2)
    _Assert(q->maxLimit() == 2  "fifo: maxLimit returns constructor value")
    _Assert(q->isFull() == nil  "fifo: bounded queue is not full initially")
    q->put("a")->put("b")
    _Assert(q->isFull() == t  "fifo: bounded queue reports full")
    _AssertErrorMsg(lambda(() q->put("c")) "queue is full (maxLimit 2)"
        "fifo: full queue rejects put")
    _Assert(q->size() == 2  "fifo: rejected put did not enqueue")
    _Assert(q->toList() == list("a" "b")  "fifo: rejected put kept order")
    q->get()
    _Assert(q->isFull() == nil  "fifo: get clears full state")
    _Assert(q->maxLimit() == 2  "fifo: maxLimit unchanged after get")
    _Assert(q->put("c")->size() == 2  "fifo: put works after get")
)

let((q)
    q = ycQueue::FIFO()
    _Assert(q->isFull() == nil  "fifo: unlimited queue isFull stays nil")
)

_AssertErrorMsg(lambda(() ycQueue::FIFO(?maxLimit 0)) "?maxLimit must be nil or a positive integer"
    "fifo: maxLimit 0 rejected")
_AssertErrorMsg(lambda(() ycQueue::FIFO(?maxLimit -1)) "?maxLimit must be nil or a positive integer"
    "fifo: negative maxLimit rejected")
_AssertErrorMsg(lambda(() ycQueue::FIFO(?maxLimit 1.5)) "?maxLimit must be nil or a positive integer"
    "fifo: float maxLimit rejected")
_AssertErrorMsg(lambda(() ycQueue::FIFO(?maxLimit "3")) "?maxLimit must be nil or a positive integer"
    "fifo: string maxLimit rejected")
_AssertErrorMsg(lambda(() ycQueue::FIFO(?maxLimit list(2))) "?maxLimit must be nil or a positive integer"
    "fifo: list maxLimit rejected")
_AssertErrorMsg(lambda(() ycQueue::FIFO(?maxLimit t)) "?maxLimit must be nil or a positive integer"
    "fifo: t maxLimit rejected")

; ---------- 8. clear 与 toList ----------

let((q)
    q = ycQueue::FIFO(?maxLimit 3)
    q->put(1)->put(2)->put(3)
    _Assert(q->isFull() == t  "fifo: bounded queue reaches full")
    q->clear()
    _Assert(q->size() == 0  "fifo: clear empties the queue")
    _Assert(q->maxLimit() == 3  "fifo: clear keeps maxLimit")
    _Assert(q->isFull() == nil  "fifo: clear resets full state")
    _Assert(q->put(4)->size() == 1  "fifo: clear allows put")
    _Assert(q->put(5)->put(6)->isFull() == t  "fifo: can refill to maxLimit after clear")
)

let((q l)
    q = ycQueue::FIFO()
    q->put("a")->put("b")
    l = q->toList()
    _Assert(l == list("a" "b")  "fifo: toList order")
    q->clear()
    q->put("a")->put("b")
    _Assert(q->get() == "a" && q->get() == "b"  "fifo: toList order matches get order")
)

let((q l)
    q = ycQueue::FIFO()
    q->put("a")->put("b")
    l = q->toList()
    _Assert(!eq(l q->toList())  "fifo: toList returns a fresh copy")
    car(l) := "z"
    _Assert(q->peek() == "a"  "fifo: changing the copy does not affect the queue")
    _Assert(q->size() == 2  "fifo: toList copy does not change size")
)

let((q)
    q = ycQueue::FIFO()
    q->put(nil)->put(1)->put(nil)
    _Assert(q->toList() == list(nil 1 nil)  "fifo: toList keeps nil members")
)

let((q l)
    q = ycQueue::FIFO()
    q->put(1)->put(2)
    l = q->toList(?clear t)
    _Assert(l == list(1 2)  "fifo: toList with clear returns the list")
    _Assert(q->size() == 0  "fifo: toList with clear empties the queue")
    q->put(3)
    _Assert(length(l) == 2 && car(l) == 1  "fifo: handed-over list is not changed by later put")
)

let((q)
    q = ycQueue::FIFO()
    _Assert(q->toList() == nil  "fifo: empty toList is nil")
    _Assert(q->toList(?clear t) == nil  "fifo: empty toList with clear is nil")
)

; ---------- 9. 边界 ----------

let((q)
    q = ycQueue::FIFO()
    q->put(1)
    q->get()
    q->put(nil)
    _Assert(q->size() == 1  "fifo: refill after drain counts the nil member")
    _Assert(q->get() == nil  "fifo: refilled nil member reads back")
    _AssertErrorMsg(lambda(() q->get()) "queue is empty"  "fifo: drained refill queue errors")
)

let((q)
    q = ycQueue::FIFO()
    for(i 1 100 q->put(i))
    _Assert(q->size() == 100  "fifo: 100 puts keep size")
    for(i 1 100
        q->get()
    )
    _Assert(q->size() == 0 && q->isEmpty()  "fifo: 100 gets drain the queue")
)

let((q)
    q = ycQueue::FIFO()
    q->put(1)->put(2)
    q->get()
    _Assert(q->peek(?index -1) == 2  "fifo: index -1 after partial drain")
    q->get()
    q->put(3)
    _Assert(q->toList() == list(3) && q->peek(?index -1) == 3  "fifo: refill rebuilds tail")
)

let((q s)
    q = ycQueue::FIFO()
    s = ycQueue::LIFO()
    q->put(1)->put(2)
    s->put("a")->put("b")
    _Assert(q->get() == 1 && s->get() == "b" && q->get() == 2 && s->get() == "a"
        "fifo: interleaved fifo and lifo are independent")
)

let((q1 q2)
    q1 = ycQueue::FIFO()
    q2 = ycQueue::FIFO()
    q1->put(1)
    q2->put(2)
    _Assert(q1->get() == 1 && q2->get() == 2  "fifo: two instances are independent")
)

let((q res)
    q = ycQueue::FIFO()
    res = errset(progn(
        q->put('sym)
        q->put(ycQueue::FIFO())
        q->put(list(1 2))
        t
    ) nil)
    _Assert(res != nil && q->size() == 3  "fifo: put accepts any member type")
)

let((q)
    q = ycQueue::FIFO()
    _AssertErrorMsg(lambda(() q->size(1)) "too many arguments (0 expected, 1 given)"
        "fifo: size rejects extra arguments")
    _AssertErrorMsg(lambda(() q->isEmpty(1)) "too many arguments (0 expected, 1 given)"
        "fifo: isEmpty rejects extra arguments")
    _AssertErrorMsg(lambda(() q->isFull(1)) "too many arguments (0 expected, 1 given)"
        "fifo: isFull rejects extra arguments")
    _AssertErrorMsg(lambda(() q->maxLimit(1)) "too many arguments (0 expected, 1 given)"
        "fifo: maxLimit rejects extra arguments")
    _AssertErrorMsg(lambda(() q->clear(1)) "too many arguments (0 expected, 1 given)"
        "fifo: clear rejects extra arguments")
)

_TestChildDone = t

; END
