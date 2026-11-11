ycNamespace:::Require("ycQueue")

useNamespace("ycSubProcess")


; ---------- 类定义 ----------

defclass(Stream () (
    ; Stream 流对象：FIFO 累积子进程输出数据，构造后经 push() 写入。
    push()
    last()
    shift()
    text()
    size()
    isEmpty()
))

defmethod(printself (self(Stream))  ; -> str
    ; 返回流对象的打印描述串，形如 <ycSubProcess::Stream size=3>。
    ;
    ; **返回**
    ;   (str) - lsprintf 生成；size 取当前条目数
    lsprintf("<%A size=%d>" className(self) self->size())
)


; ---------- 构造时安装全部方法 ----------

inScheme(
defmethod(initializeInstance (self(Stream))
    ; 安装 Stream 全部方法：push/last/shift/text/size/isEmpty。
    ; 内部状态是一个 ycQueue::FIFO 实例，只在闭包里出现。
    ;
    ; **返回**
    ;   (t) - 安装完成后返回 t
    let((queue)
        queue = ycQueue:::FIFO()
        self->push = lambda((t_text "t")  ; -> t
            ; 追加一条数据到流尾。
            ;
            ; **参数**
            ;   t_text  (str) - 待追加的数据
            ;
            ; **返回**
            ;   (t) - 追加成功
            queue->put(t_text)
            t
        )
        self->last = lambda(()  ; -> str | nil
            ; 返回最后一条数据；空流返回 nil。
            ;
            ; **返回**
            ;   (str|nil) - 末条目
            unless(queue->isEmpty()
                queue->peek(?index -1)
            )
        )
        self->shift = lambda(()  ; -> str | nil
            ; 取出并移除第一条数据；空流返回 nil。
            ;
            ; **返回**
            ;   (str|nil) - 首条目
            queue->get(?onEmpty nil)
        )
        self->text = lambda((\@key (clear nil) "g")  ; -> str
            ; 拼接全量数据为字符串；?clear 非 nil 时取完清空。
            ;
            ; **参数**
            ;   ?clear  (t|nil) - 取后是否清空；默认 nil
            ;
            ; **返回**
            ;   (str) - 全量拼接串，空流为 ""
            queue->isEmpty() && "" || buildString(queue->toList(?clear clear) "")
        )
        self->size = lambda(()  ; -> int
            ; 返回当前条目数。
            ;
            ; **返回**
            ;   (int) - 条目数
            queue->size()
        )
        self->isEmpty = lambda(()  ; -> t | nil
            ; 判断流是否为空。
            ;
            ; **返回**
            ;   (t|nil) - 空流返回 t
            queue->isEmpty()
        )
        t
    )
)
)


unuseNamespace("ycSubProcess")

; END
