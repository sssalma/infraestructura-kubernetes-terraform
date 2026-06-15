import os
from flask import Flask
import redis

app = Flask(__name__)

# Connexió a Redis (host configurable per variable d'entorn)
redis_host = os.environ.get("REDIS_HOST", "redis")
redis_port = int(os.environ.get("REDIS_PORT", 6379))
r = redis.Redis(host=redis_host, port=redis_port, decode_responses=True)

@app.route("/")
def hello():
    return "Hello from container!\n"

@app.route("/health")
def health():
    return {"status": "ok"}, 200

@app.route("/visits")
def count():
    try:
        visits = r.incr("visits")
    except redis.exceptions.RedisError:
        return "Visitas: (redis no disponible)\n", 200
    return f"Visitas: {visits}\n"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=3000)