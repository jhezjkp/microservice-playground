from flask import Flask
from redis import Redis
import os
import socket


app = Flask(__name__)
redis = Redis(host='redis', port=6379)
host = socket.gethostname()

@app.route('/')
def index():
    redis.incr('hits')
    return '\nhost:%s\nvisit count:%s\n\n' % (host, redis.get('hits'))

if __name__ == "__main__":
    app.run(host="0.0.0.0", debug=True)
