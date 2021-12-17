# ava
GUI for [notmuch](https://notmuchmail.org/) built using Flutter. Only tested on Linux desktop.

# IPC

Runs a socket on port 55555. Example:

`echo "ROUTE" | nc 0.0.0.0 55555`

The available routes are:

- /thread/:threadid