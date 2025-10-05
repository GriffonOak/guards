del "release\\guards_windows.exe"
rem @Todo: Figure out why -o:speed hangs lol
odin build . -subsystem:windows -out:release/guards_windows.exe -define:RELEASE=true