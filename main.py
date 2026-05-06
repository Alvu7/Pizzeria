#!/usr/bin/env python3
"""Main launcher for the web simulator.

Usage:
  python3 main.py
Then open: http://localhost:8000
"""

from http.server import ThreadingHTTPServer, SimpleHTTPRequestHandler

HOST = "0.0.0.0"
PORT = 8000


def main() -> None:
    server = ThreadingHTTPServer((HOST, PORT), SimpleHTTPRequestHandler)
    print(f"Simulador activo en http://localhost:{PORT}")
    print("Presiona Ctrl+C para detener.")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
