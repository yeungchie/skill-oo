ycNamespace:::Require("ycPathLib")

useNamespace("ycSubProcess")


; ---------- 函数 ----------

procedure(_WaitJob(g_job g_timeout n_interval "ggx")  ; -> int | nil
    ; 等待任务结束并取回退出码；?timeout 为 nil 时分段等待，无总上限。
    ;
    ; **参数**
    ;   g_job      (AsyncJob) - 已启动的任务对象
    ;   g_timeout  (int|nil)  - 等待上限（秒）；nil 表示不限
    ;   n_interval (int)      - 等待提示间隔（秒）
    ;
    ; **返回**
    ;   (int|nil) - 退出码；进程已结束但回调仍未落地时为 nil
    if(g_timeout
    then
        g_job->wait(g_timeout n_interval)
    else
        ; ipcWait 单次上限 1,000,000 秒：按天分段等待，直到进程结束。
        while(g_job->state() != 'Dead
            g_job->wait(86400 n_interval)
        )
    )
    ; 退出码由 post 回调写入，ipcWait 返回时可能尚未送达：
    ; 进程已结束而退出码仍为空时，给回调一个短宽限窗口（最多 5 秒）。
    let((tries)
        tries = 0
        while(g_job->state() == 'Dead && g_job->returncode() == nil && tries < 50
            g_job->sleep(0.1)
            tries++
        )
        g_job->returncode()
    )
)


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
    let((job wait_interval code)
        unless(timeout == nil || (fixp(timeout) && timeout > 0)
            error("ycSubProcess::Run: ?timeout must be a positive integer, got %A"
                timeout)
        )
        unless(interval == nil || (fixp(interval) && interval > 0)
            error("ycSubProcess::Run: ?interval must be a positive integer, got %A"
                interval)
        )
        wait_interval = if(interval interval 30)
        job = apply('CreateJob g_arg ?verbose t l_args)->start()
        code = _WaitJob(job timeout wait_interval)
        when(timeout && code == nil
            let((alive)
                ; 仍非 'Dead 说明进程还在跑，必须 kill；'Dead 则等回调收尾。
                alive = job->state() != 'Dead
                when(alive
                    job->kill()
                )
                code = _WaitJob(job 5 wait_interval)
                ; 超时，或退出码始终没有落地：一律报错，绝不返回 nil 或半截结果。
                when(alive || code == nil
                    error("ycSubProcess::Run: command timed out after %ds: %s"
                        timeout job->command())
                )
            )
        )
        when(code == nil
            error("ycSubProcess::Run: exit status is not available after the command finished: %s"
                job->command())
        )
        code == 0
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
    let((job wait_interval code)
        unless(timeout == nil || (fixp(timeout) && timeout > 0)
            error("ycSubProcess::RunWithRead: ?timeout must be a positive integer, got %A"
                timeout)
        )
        unless(interval == nil || (fixp(interval) && interval > 0)
            error("ycSubProcess::RunWithRead: ?interval must be a positive integer, got %A"
                interval)
        )
        wait_interval = if(interval interval 30)
        job = apply('CreateJob g_arg l_args)->start()
        code = _WaitJob(job timeout wait_interval)
        when(timeout && code == nil
            let((alive)
                ; 仍非 'Dead 说明进程还在跑，必须 kill；'Dead 则等回调收尾。
                alive = job->state() != 'Dead
                when(alive
                    job->kill()
                )
                code = _WaitJob(job 5 wait_interval)
                ; 超时，或退出码始终没有落地：一律报错，绝不返回半截三元结果。
                when(alive || code == nil
                    error("ycSubProcess::RunWithRead: command timed out after %ds: %s"
                        timeout job->command())
                )
            )
        )
        when(code == nil
            error("ycSubProcess::RunWithRead: exit status is not available after the command finished: %s"
                job->command())
        )
        list(
            code
            job->stdout()->text()
            job->stderr()->text()
        )
    )
)


procedure(CreateJob(g_arg \@key callback userData verbose \@rest l_args "ggggg")  ; -> AsyncJob
    ; 创建异步任务对象：命令各段拼接后构造 AsyncJob（未启动）。
    ;
    ; 只有一个实参时它是完整命令串，原样交给 shell（可用管道、重定向、变量）；
    ; 给了后续参数时按参数列表拼接，每个参数单独加引号保护，空格与
    ; `;` `|` `&` `>` 等元字符不再被 shell 解释。
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
    let((command)
        command = if(l_args
        then
            buildString(foreach(mapcar x cons(g_arg l_args)
                ycPathLib::ShellQuote(stringp(x) && x || lsprintf("%A" x))
            ))
        else
            stringp(g_arg) && g_arg || lsprintf("%A" g_arg)
        )
        AsyncJob(command
            ?callback   callback
            ?userData   userData
            ?verbose    verbose
        )
    )
)


procedure(AsyncJob(t_command \@key callback userData verbose "tggg")  ; -> AsyncJob
    ; 构造 AsyncJob 实例（未启动）；一般经 CreateJob 使用，后者先拼接命令。
    ;
    ; **参数**
    ;   t_command  (str) - 完整命令串
    ;   ?callback  (any) - 事件回调函数 callback(s_event job)；默认 nil
    ;   ?userData  (any) - 随对象携带的任意数据；默认 nil
    ;   ?verbose   (t|nil) - 是否实时打印子进程输出；默认 nil
    ;
    ; **返回**
    ;   (AsyncJob) - 新任务对象，需再调用 start() 启动
    makeInstance('AsyncJob
        ?command    t_command
        ?callback   callback
        ?userData   userData
        ?verbose    verbose && t
    )
)


; ---------- 类定义 ----------

defclass(_AsyncJobData () (
    ; _AsyncJobData 数据桶：收纳任务命令与运行期状态，仅供 AsyncJob 方法闭包读写。
    command(
        \@initarg command
    )
    ipcId(
        \@initform nil
    )
    returncode(
        \@initform nil
    )
    elapsed(
        \@initform makeInstance('Elapsed)
    )
    stdout(
        \@initform makeInstance('Stream)
    )
    stderr(
        \@initform makeInstance('Stream)
    )
))

defclass(AsyncJob () (
    ; AsyncJob 任务对象：控制子进程生命周期，状态经 _AsyncJobData 持有，构造后 start() 启动。
    ; 状态在 initializeInstance 的闭包里（_AsyncJobData），只经只读方法读取。
    ; 可写配置：callback / userData / verbose。
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

    ; 只读访问方法
    command()
    ipcId()
    returncode()
    elapsed()
    stdout()
    stderr()

    ; method
    start()
    wait()
    await()
    kill()
    state()
    stop()
    continue()
    send()
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
        self->returncode()
    )
)


; ---------- 构造时安装全部方法 ----------

inScheme(

defmethod(initializeInstance (self(AsyncJob) \@key (command nil) (callback nil) (userData nil) (verbose nil))
    ; 安装 AsyncJob 全部方法：start/wait/await/kill/state/stop/continue/send/close/signal/sleep。
    ; callback / userData / verbose 由主类槽的 @initarg 接收，这里声明只为关键字表完整。
    ;
    ; **参数**
    ;   ?command  (str)     - 完整命令串；缺省或非字符串时报错
    ;   ?callback (any)     - 回调函数；由主类槽接收
    ;   ?userData (any)     - 随对象数据；由主类槽接收
    ;   ?verbose  (t|nil)   - 实时打印开关；由主类槽接收
    ;
    ; **返回**
    ;   (t) - 安装完成后返回 t
    unless(stringp(command)
        error("%A: ?command must be a string, got %A" className(self) command)
    )
    let((data)
        data = makeInstance('_AsyncJobData ?command command)
        self->command = lambda(()  ; -> str
            ; 返回创建任务时的完整命令串。
            ;
            ; **返回**
            ;   (str) - 完整命令串
            data->command
        )
        self->ipcId = lambda(()  ; -> ipcId | nil
            ; 返回底层进程间通信 ID；未启动时为 nil。
            ;
            ; **返回**
            ;   (ipcId|nil) - 进程间通信 ID；未启动为 nil
            data->ipcId
        )
        self->returncode = lambda(()  ; -> int | nil
            ; 返回进程退出码；未结束或超时后仍为 nil。
            ;
            ; **返回**
            ;   (int|nil) - 退出码；未落地为 nil
            data->returncode
        )
        self->elapsed = lambda(()  ; -> Elapsed
            ; 返回任务耗时记录对象。
            ;
            ; **返回**
            ;   (Elapsed) - 耗时记录对象
            data->elapsed
        )
        self->stdout = lambda(()  ; -> Stream
            ; 返回标准输出流对象。
            ;
            ; **返回**
            ;   (Stream) - 标准输出流
            data->stdout
        )
        self->stderr = lambda(()  ; -> Stream
            ; 返回标准错误输出流对象。
            ;
            ; **返回**
            ;   (Stream) - 标准错误输出流
            data->stderr
        )
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
            unless(data->ipcId
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
            when(data->ipcId
                _error("start" "job already started, current status is '%s'" self->state())
            )
            when(self->callback
                errset(funcall(self->callback 'beforeBegin self) t)
            )
            ; ipcBeginProcess 自己会剥离一层反斜杠：先给 " \ $ 补一层转义，
            ; 抵消它的剥离，shell 最终收到原始命令串。
            data->ipcId = ipcBeginProcess(  ; #. 读期编译一次，等价于原 _rsrec 缓存
                pcreReplace(#.pcreCompile("[\"\\\\$]") data->command "\\\\\\0" 0)
                ""
                lambda((g_cid t_data)
                    data->stdout->push(t_data)
                    when(self->verbose
                        fprintf(inSkill(IL::stdout) "%s" t_data)
                    )
                    when(self->callback
                        errset(funcall(self->callback 'stdout self) t)
                    )
                )
                lambda((g_cid t_data)
                    data->stderr->push(t_data)
                    when(self->verbose
                        fprintf(inSkill(IL::stderr) "%s" t_data)
                    )
                    when(self->callback
                        errset(funcall(self->callback 'stderr self) t)
                    )
                )
                lambda((g_cid n_code)
                    data->returncode = n_code
                    data->elapsed->mark()
                    when(self->callback
                        errset(funcall(self->callback 'post self) t)
                    )
                )
            )
            data->elapsed->mark()
            ipcWaitForProcess(data->ipcId)
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
            ipcWait(data->ipcId wait_interval n_timeout)
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
            unless(data->ipcId
                self->start()
            )
            while(!data->returncode
                when(self->state() == 'Stopped
                    _error("await" "job is stopped and cannot finish; continue() or kill() it first")
                )
                self->wait(1)
            )
            when(check && (data->returncode != 0)
                let((info)
                    unless(blankstrp(info = data->stderr->text())
                        fprintf(inSkill(IL::stderr) "%s" info)
                    )
                )
                _error("await" "job failed, returncode is %d" data->returncode)
            )
            data->stdout->text()
        )
        self->kill = lambda(()  ; -> t | nil
            ; 向进程发送 SIGKILL；返回底层 ipcKillProcess 的结果。
            ;
            ; **返回**
            ;   (t|nil) - 成功返回 t
            _checkStarted("kill")
            ipcKillProcess(data->ipcId)
        )
        self->state = lambda(()  ; -> sym
            ; 返回进程状态符号：'None（未启动）/ 'Active / 'Dead / 'Stopped。
            ;
            ; **返回**
            ;   (sym) - 未启动为 'None，否则透传 ipcId 的 state
            data->ipcId && data->ipcId->state || 'None
        )
        self->stop = lambda(()  ; -> t | nil
            ; 暂停进程，类似 Ctrl+Z；返回底层 ipcStopProcess 的结果。
            ;
            ; **返回**
            ;   (t|nil) - 成功返回 t
            _checkStarted("stop")
            ipcStopProcess(data->ipcId)
        )
        self->continue = lambda(()  ; -> t | nil
            ; 继续已暂停的进程，类似 fg；返回底层 ipcContProcess 的结果。
            ;
            ; **返回**
            ;   (t|nil) - 成功返回 t
            _checkStarted("continue")
            ipcContProcess(data->ipcId)
        )
        self->send = lambda((t_formatString \@key end("\n") \@rest l_args "ttg")  ; -> self
            ; 向子进程标准输入写入一行（lsprintf 先格式化，再补 end 结尾）。
            ;
            ; **参数**
            ;   t_formatString  (str) - 格式串
            ;   ?end            (str) - 行结尾（默认 "\n"）
            ;   l_args          (list) - 变参：格式串实参
            ;
            ; **返回**
            ;   (AsyncJob) - self；写入失败（进程已退出）时 error() 中断
            _checkStarted("send")
            ipcWriteProcess(data->ipcId
                strcat(apply('lsprintf t_formatString l_args) end)
            ) || _error("send" "job process has expired, current status is '%s'" self->state())
            self
        )
        self->close = lambda(()  ; -> t | nil
            ; 关闭子进程标准输入通道，类似 Ctrl+D；返回底层 ipcCloseProcess 的结果。
            ;
            ; **返回**
            ;   (t|nil) - 成功返回 t
            _checkStarted("close")
            ipcCloseProcess(data->ipcId)
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
            ipcSignalProcess(data->ipcId s_signal)
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
)

)


unuseNamespace("ycSubProcess")

; END
