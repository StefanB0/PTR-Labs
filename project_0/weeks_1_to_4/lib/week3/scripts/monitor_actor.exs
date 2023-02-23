pid = Week3.MonitorActor.run()
send(pid, {:spawn, self()})
:timer.sleep(100)

pid2 = Week3.MonitorActor.shortlisten()
send(pid2, {:crash})
