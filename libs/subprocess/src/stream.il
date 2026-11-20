ycNamespace:::Require("ycQueue" "ycString")

useNamespace("ycSubProcess")


; ---------- 类定义 ----------

defclass(Stream () (
    ; Stream 流对象：FIFO 累积子进程输出数据，构造后经 push() 写入。
    push()
    last()
    read()
    readLine()
    peekLine()
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
defmethod(initializeInstance (self(Stream) \@key (owner nil))
    ; 安装 Stream 全部方法：push/last/read/readLine/peekLine/peek/text/size/lines/isEmpty。
    ; 内部状态是一个 ycQueue::FIFO 实例和队首剩余串 front，只在闭包里出现；
    ; owner 是可选的任务对象，用于读取时等待子进程输出。
    ; ycQueue 未加载时以 error() 中断。
    ;
    ; **参数**
    ;   ?owner  (AsyncJob|nil) - 关联任务；手工创建时为 nil
    ;
    ; **返回**
    ;   (t) - 安装完成后返回 t
    unless(fboundp('ycQueue:::FIFO)
        error("%A: ycQueue is not loaded - load it first" className(self))
    )
    let((queue front)
        queue = ycQueue:::FIFO()
        front = ""
        procedure(_checkTimeout(t_method n_timeout "tn")  ; -> t
            ; 校验 timeout：必须是大于等于 0 的数值。
            ;
            ; **参数**
            ;   t_method   (str) - 调用方方法名
            ;   n_timeout  (num) - 等待秒数
            ;
            ; **返回**
            ;   (t) - 合法时返回 t；负数中断
            unless(numberp(n_timeout) && n_timeout >= 0
                error("%A->%s: ?timeout must be a non-negative number, got %A"
                    className(self) t_method n_timeout)
            )
            t
        )
        procedure(_requireString(t_method "t")  ; -> t
            ; 确认 ycString 已加载；行读取与行统计依赖它。
            ;
            ; **参数**
            ;   t_method  (str) - 调用方方法名
            ;
            ; **返回**
            ;   (t) - 已加载
            unless(fboundp('ycString:::Split) && fboundp('ycString:::Count)
                && fboundp('ycString:::EndsWith)
                error("%A->%s: ycString is not loaded - load it first"
                    className(self) t_method)
            )
            t
        )
        procedure(_pump()  ; -> t
            ; 让出父进程一小段时间，派发 IPC 输出回调。
            ;
            ; **返回**
            ;   (t) - 恒为 t
            when(owner
                owner->sleep(0.02)
            )
            t
        )
        procedure(_canWait(t_method "t")  ; -> t | nil
            ; 判断当前是否还能等待更多输出；Stopped 时中断。
            ;
            ; **参数**
            ;   t_method  (str) - 调用方方法名
            ;
            ; **返回**
            ;   (t|nil) - 可继续等待为 t
            let((state)
                state = owner && owner->state()
                cond(
                    ((state == 'Active) t)
                    ((state == 'Stopped)
                        error("%A->%s: job is stopped and cannot produce more data; continue() or kill() it first"
                            className(self) t_method)
                    )
                    ((state == 'Dead && owner->returncode() == nil) t)
                    (t nil)
                )
            )
        )
        procedure(_atEnd()  ; -> t | nil
            ; 判断数据源是否已经结束：无 owner、未启动或已退出且退出码落地。
            ;
            ; **返回**
            ;   (t|nil) - 已结束为 t
            let((state)
                state = owner && owner->state()
                cond(
                    ((!state) t)
                    ((state == 'None) t)
                    ((state == 'Dead) owner->returncode() != nil)
                    (t nil)
                )
            )
        )
        procedure(_hasNewline()  ; -> t | nil
            ; 判断 front 或 FIFO 中是否已经存在换行符。
            ;
            ; **返回**
            ;   (t|nil) - 存在换行为 t
            let((items found)
                when(front != "" && index(front "\n")
                    found = t
                )
                unless(found
                    items = queue->toList()
                    when(items
                        for(i 0 length(items) - 1
                            when(!found && index(nth(i items) "\n")
                                found = t
                            )
                        )
                    )
                )
                found
            )
        )
        procedure(_splitAtNewline(t_text "t")  ; -> list[str]
            ; 在第一个换行符处切成 (含换行的前半段, 后半段)。
            ;
            ; **参数**
            ;   t_text  (str) - 至少含一个换行符的文本
            ;
            ; **返回**
            ;   (list[str]) - (line rest)
            let((len cut pos)
                len = length(t_text)
                cut = index(t_text "\n")
                unless(cut
                    error("%A->readLine: internal error - split called without a newline"
                        className(self))
                )
                pos = len - length(cut) + 1
                ; index 返回从换行符起的子串，用长度差反推它前面的字符数。
                list(
                    strcat(if(pos > 1 substring(t_text 1 pos - 1) "") "\n")
                    if(pos < len substring(t_text pos + 1 len - pos) "")
                )
            )
        )
        procedure(_takeLine()  ; -> str
            ; 从 front / FIFO 中取走第一条完整行（含换行符）。
            ;
            ; **返回**
            ;   (str) - 取出的行
            let((pieces parts item found)
                pieces = cons(nil nil)
                when(front != ""
                    if(index(front "\n")
                    then
                        parts = _splitAtNewline(front)
                        pieces = tconc(pieces car(parts))
                        front = cadr(parts)
                        found = t
                    else
                        pieces = tconc(pieces front)
                        front = ""
                    )
                )
                while(!found && !queue->isEmpty()
                    item = queue->get()
                    if(index(item "\n")
                    then
                        parts = _splitAtNewline(item)
                        pieces = tconc(pieces car(parts))
                        front = cadr(parts)
                        found = t
                    else
                        pieces = tconc(pieces item)
                    )
                )
                buildString(car(pieces) "")
            )
        )
        procedure(_takeAll()  ; -> str | nil
            ; 取走当前全部剩余文本；空流返回 nil。
            ;
            ; **返回**
            ;   (str|nil) - 剩余文本
            let((result)
                result = self->text(?clear t)
                if(result == "" nil result)
            )
        )
        procedure(_takeRead()  ; -> str | nil
            ; 取走一条原始数据：优先 front，其次 FIFO。
            ;
            ; **返回**
            ;   (str|nil) - 原始数据
            if(front != ""
                let((value)
                    value = front
                    front = ""
                    value
                )
                queue->get(?onEmpty nil)
            )
        )
        procedure(_lines(t_text "t")  ; -> list[str] | nil
            ; 把当前文本按行切开；末尾换行不产生额外空行。
            ;
            ; **参数**
            ;   t_text  (str) - 当前全量文本
            ;
            ; **返回**
            ;   (list[str]|nil) - 行列表；空文本为 nil
            if(t_text == ""
                nil
                let((parts n result i tail)
                    parts = ycString:::Split(t_text ?sep "\n" ?keepEmpty t)
                    n = length(parts)
                    result = cons(nil nil)
                    tail = ycString:::EndsWith(t_text "\n")
                    for(i 0 n - 1
                        cond(
                            ((i < n - 1)
                                result = tconc(result strcat(nth(i parts) "\n"))
                            )
                            ((!tail)
                                result = tconc(result nth(i parts))
                            )
                        )
                    )
                    car(result)
                )
            )
        )
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
            if(!queue->isEmpty()
                queue->peek(?index -1)
                if(front == "" nil front)
            )
        )
        self->read = lambda((\@key (timeout 0) "n")  ; -> str | nil
            ; 取走一条原始数据；没有数据时按 ?timeout 等待。
            ;
            ; **参数**
            ;   ?timeout  (num) - 最多等待秒数；默认 0 不等待
            ;
            ; **返回**
            ;   (str|nil) - 原始数据；无数据为 nil
            _checkTimeout("read" timeout)
            if(front != "" || !queue->isEmpty()
                _takeRead()
                if(timeout > 0 && _canWait("read")
                    let((i ticks)
                        ticks = fix(timeout / 0.02) + 1
                        i = 0
                        while(i < ticks && front == "" && queue->isEmpty()
                            && _canWait("read")
                            _pump()
                            i++
                        )
                        _takeRead()
                    )
                    nil
                )
            )
        )
        self->readLine = lambda((\@key (timeout 0) "n")  ; -> str | nil
            ; 读取第一行（含换行符）；没有换行时按 ?timeout 等待。
            ;
            ; **参数**
            ;   ?timeout  (num) - 最多等待秒数；默认 0 不等待
            ;
            ; **返回**
            ;   (str|nil) - 一行；无数据为 nil
            _checkTimeout("readLine" timeout)
            cond(
                (_hasNewline()
                    _takeLine()
                )
                (_atEnd()
                    _takeAll()
                )
                ((timeout > 0 && _canWait("readLine"))
                    let((i ticks)
                        ticks = fix(timeout / 0.02) + 1
                        i = 0
                        while(i < ticks && !_hasNewline() && !_atEnd()
                            && _canWait("readLine")
                            _pump()
                            i++
                        )
                        cond(
                            (_hasNewline() _takeLine())
                            (_atEnd() _takeAll())
                            (t nil)
                        )
                    )
                )
                (t nil)
            )
        )
        self->peekLine = lambda((\@optional x_index(0) "x")  ; -> str | nil
            ; 返回指定行但不移除；索引 0 起算，负值从末尾算。
            ;
            ; **参数**
            ;   x_index  (int) - 行索引；默认 0
            ;
            ; **返回**
            ;   (str|nil) - 行；空流或索引越界为 nil
            _requireString("peekLine")
            let((lines n pos)
                lines = _lines(self->text())
                n = if(lines length(lines) 0)
                pos = if(x_index < 0 n + x_index x_index)
                when(pos >= 0 && pos < n
                    nth(pos lines)
                )
            )
        )
        self->peek = lambda((\@optional x_index(0) "x")  ; -> str | nil
            ; 返回指定索引的条目但不移除；索引 0 起算，负值从末尾算。
            ;
            ; **参数**
            ;   x_index  (int) - 索引；默认 0
            ;
            ; **返回**
            ;   (str|nil) - 索引条目；空流或索引越界为 nil
            let((n_size pos)
                n_size = queue->size() + if(front == "" 0 1)
                when(n_size > 0 && x_index < n_size && x_index >= -n_size
                    pos = if(x_index < 0 n_size + x_index x_index)
                    cond(
                        ((front == "")
                            queue->peek(?index x_index)
                        )
                        ((pos == 0)
                            front
                        )
                        (t
                            queue->peek(?index pos - 1)
                        )
                    )
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
            let((result)
                result = strcat(front
                    if(queue->isEmpty()
                        ""
                        buildString(queue->toList(?clear clear) "")
                    )
                )
                when(clear
                    front = ""
                )
                result
            )
        )
        self->size = lambda(()  ; -> int
            ; 返回当前逻辑条目数；按行读取拆出的剩余串计一条。
            ;
            ; **返回**
            ;   (int) - 条目数
            queue->size() + if(front == "" 0 1)
        )
        self->lines = lambda(()  ; -> int
            ; 统计当前行数；末尾没有换行的残行也计一行。
            ;
            ; **返回**
            ;   (int) - 行数；空流为 0
            _requireString("lines")
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
            front == "" && queue->isEmpty()
        )
        t
    )
)
)


unuseNamespace("ycSubProcess")

; END
