ycNamespace:::Require("ycLang")

useNamespace("ycQueue")

; ---------- LIFO 数据桶 ----------

defclass(_LIFOData () (
    ; _LIFOData 数据桶：收纳元素表头、元素计数与容量上限，构造后禁写。
    items(
        \@initarg items
        \@initform cons(nil nil)
    )
    count(
        \@initarg count
        \@initform 0
    )
    maxLimit(
        \@initarg maxLimit
        \@initform nil
    )
))

; ---------- LIFO 类型 ----------

defclass(LIFO () (
    ; LIFO 实例：后进先出队列，任意值为成员，可选容量上限。
    ; 状态放在 initializeInstance 的闭包里（_LIFOData），不作为实例槽暴露。
    put()
    get()
    peek()
    size()
    isEmpty()
    isFull()
    maxLimit()
    clear()
    toList()
))

defmethod(printself (self(LIFO))  ; -> str
    ; 返回 LIFO 的打印描述串，形如 <ycQueue::LIFO size=3>。
    ;
    ; **返回**
    ;   (str) - lsprintf 按 <类名 size=N> 模板生成
    lsprintf("<%A size=%d>" className(self) self->size())
)


inScheme(
defmethod(initializeInstance (self(LIFO) \@key (maxLimit nil))
    ; 构造 LIFO 实例时校验容量上限，在闭包里建状态桶并安装方法集：
    ; put/get/peek/size/isEmpty/isFull/maxLimit/clear/toList。
    ;
    ; **参数**
    ;   ?maxLimit  (int|nil) - 容量上限；默认 nil
    ;
    ; **返回**
    ;   (t) - 安装完成后返回 t
    when(maxLimit && !(fixp(maxLimit) && maxLimit > 0)
        error("%A: ?maxLimit must be nil or a positive integer, got %A" className(self) maxLimit)
    )
    let((data)
        data = makeInstance('_LIFOData ?maxLimit maxLimit)

        self->put = lambda((g_value "g")  ; -> self
            ; 把 g_value 压到队首；满队列时以 error() 中断且不入队。
            ;
            ; **参数**
            ;   g_value  (any) - 任意 SKILL 值
            ;
            ; **返回**
            ;   (LIFO) - self，支持链式
            when(data->maxLimit && data->count >= data->maxLimit
                error("%A->put: queue is full (maxLimit %d)" className(self) data->maxLimit)
            )
            if(car(data->items)
            then
                car(data->items) := cons(g_value car(data->items))
            else
                ; 表空时末格指针悬空，必须指向新的唯一元素。
                car(data->items) := cons(g_value nil)
                cdr(data->items) := car(data->items)
            )
            data->count = data->count + 1
            self
        )

        self->get = lambda((\@key (onEmpty 'ycLang:::NoneArg) "g")  ; -> any
            ; 取出并移除最新元素；空队列按 ?onEmpty 契约处理。
            ;
            ; **参数**
            ;   ?onEmpty  (any) - 空读时返回的值；默认未指定（空读报错）
            ;
            ; **返回**
            ;   (any) - 被取出的成员；空队列时为 ?onEmpty 的给定值
            let((value)
                if(data->count == 0
                then
                    _EmptyResult(self "get" onEmpty)
                else
                    value = caar(data->items)
                    car(data->items) := cdar(data->items)
                    data->count = data->count - 1
                    when(data->count == 0
                        ; 排空后换新容器，避免尾指针悬空
                        data->items = cons(nil nil)
                    )
                    value
                )
            )
        )

        self->peek = lambda((\@key (index 0) (onEmpty 'ycLang:::NoneArg) "xg")  ; -> any
            ; 返回指定位置的元素而不移除；空队列按 ?onEmpty 契约处理。
            ;
            ; **参数**
            ;   ?index    (int) - 0-based 位置，负值从另一端数；默认 0
            ;   ?onEmpty  (any) - 空读时返回的值；默认未指定（空读报错）
            ;
            ; **返回**
            ;   (any) - 该位置的成员；空队列时为 ?onEmpty 的给定值
            let((pos)
                if(data->count == 0
                then
                    _EmptyResult(self "peek" onEmpty)
                else
                    cond(
                        (index == 0
                            caar(data->items)
                        )
                        (index == -1
                            car(cdr(data->items))
                        )
                        (t
                            pos = _Position(self "peek" index data->count)
                            nth(pos car(data->items))
                        )
                    )
                )
            )
        )

        self->size = lambda(()  ; -> int
            ; 返回当前元素个数。
            ;
            ; **返回**
            ;   (int) - 元素个数，≥ 0
            data->count
        )

        self->isEmpty = lambda(()  ; -> t | nil
            ; 判断队列是否为空。
            ;
            ; **返回**
            ;   (t|nil) - 空队列为 t，否则为 nil
            data->count == 0
        )

        self->isFull = lambda(()  ; -> t | nil
            ; 判断队列是否已达到容量上限。
            ;
            ; **返回**
            ;   (t|nil) - 达到上限为 t；不限容量或未满为 nil
            data->maxLimit && data->count >= data->maxLimit
        )

        self->maxLimit = lambda(()  ; -> int | nil
            ; 返回构造时给定的容量上限。
            ;
            ; **返回**
            ;   (int|nil) - 容量上限；不限容量为 nil
            data->maxLimit
        )

        self->clear = lambda(()  ; -> self
            ; 移除全部元素，回到初始状态（容量上限保留）。
            ;
            ; **返回**
            ;   (LIFO) - self，支持链式
            data->items = cons(nil nil)
            data->count = 0
            self
        )

        self->toList = lambda((\@key (clear nil) "g")  ; -> list
            ; 按出队顺序返回元素表；默认返回拷贝，?clear 非 nil 时移交并清空。
            ;
            ; **参数**
            ;   ?clear  (t|nil) - 非 nil 时移交内部表并清空队列；默认 nil
            ;
            ; **返回**
            ;   (list) - 最新 → 最早的元素表；空队列为 nil
            let((result)
                if(clear
                then
                    result = car(data->items)
                    data->items = cons(nil nil)
                    data->count = 0
                    result
                else
                    copy(car(data->items))
                )
            )
        )
        t
    )
)
)

; ---------- 构造器 ----------

procedure(LIFO(\@key (maxLimit nil) "g")  ; -> LIFO
    ; 构造一个后进先出队列。
    ;
    ; **参数**
    ;   ?maxLimit  (int|nil) - 容量上限，nil 表示不限制；默认 nil
    ;
    ; **返回**
    ;   (LIFO) - 新队列实例；?maxLimit 非法时以 error() 中断
    makeInstance('LIFO ?maxLimit maxLimit)
)

unuseNamespace("ycQueue")

; END
