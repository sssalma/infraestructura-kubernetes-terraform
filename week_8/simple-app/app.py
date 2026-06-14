from flask import Flask

app = Flask(__name__)
visits = 0

@app.route("/")
def hello():
    return "Hello from container!\n"

@app.route("/health")
def health():
    return {"status": "ok"}, 200

@app.route("/visits")
def count():
    global visits
    visits += 1
    return f"Visitas: {visits}\n"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=3000)
