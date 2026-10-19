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

; --- cleanup ---
system(strcat("rm -rf " t_tmp))
_assert(!p_base->exists()  "fixture: cleanup")

)  ; end let

_TestCodecDone = t

; END
