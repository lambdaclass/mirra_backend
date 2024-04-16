profiler = fn ->
:fprof.start()
:fprof.trace([:start, :verbose, procs: [Process.whereis(Arena.GameLauncher)]])
Process.sleep(10000)
:fprof.trace(:stop)
:fprof.profile()
:fprof.analyse(totals: false, dest: 'prof.analysis')
end


scp to local
erlgrind
qcachegrind
