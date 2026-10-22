let((t_tmp p_base)

t_tmp = "ycPathlibTmpTest"
system(strcat("rm -rf " t_tmp))

p_base = _p(t_tmp)
p_base->mkdir()

p_base->join("one.json")->writeText("{\"a\": 1, \"b\": [true, null]}")
p_base->join("one.jsonc")->writeText("{\n  // note\n  \"a\": 1,\n}")
p_base->join("two.jsonl")->writeText("{\"a\": 1}\n{\"a\": 2}\n")
p_base->join("deep.json")->writeText("[[[[1]]]]")
p_base->join("empty.json")->writeText("")
p_base->join("one.yaml")->writeText("a: 1\nb: [true, null]\n")
p_base->join("stream.yaml")->writeText("---\n1\n---\n2\n")
p_base->join("deep.yaml")->writeText("[[[[1]]]]")
p_base->join("empty.yaml")->writeText("")
p_base->join("one.csv")->writeText("name,qty\napple,3\n")
p_base->join("one.tsv")->writeText("a\tb\n")
p_base->join("empty.csv")->writeText("")
p_base->join("one.toml")->writeText("title = \"demo\"\n[server]\nhost = \"localhost\"\nports = [8000, 8001]\n")
p_base->join("deep.toml")->writeText("a = [[1]]\n")
p_base->join("empty.toml")->writeText("")
p_base->join("bad.toml")->writeText("a = \n")

; --- json: contract equals decode(readText()) ---
let((p_f)
    p_f = p_base->join("one.json")
    _assert(_sameJson(p_f->readJson() ycJson::decode(p_f->readText()) "json")
        "readJson: json equals decode(readText())")
)

; --- jsonc: ?format forwards ---
let((p_f)
    p_f = p_base->join("one.jsonc")
    _assert(_sameJson(p_f->readJson(?format "jsonc") ycJson::decode(p_f->readText() ?format "jsonc") "jsonc")
        "readJson: jsonc forwards ?format")
)

; --- jsonl: list result ---
let((p_f l_r)
    p_f = p_base->join("two.jsonl")
    l_r = p_f->readJson(?format "jsonl")
    _assert(listp(l_r) && length(l_r) == 2  "readJson: jsonl returns list")
    _assert(_sameJson(l_r ycJson::decode(p_f->readText() ?format "jsonl") "jsonl")
        "readJson: jsonl equals decode(readText())")
)

; --- ?maxDepth forwards ---
let((p_f)
    p_f = p_base->join("deep.json")
    _assert(_sameJson(p_f->readJson() ycJson::decode(p_f->readText()) "json")
        "readJson: nested json default depth")
    _assertError(lambda(() p_f->readJson(?maxDepth 1) t)  "readJson: ?maxDepth rejects too deep")
    _assert(_sameJson(p_f->readJson(?maxDepth 10) ycJson::decode(p_f->readText() ?maxDepth 10) "json")
        "readJson: custom ?maxDepth forwards")
)

; --- parse errors come from decode ---
_assertError(lambda(() p_base->join("empty.json")->readJson() t)  "readJson: empty file parse error")
_assertError(lambda(() p_base->join("one.json")->readJson(?format "xml") t)  "readJson: invalid ?format forwards to decode")

; --- file errors come from readText precheck ---
_assertError(lambda(() p_base->join("missing.json")->readJson() t)  "readJson: missing file errors")
_assertError(lambda(() p_base->readJson() t)  "readJson: directory errors")

; --- yaml: contract equals decode(readText()) ---
let((p_f)
    p_f = p_base->join("one.yaml")
    _assert(_sameYaml(p_f->readYaml() ycYaml::decode(p_f->readText()))
        "readYaml: yaml equals decode(readText())")
)
let((p_f l_r)
    p_f = p_base->join("stream.yaml")
    l_r = p_f->readYaml(?format "yaml-stream")
    _assert(listp(l_r) && length(l_r) == 2  "readYaml: stream returns list")
    _assert(_sameYaml(l_r ycYaml::decode(p_f->readText() ?format "yaml-stream"))
        "readYaml: stream equals decode(readText())")
)
let((p_f)
    p_f = p_base->join("deep.yaml")
    _assertError(lambda(() p_f->readYaml(?maxDepth 1) t)  "readYaml: ?maxDepth rejects too deep")
    _assert(_sameYaml(p_f->readYaml(?maxDepth 10) ycYaml::decode(p_f->readText() ?maxDepth 10))
        "readYaml: custom ?maxDepth forwards")
)
_assert(p_base->join("empty.yaml")->readYaml() == ycCodec::Null  "readYaml: empty file is null")
_assertError(lambda(() p_base->join("one.yaml")->readYaml(?format "xml") t)  "readYaml: invalid ?format forwards")
_assertError(lambda(() p_base->join("missing.yaml")->readYaml() t)  "readYaml: missing file errors")
_assertError(lambda(() p_base->readYaml() t)  "readYaml: directory errors")

; --- csv: returns Table and forwards options ---
let((p_f t_tab)
    p_f = p_base->join("one.csv")
    t_tab = p_f->readCsv(?header t)
    _assert(classOf(t_tab) == findClass('ycCsv::Table)  "readCsv: returns Table")
    _assert(t_tab->rowCount() == 1  "readCsv: row count")
    _assert(car(t_tab->header()) == "name"  "readCsv: header")
    _assert(t_tab->value(1 "qty") == "3"  "readCsv: value")
    _assertSameSeq(t_tab->row(1) list("apple" "3")  "readCsv: row equals decode")
)
let((p_f t_tab)
    p_f = p_base->join("one.tsv")
    t_tab = p_f->readCsv(?format "tsv")
    _assertSameSeq(t_tab->row(1) list("a" "b")  "readCsv: tsv format")
)
let((p_f)
    p_f = p_base->join("empty.csv")
    _assert(p_f->readCsv()->rowCount() == 0  "readCsv: empty file has no rows")
)
_assertError(lambda(() p_base->join("one.csv")->readCsv(?format "xml") t)  "readCsv: invalid ?format forwards")
_assertError(lambda(() p_base->join("missing.csv")->readCsv() t)  "readCsv: missing file errors")
_assertError(lambda(() p_base->readCsv() t)  "readCsv: directory errors")

; --- toml: root table and pass-through ---
let((p_f t_v)
    p_f = p_base->join("one.toml")
    t_v = p_f->readToml()
    _assert(t_v["title"] == "demo"  "readToml: string value")
    _assert(t_v["server"]["host"] == "localhost"  "readToml: nested table")
    _assertSameSeq(t_v["server"]["ports"] list(8000 8001)  "readToml: array value")
)
let((p_f t_v)
    p_f = p_base->join("deep.toml")
    _assertError(lambda(() p_f->readToml(?maxDepth 1) t)  "readToml: ?maxDepth rejects too deep")
    t_v = p_f->readToml(?maxDepth 10)
    _assert(length(t_v["a"]) == 1 && car(car(t_v["a"])) == 1  "readToml: custom ?maxDepth forwards")
)
let((p_f t_v)
    p_f = p_base->join("empty.toml")
    t_v = p_f->readToml()
    _assert(length(t_v) == 0  "readToml: empty file returns empty table")
)
_assertError(lambda(() p_base->join("bad.toml")->readToml() t)  "readToml: parse errors forward")
_assertError(lambda(() p_base->join("one.toml")->readToml(?maxDepth 0) t)  "readToml: invalid option forwards")
_assertError(lambda(() p_base->join("missing.toml")->readToml() t)  "readToml: missing file errors")
_assertError(lambda(() p_base->readToml() t)  "readToml: directory errors")

; --- cleanup ---
system(strcat("rm -rf " t_tmp))
_assert(!p_base->exists()  "fixture: cleanup")

)  ; end let

_TestCodecDone = t

; END
