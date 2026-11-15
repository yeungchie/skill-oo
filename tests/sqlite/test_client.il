let((tmp wrapper envPath db info bad parse)
    tmp = "ycSQLiteTmpTest"
    system(strcat("rm -rf " tmp " && mkdir -p " tmp))
    wrapper = strcat(_TestDir "../../libs/sqlite/src/sqlite3.sh")
    envPath = strcat(tmp "/sqlite3-env")
    system(lsprintf("cp %s %s && chmod +x %s" wrapper envPath envPath))

    setShellEnvVar("YC_SKILL_OO_SQLITE_CLIENT" envPath)
    db = ycSQLite::Open(":memory:")
    _Assert(car(db->client()->command()) == envPath
        "client: YC_SKILL_OO_SQLITE_CLIENT selects the configured path")
    _Assert(db->client()->isValid()
        "client: environment-selected client validates")
    db->close()
    unsetShellEnvVar("YC_SKILL_OO_SQLITE_CLIENT")
    system(strcat("rm -f " envPath))

    _Assert(ycSQLite::Configure(?command list("sh" wrapper))->isValid()
        "client: Configure accepts the module wrapper")
    _Assert(ycSQLite::DefaultClient()->isValid()
        "client: DefaultClient is cached after Configure")
    _Assert(ycSQLite::DefaultClient()->supports('session)
        "client: wrapper reports persistent session capability")
    _Assert(ycSQLite::DefaultClient()->supports('memory)
        "client: wrapper reports memory database capability")

    info = ycSQLite::ProbeClient(
        ?executable "sqlite3"
        ?unsetEnv list("LD_LIBRARY_PATH")
    )
    _Assert(info->isValid()
        "client: explicit executable plus unsetEnv validates")
    _Assert(pcreMatchp("^3\\.[0-9]+\\.[0-9]+$" info->version())
        "client: version string is three numeric components")
    _Assert(length(info->versionTuple()) == 3
        "client: versionTuple has three elements")

    bad = ycSQLite::ProbeClient(?executable strcat(tmp "/missing-client"))
    _Assert(!bad->isValid()
        "client: missing executable is invalid")
    _Assert(!blankstrp(bad->diagnostics())
        "client: invalid client exposes diagnostics")

    _AssertError(lambda(() ycSQLite::Client(?command "sqlite3"))
        "client: command must be a list")
    _AssertError(lambda(() ycSQLite::Client(?command list("sqlite3" 1)))
        "client: command elements must be strings")
    _AssertError(lambda(() ycSQLite::Client(?timeout 0))
        "client: timeout must be positive")

    ; --- version parsing ---
    info = ycSQLite::_ParseVersion("3.45.1.1 2024-01-01" "probe")
    _Assert(car(info) == "3.45.1.1"
        "client: four-part version keeps the original string")
    _Assert(cadr(info) == list(3 45 1)
        "client: four-part version keeps the first three components")
    parse = ycSQLite::_ParseVersion("3.50.0-prelease" "probe")
    _Assert(cadr(parse) == list(3 50 0)
        "client: version suffix keeps the numeric components")
    _AssertErrorMsg(lambda(() ycSQLite::_ParseVersion("sqlite3" "probe"))
        "unsupported version output"
        "client: non-numeric version is rejected")

    system(strcat("rm -rf " tmp))
)

_TestChildDone = t

; END
