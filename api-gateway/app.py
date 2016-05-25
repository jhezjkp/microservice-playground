#!/usr/bin/env python

import time
import socket
from flask import Flask, request, jsonify

app = Flask(__name__)

@app.route("/")
def index():
    return "Hello World!"

@app.route("/echo", methods=['GET', 'POST'])
def echo():
    s = request.values.get("param", "nothing")
    return "echo:" + s + "\n"

@app.route("/info")
def info():
    hostname = socket.gethostname()
    ip = socket.gethostbyname(hostname)
    t = int(time.time())
    return jsonify(hostname=hostname, ip=ip, time=t)

if __name__ == "__main__":
    app.run("0.0.0.0", debug=True)
