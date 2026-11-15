ycNamespace:::Require("ycPathLib")
ycNamespace:::Require("ycSubProcess")

useNamespace("ycSQLite")


_DefaultClient = nil
_WrapperPath = nil
let((dir)
    dir = ycPathLib::CurrentFile()->parent()
    _WrapperPath = dir->join("sqlite3.sh")->str()
)


defclass(_ClientData () (
    ; _ClientData 数据桶：客户端命令、验证状态与能力信息。
    command(
        \@initarg command
        \@initform nil
    )
    timeout(
        \@initarg timeout
        \@initform nil
    )
    validated(
        \@initarg validated
        \@initform nil
    )
    valid(
        \@initarg valid
        \@initform nil
    )
    version(
        \@initarg version
        \@initform nil
    )
    versionTuple(
        \@initarg versionTuple
        \@initform nil
    )
    features(
        \@initarg features
        \@initform nil
    )
    diagnostics(
        \@initarg diagnostics
        \@initform ""
    )
))

defclass(Client () (
    ; Client SQLite 客户端配置与验证状态。
    _data(
        \@initarg _data
        \@initform nil
    )
    command()
    timeout()
    validate()
    isValid()
    version()
    versionTuple()
    features()
    supports()
    diagnostics()
    sessionCommand()
))


procedure(_ParseVersion(t_text t_context "tt")  ; -> list
    ; 解析 sqlite3 --version 输出的版本号。
    ;
    ; **参数**
    ;   t_text     (str) - --version 的完整输出
    ;   t_context  (str) - 错误消息上下文
    ;
    ; **返回**
    ;   (list[str list[int]]) - 原始版本串与前三个数值分量；格式非法时 error() 中断
    let((line text parts)
        unless(stringp(t_text)
            error("%s: version output must be a string, got %A"
                t_context t_text)
        )
        line = car(_SplitLines(t_text))
        unless(line
            error("%s: --version returned no output" t_context)
        )
        text = car(_SplitBy(line " "))
        unless(pcreMatchp("^[0-9]+\\.[0-9]+\\.[0-9]+" text)
            error("%s: unsupported version output %A" t_context line)
        )
        parts = _SplitBy(text ".")
        list(text list(
            atoi(nth(0 parts))
            atoi(nth(1 parts))
            atoi(nth(2 parts))
        ))
    )
)


procedure(_CheckCommandList(l_cmd "l")  ; -> list[str]
    ; 校验并返回命令列表。
    ;
    ; **参数**
    ;   l_cmd  (list[str]) - 命令及参数列表
    ;
    ; **返回**
    ;   (list[str]) - 原列表；类型非法时 error() 中断
    unless(l_cmd && listp(l_cmd)
        error("ycSQLite::Client: command must be a non-empty list of strings")
    )
    for(i 1 length(l_cmd)
        unless(stringp(nth(i - 1 l_cmd))
            error("ycSQLite::Client: command element %d must be a string, got %A"
                i nth(i - 1 l_cmd))
        )
    )
    l_cmd
)


procedure(_CommandText(l_cmd "l")  ; -> str
    ; 返回命令列表的显示文本。
    ;
    ; **参数**
    ;   l_cmd  (list[str]) - 命令列表
    ;
    ; **返回**
    ;   (str) - 空格连接的显示文本
    buildString(l_cmd " ")
)


procedure(_ErrText(g_err "g")  ; -> str
    ; 从 errset.errset 提取错误消息。
    ;
    ; **参数**
    ;   g_err  (list|nil) - errset.errset
    ;
    ; **返回**
    ;   (str) - 错误消息；无法提取时返回通用说明
    if(g_err && 4 <= length(g_err) && car(car(cdr(cdr(cdr(cdr(g_err))))))
    then
        car(car(cdr(cdr(cdr(cdr(g_err))))))
    else
        "unknown client validation error"
    )
)


procedure(_RunCommand(l_cmd g_timeout "lg")  ; -> list
    ; 同步执行客户端命令并返回退出码与输出。
    ;
    ; **参数**
    ;   l_cmd      (list[str]) - 命令列表
    ;   g_timeout  (int|nil) - 等待秒数；nil 使用 5 秒
    ;
    ; **返回**
    ;   (list(int str str)) - 退出码、stdout、stderr；超时/无退出码时 error() 中断
    let((job limit n)
        job = apply('ycSubProcess::CreateJob car(l_cmd) cdr(l_cmd))->start()
        limit = if(g_timeout g_timeout 5)
        job->wait(limit 1)
        n = 0
        while(n < 50 && job->state() != 'Dead && job->returncode() == nil
            job->sleep(0.1)
            n++
        )
        when(job->state() != 'Dead
            job->kill()
            error("ycSQLite::Client: command timed out after %ds: %s"
                limit _CommandText(l_cmd))
        )
        when(job->returncode() == nil
            error("ycSQLite::Client: command finished without an exit status: %s"
                _CommandText(l_cmd))
        )
        list(job->returncode() job->stdout()->text() job->stderr()->text())
    )
)


procedure(_SessionProbe(l_cmd g_timeout "lg")  ; -> t | nil
    ; 启动一次会话并验证标记往返。
    ;
    ; **参数**
    ;   l_cmd      (list[str]) - 会话启动命令
    ;   g_timeout  (int|nil) - 等待秒数；nil 使用 5 秒
    ;
    ; **返回**
    ;   (t|nil) - 成功为 t；失败返回 nil（进程被清理）
    let((job limit n marker text)
        l_cmd = _CheckCommandList(l_cmd)
        limit = if(g_timeout g_timeout 5)
        marker = "__YC_SQLITE_READY__"
        job = apply('ycSubProcess::CreateJob car(l_cmd) cdr(l_cmd))->start()
        job->sleep(0.2)
        job->send(".print %s" marker)
        n = 0
        while(n < limit * 10 && job->state() != 'Dead
            text = job->stdout()->text()
            when(index(text marker)
                n = limit * 10
            )
            unless(index(text marker)
                job->sleep(0.1)
                n++
            )
        )
        text = job->stdout()->text()
        when(job->state() != 'Dead
            job->send(".quit")
            job->sleep(0.2)
            when(job->state() != 'Dead
                job->kill()
            )
        )
        index(text marker) != nil
    )
)


procedure(_ValidateClient(g_data "g")  ; -> t
    ; 执行客户端完整验证并写入数据桶。
    ;
    ; **参数**
    ;   g_data  (_ClientData) - 客户端数据桶
    ;
    ; **返回**
    ;   (t) - 验证通过；失败时 error() 中断
    let((res versionLine parsed testOut sessionCmd)
        g_data->validated = nil
        g_data->valid = nil
        g_data->diagnostics = ""
        g_data->version = nil
        g_data->versionTuple = nil
        g_data->features = nil
        res = _RunCommand(
            append(g_data->command list("--version"))
            g_data->timeout
        )
        unless(car(res) == 0
            error("ycSQLite::Client->validate: --version exited with %d: %s"
                car(res) caddr(res))
        )
        versionLine = car(_SplitLines(cadr(res)))
        unless(versionLine
            error("ycSQLite::Client->validate: --version returned no output")
        )
        parsed = _ParseVersion(versionLine "ycSQLite::Client->validate")
        g_data->version = car(parsed)
        g_data->versionTuple = cadr(parsed)
        res = _RunCommand(
            append(g_data->command
                list("-csv" ":memory:" "select 1, typeof(1);"))
            g_data->timeout
        )
        testOut = cadr(res)
        unless(car(res) == 0 && index(testOut "1,integer")
            error("ycSQLite::Client->validate: memory probe failed: %s"
                if(blankstrp(caddr(res)) testOut caddr(res)))
        )
        g_data->features = list('memory 'csv)
        when(_CommandExists("stdbuf")
            sessionCmd = append(
                list("stdbuf" "-oL" "-eL")
                append(g_data->command list("-batch" ":memory:"))
            )
            when(_SessionProbe(sessionCmd g_data->timeout)
                g_data->features = cons('session g_data->features)
            )
        )
        g_data->valid = t
        g_data->validated = t
        t
    )
)


procedure(_CommandExists(t_name "t")  ; -> t | nil
    ; 检查命令是否在 PATH 中可用。
    ;
    ; **参数**
    ;   t_name  (str) - 命令名
    ;
    ; **返回**
    ;   (t|nil) - 存在且可执行时为 t
    let((res)
        res = errset(
            _RunCommand(list("sh" "-c" strcat("command -v " t_name)) 5)
            nil
        )
        res && car(res) && car(car(res)) == 0
            && !blankstrp(cadr(car(res)))
    )
)


defmethod(printself (self(Client))  ; -> str
    ; 返回客户端的打印描述串。
    ;
    ; **返回**
    ;   (str) - <ycSQLite::Client valid=... version="...">
    lsprintf("<%A valid=%A version=%A>"
        className(self) self->isValid() self->version())
)


inScheme(
procedure(_InstallClient(self "g")  ; -> t
    ; 安装 Client 的全部方法。
    ;
    ; **返回**
    ;   (t) - 安装完成
    self->command = lambda(()  ; -> list[str]
        ; 返回基础命令列表。
        ;
        ; **返回**
        ;   (list[str]) - 命令列表浅拷贝
        copy(self->_data->command)
    )
    self->timeout = lambda(()  ; -> int | nil
        ; 返回默认等待秒数。
        ;
        ; **返回**
        ;   (int|nil) - 默认等待秒数
        self->_data->timeout
    )
    self->validate = lambda(()  ; -> Client
        ; 执行并缓存客户端验证。
        ;
        ; **返回**
        ;   (Client) - self；失败时记录诊断但不抛错
        unless(self->_data->validated
            let((res)
                res = errset(_ValidateClient(self->_data) nil)
                unless(res
                    self->_data->valid = nil
                    self->_data->validated = t
                    self->_data->diagnostics = _ErrText(errset.errset)
                )
            )
        )
        self
    )
    self->isValid = lambda(()  ; -> t | nil
        ; 客户端是否验证通过。
        ;
        ; **返回**
        ;   (t|nil) - 通过为 t
        self->_data->valid
    )
    self->version = lambda(()  ; -> str | nil
        ; 返回 SQLite 版本串。
        ;
        ; **返回**
        ;   (str|nil) - 版本串
        self->_data->version
    )
    self->versionTuple = lambda(()  ; -> list[int] | nil
        ; 返回三段版本号。
        ;
        ; **返回**
        ;   (list[int]|nil) - 主、次、补丁版本
        when(self->_data->versionTuple copy(self->_data->versionTuple))
    )
    self->features = lambda(()  ; -> list[sym]
        ; 返回已验证能力列表。
        ;
        ; **返回**
        ;   (list[sym]) - 能力符号列表
        when(self->_data->features copy(self->_data->features))
    )
    self->supports = lambda((s_feature "s")  ; -> t | nil
        ; 查询是否支持某项能力。
        ;
        ; **参数**
        ;   s_feature  (sym) - 能力名
        ;
        ; **返回**
        ;   (t|nil) - 支持为 t
        member(s_feature self->_data->features) != nil
    )
    self->diagnostics = lambda(()  ; -> str
        ; 返回最近一次验证诊断。
        ;
        ; **返回**
        ;   (str) - 成功为空串
        self->_data->diagnostics
    )
    self->sessionCommand = lambda((t_path "t")  ; -> list[str]
        ; 返回长驻会话启动命令。
        ;
        ; **参数**
        ;   t_path  (str) - 数据库路径
        ;
        ; **返回**
        ;   (list[str]) - stdbuf、基础命令、-batch 与路径
        unless(stringp(t_path) && t_path != ""
            error("%A->sessionCommand: path must be a non-empty string"
                className(self))
        )
        append(
            list("stdbuf" "-oL" "-eL")
            append(self->_data->command list("-batch" t_path))
        )
    )
    t
)
)


procedure(Client(\@key (command nil) (executable nil) (unsetEnv nil) (timeout nil) "gggg")  ; -> Client
    ; 构造 SQLite 客户端配置。
    ;
    ; **参数**
    ;   ?command    (list[str]) - 完整基础命令；与 ?executable 互斥
    ;   ?executable (str) - 客户端路径或命令名
    ;   ?unsetEnv   (list[str]) - 需要从子进程环境中移除的变量名
    ;   ?timeout    (int|nil) - 默认等待秒数
    ;
    ; **返回**
    ;   (Client) - 未验证的客户端对象
    let((cmd)
        when(command && executable
            error("ycSQLite::Client: ?command and ?executable are mutually exclusive")
        )
        unless(executable == nil || stringp(executable)
            error("ycSQLite::Client: ?executable must be a string or nil, got %A"
                executable)
        )
        when(unsetEnv
            unless(listp(unsetEnv)
                error("ycSQLite::Client: ?unsetEnv must be a list of strings, got %A"
                    unsetEnv)
            )
            for(i 1 length(unsetEnv)
                unless(stringp(nth(i - 1 unsetEnv))
                    error("ycSQLite::Client: ?unsetEnv element %d must be a string"
                        i)
                )
            )
        )
        when(timeout
            unless(fixp(timeout) && timeout > 0
                error("ycSQLite::Client: ?timeout must be a positive integer or nil")
            )
        )
        cmd = if(command
        then
            _CheckCommandList(command)
        else
            list(if(executable executable "sqlite3"))
        )
        when(unsetEnv
            foreach(name unsetEnv
                cmd = cons("-u" cons(name cmd))
            )
            cmd = cons("env" cmd)
        )
        makeInstance('Client ?_data makeInstance('_ClientData
            ?command cmd
            ?timeout timeout
        ))
    )
)


procedure(DefaultClient()  ; -> Client
    ; 返回全局默认客户端；首次调用按显式配置、环境变量、wrapper 顺序解析。
    ;
    ; **返回**
    ;   (Client) - 默认客户端对象
    unless(_DefaultClient
        let((envName env)
            envName = "YC_SKILL_OO_SQLITE_CLIENT"
            env = getShellEnvVar(envName)
            _DefaultClient = if(env && env != ""
            then
                Client(?command list(env))
            else
                Client(?command list("sh" _WrapperPath))
            )
        )
    )
    _DefaultClient
)


procedure(Configure(\@key (client nil) (command nil) (executable nil) (unsetEnv nil) (timeout nil) "ggggg")  ; -> Client
    ; 设置全局默认客户端并立即验证。
    ;
    ; **参数**
    ;   ?client     (Client|nil) - 已构造客户端；优先于命令参数
    ;   ?command    (list[str]) - 完整基础命令
    ;   ?executable (str) - 客户端路径或命令名
    ;   ?unsetEnv   (list[str]) - 需要移除的环境变量名
    ;   ?timeout    (int|nil) - 默认等待秒数
    ;
    ; **返回**
    ;   (Client) - 已验证的客户端；失败时 error() 中断
    _DefaultClient = if(client
    then
        client
    else
        if(command || executable || unsetEnv || timeout
        then
            Client(
                ?command command
                ?executable executable
                ?unsetEnv unsetEnv
                ?timeout timeout
            )
        else
            DefaultClient()
        )
    )
    _DefaultClient->validate()
    unless(_DefaultClient->isValid()
        error("ycSQLite::Configure: client validation failed: %s"
            _DefaultClient->diagnostics())
    )
    _DefaultClient
)


procedure(ProbeClient(\@key (command nil) (executable nil) (unsetEnv nil) (timeout nil) "gggg")  ; -> Client
    ; 构造并验证客户端，但不修改全局默认配置。
    ;
    ; **参数**
    ;   ?command    (list[str]) - 完整基础命令
    ;   ?executable (str) - 客户端路径或命令名
    ;   ?unsetEnv   (list[str]) - 需要移除的环境变量名
    ;   ?timeout    (int|nil) - 默认等待秒数
    ;
    ; **返回**
    ;   (Client) - 验证结果；失败诊断在 diagnostics()
    let((client2)
        client2 = Client(
            ?command command
            ?executable executable
            ?unsetEnv unsetEnv
            ?timeout timeout
        )
        client2->validate()
        client2
    )
)


inScheme(
defmethod(initializeInstance (self(Client) \@rest _args)
    ; 构造 Client 实例时安装全部方法。
    ;
    ; **参数**
    ;   _args  (list) - 附加参数，本实现忽略
    ;
    ; **返回**
    ;   (t) - 安装完成
    _InstallClient(self)
    t
)
)

unuseNamespace("ycSQLite")

; END
