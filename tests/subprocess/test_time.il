_assert(ycSubProcess::createJob("sleep 0")->start()->wait()->elapsed->getSeconds() <= 1 "elapsed seconds at most 1 for sleep 0")
_assert(ycSubProcess::createJob("sleep 1")->start()->wait()->elapsed->getSeconds() <= 2 "elapsed seconds at most 2 for sleep 1")

_TestTimeDone = t

; END
