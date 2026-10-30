useNamespace("ycSubProcess")


; ---------- 函数 ----------

procedure(Run(g_arg \@key (timeout nil) (interval nil) \@rest l_args "gggg")  ; -> t | nil
    ; 执行命令并等待任务完成，子进程输出实时打印到终端。
    ;
    ; **参数**
    ;   g_arg     (any)     - 命令；非字符串按 %A 自动转换
    ;   ?timeout  (int|nil) - 等待上限（秒）；默认 nil（不限），须为正整数
    ;   ?interval (int|nil) - 等待提示间隔（秒）；默认 nil（30），须为正整数
    ;   l_args    (list)    - 命令的其余部分；非字符串同样自动转换
    ;
    ; **返回**
    ;   (t|nil) - 正常结束（退出码 0）返回 t；退出码非零返回 nil；超时 error
    let((job wait_timeout wait_interval)
        unless(timeout == nil || (fixp(timeout) && timeout > 0)
            error("ycSubProcess::Run: ?timeout must be a positive integer, got %A"
                timeout)
        )
        unless(interval == nil || (fixp(interval) && interval > 0)
            error("ycSubProcess::Run: ?interval must be a positive integer, got %A"
                interval)
        )
        ; 省略 ?timeout 时沿用 wait() 的默认上限，保持旧行为不变。
        wait_timeout = if(timeout timeout 1000000)
        wait_interval = if(interval interval 30)
        job = apply('CreateJob g_arg ?verbose t l_args)->start()
        job->wait(wait_timeout wait_interval)
        ; ipcWait 永远返回 t，超时只能靠 returncode 还是 nil 来观察；
        ; 退出码由 post 回调写入，wait 返回时可能尚未送达。
        when(timeout && job->returncode == nil
            let((alive)
                ; 仍非 'Dead 说明进程还在跑，必须 kill；'Dead 则等回调收尾。
                alive = job->state() != 'Dead
                when(alive
                    job->kill()
                )
                job->wait(5)
                ; 超时，或退出码始终没有落地：一律报错，绝不返回 nil 或半截结果。
                when(alive || job->returncode == nil
                    error("ycSubProcess::Run: command timed out after %ds: %s"
                        timeout job->cmd)
                )
            )
        )
        job->returncode == 0
    )
)


procedure(RunWithRead(g_arg \@key (timeout nil) (interval nil) \@rest l_args "gggg")  ; -> (returncode:int, stdout:str, stderr:str)
    ; 执行命令并等待完成，分别读取标准输出与标准错误，不向终端打印。
    ;
    ; **参数**
    ;   g_arg     (any)     - 命令；非字符串按 %A 自动转换
    ;   ?timeout  (int|nil) - 等待上限（秒）；默认 nil（不限），须为正整数
    ;   ?interval (int|nil) - 等待提示间隔（秒）；默认 nil（30），须为正整数
    ;   l_args    (list)    - 命令的其余部分；非字符串同样自动转换
    ;
    ; **返回**
    ;   (returncode:int, stdout:str, stderr:str) - 固定三元列表：退出码、标准输出、标准错误；超时 error
    let((job wait_timeout wait_interval)
        unless(timeout == nil || (fixp(timeout) && timeout > 0)
            error("ycSubProcess::RunWithRead: ?timeout must be a positive integer, got %A"
                timeout)
        )
        unless(interval == nil || (fixp(interval) && interval > 0)
            error("ycSubProcess::RunWithRead: ?interval must be a positive integer, got %A"
                interval)
        )
        ; 省略 ?timeout 时沿用 wait() 的默认上限，保持旧行为不变。
        wait_timeout = if(timeout timeout 1000000)
        wait_interval = if(interval interval 30)
        job = apply('CreateJob g_arg l_args)->start()
        job->wait(wait_timeout wait_interval)
        ; ipcWait 永远返回 t，超时只能靠 returncode 还是 nil 来观察；
        ; 退出码由 post 回调写入，wait 返回时可能尚未送达。
        when(timeout && job->returncode == nil
            let((alive)
                ; 仍非 'Dead 说明进程还在跑，必须 kill；'Dead 则等回调收尾。
                alive = job->state() != 'Dead
                when(alive
                    job->kill()
                )
                job->wait(5)
                ; 超时，或退出码始终没有落地：一律报错，绝不返回半截三元结果。
                when(alive || job->returncode == nil
                    error("ycSubProcess::RunWithRead: command timed out after %ds: %s"
                        timeout job->cmd)
                )
            )
        )
        list(
            job->returncode
            job->stdout->text()
            job->stderr->text()
        )
    )
)


procedure(CreateJob(g_arg \@key callback userData verbose \@rest l_args "ggggg")  ; -> AsyncJob
    ; 创建异步任务对象：命令各段拼接后构造 AsyncJob（未启动）。
    ;
    ; **参数**
    ;   g_arg      (any) - 命令；非字符串按 %A 自动转换
    ;   l_args     (list) - 命令的其余部分；非字符串同样自动转换
    ;   ?callback  (any) - 事件回调函数 callback(s_event job)；默认 nil
    ;   ?userData  (any) - 随对象携带的任意数据；默认 nil
    ;   ?verbose   (t|nil) - 是否实时打印子进程输出；默认 nil
    ;
    ; **返回**
    ;   (AsyncJob) - 未启动的任务对象，需再调用 start() 启动
    AsyncJob(
        buildString(foreach(mapcar x cons(g_arg l_args)
            stringp(x) && x || lsprintf("%A" x)
        ))
        ?callback   callback
        ?userData   userData
        ?verbose    verbose
    )
)


procedure(AsyncJob(t_cmd \@key callback userData verbose "tggg")  ; -> AsyncJob
    ; 构造 AsyncJob 实例（未启动）；一般经 CreateJob 使用，后者先拼接命令。
    ;
    ; **参数**
    ;   t_cmd      (str) - 完整命令串
    ;   ?callback  (any) - 事件回调函数 callback(s_event job)；默认 nil
    ;   ?userData  (any) - 随对象携带的任意数据；默认 nil
    ;   ?verbose   (t|nil) - 是否实时打印子进程输出；默认 nil
    ;
    ; **返回**
    ;   (AsyncJob) - 新任务对象，需再调用 start() 启动
    makeInstance('AsyncJob
        ?cmd        t_cmd
        ?callback   callback
        ?userData   userData
        ?verbose    verbose && t
    )
)


; ---------- 类定义 ----------

defclass(AsyncJob () (
    ; AsyncJob 任务对象：控制子进程生命周期并持有 stdout/stderr/耗时状态，构造后 start() 启动。
    ; argument
    cmd(
        \@initarg cmd
    )
    callback(
        \@initarg callback
        \@initform lambda((s_event job "sg") nil)
    )
    userData(
        \@initarg userData
        \@initform nil
    )
    verbose(
        \@initarg verbose
        \@initform nil
    )

    ; parameter
    ipcId(
        \@initform nil
    )
    returncode(
        \@initform nil
    )
    elapsed(
        \@initform makeInstance('Elapsed)
    )

    ; stream
    stdout(
        \@initform makeInstance('Stream)
    )
    stderr(
        \@initform makeInstance('Stream)
    )

    ; method
    start()
    wait()
    await()
    kill()
    state()
    stop()
    continue()
    print()
    close()
    signal()
    sleep()
))

defmethod(printself (self(AsyncJob))  ; -> str
    ; 返回任务对象的打印描述串，形如 <ycSubProcess::AsyncJob status=None, returncode=nil>。
    ;
    ; **返回**
    ;   (str) - lsprintf 生成；status 取 state()，returncode 取当前值
    lsprintf("<%A status=%A, returncode=%A>"
        className(self)
        self->state()
        self->returncode
    )
)


; ---------- 构造时安装全部方法 ----------

inScheme(let((_rsrec)

_rsrec = pcreCompile("[\"\\\\$]")

procedure(_rstring(t_s "t")  ; -> str
    ; 将命令串转为原始字符串：转义 " 与 $，阻止 shell 展开。
    ;
    ; **参数**
    ;   t_s  (str) - 待转义命令串
    ;
    ; **返回**
    ;   (str) - 转义后的命令串
    pcreReplace(_rsrec t_s "\\\\\\0" 0)
)

defmethod(initializeInstance (self(AsyncJob) \@rest l_args)
    ; 安装 AsyncJob 全部方法：start/wait/await/kill/state/stop/continue/print/close/signal/sleep。
    ;
    ; **参数**
    ;   l_args  (list) - 变参：附加初始化参数，本实现忽略
    ;
    ; **返回**
    ;   (t) - 安装完成后返回 t
    procedure(_error(t_method t_formatString \@rest l_args "ttg")  ; -> never
        ; 按统一格式 error() 中断：消息形如 <类名>-><方法名>: <说明>。
        ;
        ; **参数**
        ;   t_method        (str) - 出错的方法名
        ;   t_formatString  (str) - 错误说明格式串（lsprintf 格式）
        ;   l_args          (list) - 变参：格式串实参
        ;
        ; **返回**
        ;   (never) - 总是调用 error()，不返回
        error("%A->%s: %s" className(self) t_method apply('lsprintf t_formatString l_args))
    )
    procedure(_checkStarted(t_method "t")
        ; 前置校验：任务未启动（ipcId 为 nil）时以 _error 中断。
        ;
        ; **参数**
        ;   t_method  (str) - 归属的方法名，并入错误消息
        ;
        ; **返回**
        ;   (t) - 已启动时返回 t
        unless(self->ipcId
            _error(t_method "job has not started, current status is '%s'" self->state())
        )
    )
    self->start = lambda(()  ; -> self
        ; 启动子进程：注册 stdout/stderr/退出回调并等待到进程启动完成；
        ; 'beforeBegin 在启动前、'afterBegin 在启动后触发；回调抛出的错误只打印、不打断任务。
        ; 已启动（ipcId 非 nil）时 error() 中断。
        ;
        ; **返回**
        ;   (AsyncJob) - self
        when(self->ipcId
            _error("start" "job already started, current status is '%s'" self->state())
        )
        when(self->callback
            errset(funcall(self->callback 'beforeBegin self) t)
        )
        self->ipcId = ipcBeginProcess(_rstring(self->cmd) ""
            lambda((g_cid t_data)
                self->stdout->push(t_data)
                when(self->verbose
                    fprintf(inSkill(IL::stdout) "%s" t_data)
                )
                when(self->callback
                    errset(funcall(self->callback 'stdout self) t)
                )
            )
            lambda((g_cid t_data)
                self->stderr->push(t_data)
                when(self->verbose
                    fprintf(inSkill(IL::stderr) "%s" t_data)
                )
                when(self->callback
                    errset(funcall(self->callback 'stderr self) t)
                )
            )
            lambda((g_cid n_code)
                self->returncode = n_code
                self->elapsed->mark()
                when(self->callback
                    errset(funcall(self->callback 'post self) t)
                )
            )
        )
        self->elapsed->mark()
        ipcWaitForProcess(self->ipcId)
        when(self->callback
            errset(funcall(self->callback 'afterBegin self) t)
        )
        self
    )
    self->wait = lambda((\@optional n_timeout(1000000) wait_interval(30) "xx")  ; -> self
        ; 等待进程结束或超时；间隔 wait_interval 提示一次（单位与默认值见 README）。
        ;
        ; **参数**
        ;   n_timeout   (int) - 等待超时（默认 1000000）
        ;   wait_interval  (int) - 提示打印间隔（默认 30）
        ;
        ; **返回**
        ;   (AsyncJob) - self
        _checkStarted("wait")
        ipcWait(self->ipcId wait_interval n_timeout)
        self
    )
    self->await = lambda((\@key check "g")  ; -> str
        ; 未启动则先启动，随后等待进程结束；?check 非 nil 且返回码非零时
        ; 打印 stderr 全量并以 error() 中断；任务处于 'Stopped 时无法等到
        ; 结束，会以 error() 中断。
        ;
        ; **参数**
        ;   ?check  (t|nil) - 返回码非零时是否报错；默认 nil
        ;
        ; **返回**
        ;   (str) - 进程 stdout 全量文本
        unless(self->ipcId
            self->start()
        )
        while(!self->returncode
            when(self->state() == 'Stopped
                _error("await" "job is stopped and cannot finish; continue() or kill() it first")
            )
            self->wait(1)
        )
        when(check && (self->returncode != 0)
            let((info)
                unless(blankstrp(info = self->stderr->text())
                    fprintf(inSkill(IL::stderr) "%s" info)
                )
            )
            _error("await" "job failed, returncode is %d" self->returncode)
        )
        self->stdout->text()
    )
    self->kill = lambda(()  ; -> t | nil
        ; 向进程发送 SIGKILL；返回底层 ipcKillProcess 的结果。
        ;
        ; **返回**
        ;   (t|nil) - 成功返回 t
        _checkStarted("kill")
        ipcKillProcess(self->ipcId)
    )
    self->state = lambda(()  ; -> sym
        ; 返回进程状态符号：'None（未启动）/ 'Active / 'Dead / 'Stopped。
        ;
        ; **返回**
        ;   (sym) - 未启动为 'None，否则透传 ipcId 的 state
        self->ipcId && self->ipcId->state || 'None
    )
    self->stop = lambda(()  ; -> t | nil
        ; 暂停进程，类似 Ctrl+Z；返回底层 ipcStopProcess 的结果。
        ;
        ; **返回**
        ;   (t|nil) - 成功返回 t
        _checkStarted("stop")
        ipcStopProcess(self->ipcId)
    )
    self->continue = lambda(()  ; -> t | nil
        ; 继续已暂停的进程，类似 fg；返回底层 ipcContProcess 的结果。
        ;
        ; **返回**
        ;   (t|nil) - 成功返回 t
        _checkStarted("continue")
        ipcContProcess(self->ipcId)
    )
    self->print = lambda((t_formatString \@key end("\n") \@rest l_args "ttg")  ; -> self
        ; 向子进程标准输入写入一行（lsprintf 先格式化，再补 end 结尾）。
        ;
        ; **参数**
        ;   t_formatString  (str) - 格式串
        ;   ?end            (str) - 行结尾（默认 "\n"）
        ;   l_args          (list) - 变参：格式串实参
        ;
        ; **返回**
        ;   (AsyncJob) - self；写入失败（进程已退出）时 error() 中断
        _checkStarted("print")
        ipcWriteProcess(self->ipcId
            strcat(apply('lsprintf t_formatString l_args) end)
        ) || _error("print" "job process has expired, current status is '%s'" self->state())
        self
    )
    self->close = lambda(()  ; -> t | nil
        ; 关闭子进程标准输入通道，类似 Ctrl+D；返回底层 ipcCloseProcess 的结果。
        ;
        ; **返回**
        ;   (t|nil) - 成功返回 t
        _checkStarted("close")
        ipcCloseProcess(self->ipcId)
    )
    self->signal = lambda((s_signal "s")  ; -> t | nil
        ; 向进程发送信号；返回底层 ipcSignalProcess 的结果。
        ;
        ; **参数**
        ;   s_signal  (sym) - 信号符号：'INT 'TERM 'QUIT 'KILL
        ;
        ; **返回**
        ;   (t|nil) - 成功返回 t
        _checkStarted("signal")
        ipcSignalProcess(self->ipcId s_signal)
    )
    self->sleep = lambda((\@optional n_second(0) "n")  ; -> self
        ; 令父进程（当前会话）休眠指定秒数。
        ;
        ; **参数**
        ;   n_second  (num) - 休眠秒数（默认 0）
        ;
        ; **返回**
        ;   (AsyncJob) - self
        ipcSleepMilli(fix2(n_second * 1e3))
        self
    )
    t
)

))


unuseNamespace("ycSubProcess")

; END
