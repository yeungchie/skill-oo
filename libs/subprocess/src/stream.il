ycNamespace:::Require("ycQueue" "ycString")

useNamespace("ycSubProcess")


; ---------- 类定义 ----------

defclass(Stream () (
    ; Stream 流对象：FIFO 累积子进程输出数据，构造后经 push() 写入。
    push()
    last()
    shift()
    peek()
    text()
    size()
    lines()
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
    ; 安装 Stream 全部方法：push/last/peek/shift/text/lines/size/isEmpty。
    ; 内部状态是一个 ycQueue::FIFO 实例，只在闭包里出现；
    ; ycQueue 未加载时以 error() 中断。
    ;
    ; **返回**
    ;   (t) - 安装完成后返回 t
    unless(fboundp('ycQueue:::FIFO)
        error("%A: ycQueue is not loaded - load it first" className(self))
    )
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
        self->peek = lambda((\@optional g_index(0) "g")  ; -> str | nil
            ; 返回指定索引的条目但不移除；索引 0 起算，负值从末尾算。
            ;
            ; **参数**
            ;   g_index  (int) - 索引；默认 0
            ;
            ; **返回**
            ;   (str|nil) - 索引条目；空流或索引越界为 nil
            let((n_size)
                unless(fixp(g_index)
                    error("%A->peek: index must be an integer (%A)" className(self) g_index)
                )
                n_size = queue->size()
                when(n_size > 0 && g_index < n_size && g_index >= -n_size
                    queue->peek(?index g_index)
                )
            )
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
        self->lines = lambda(()  ; -> int
            ; 统计当前行数；末尾没有换行的残行也计一行。
            ;
            ; **返回**
            ;   (int) - 行数；空流为 0
            unless(fboundp('ycString:::Count)
                error("%A->lines: ycString is not loaded - load it first" className(self))
            )
            let((text c)
                text = self->text()
                if(text == ""
                then 0
                else
                    c = ycString:::Count(text "\n")
                    unless(ycString:::EndsWith(text "\n")
                        c += 1
                    )
                    c
                )
            )
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
