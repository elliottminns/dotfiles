"""Run an explicit command through the VM's host-root-only QEMU agent socket."""

import base64
import json
import socket
import sys
import time

if len(sys.argv) < 2:
    sys.exit("Usage: zenbox-builder-exec /absolute/guest/command [arguments...]")

with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as connection:
    connection.settimeout(15)
    connection.connect("/run/zenbox-builder/agent.sock")
    stream = connection.makefile("rwb", buffering=0)

    def request(command, arguments=None):
        message = {"execute": command}
        if arguments is not None:
            message["arguments"] = arguments
        stream.write(json.dumps(message).encode() + b"\n")
        response = json.loads(stream.readline())
        if "error" in response:
            raise RuntimeError(response["error"])
        return response["return"]

    process = request("guest-exec", {
        "path": sys.argv[1], "arg": sys.argv[2:], "capture-output": True,
    })
    deadline = time.monotonic() + 120
    while time.monotonic() < deadline:
        result = request("guest-exec-status", {"pid": process["pid"]})
        if result.get("exited"):
            for name, output in (("out-data", sys.stdout), ("err-data", sys.stderr)):
                if name in result:
                    output.buffer.write(base64.b64decode(result[name]))
            sys.exit(result.get("exitcode", 1))
        time.sleep(0.5)
    sys.exit("Guest command timed out; it may still be running inside the VM.")
