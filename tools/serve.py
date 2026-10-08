"""Serve unmodified game assets and the Emscripten build on loopback."""

import mimetypes
import os
import re
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import unquote, urlsplit


def serve(build: Path, game: Path, port: int) -> None:
    build = build.resolve()
    game = game.resolve()
    if not (build / "srhd-fpc.wasm").is_file():
        raise FileNotFoundError(
            "Build the browser target with ./tools/build.py --target=wasm first."
        )
    # This is an index, not an extracted/repacked copy of any game resource.
    # The workspace's DATA directory may link to the original asset install.
    # Follow those links without copying packages, and stop directory cycles.
    assets, visited = {}, set()
    for directory, children, files in os.walk(game, followlinks=True):
        current = Path(directory)
        resolved = current.resolve()
        if resolved in visited:
            children.clear()
            continue
        visited.add(resolved)
        children[:] = [name for name in children if not name.startswith(".")]
        for name in files:
            path = current / name
            if not name.startswith(".") and path.is_file():
                assets[path.relative_to(game).as_posix()] = path
    manifest = ("\n".join(sorted(assets)) + "\n").encode()

    class Handler(BaseHTTPRequestHandler):
        protocol_version = "HTTP/1.1"

        def do_HEAD(self):
            self.respond(False)

        def do_GET(self):
            self.respond(True)

        def respond(self, body):
            # FetchFS may join its base and root-relative path with two slashes.
            path = re.sub("/+", "/", unquote(urlsplit(self.path).path))
            data = None
            source = None
            if path == "/assets/manifest.txt":
                data = manifest
            elif path.startswith("/assets/"):
                source = assets.get(path[len("/assets/") :])
            elif path in ("/", "/index.html", "/srhd-fpc.js", "/srhd-fpc.wasm"):
                source = build / ("index.html" if path == "/" else path[1:])
            if data is None and (source is None or not source.is_file()):
                self.send_error(404)
                return
            size = len(data) if data is not None else source.stat().st_size
            begin, end, code = 0, size - 1, 200
            # HEAD describes the whole object, as FetchFS expects. GET supports
            # one inclusive range and rejects malformed or unsatisfiable ranges.
            request_range = self.headers.get("Range") if body else None
            if request_range:
                match = re.fullmatch(r"bytes=(\d+)-(\d*)", request_range)
                if match:
                    begin = int(match[1])
                    end = min(int(match[2]), end) if match[2] else end
                if not match or begin > end:
                    self.send_response(416)
                    self.send_header("Content-Range", f"bytes */{size}")
                    self.send_header("Content-Length", "0")
                    self.end_headers()
                    return
                code = 206
            length = max(0, end - begin + 1)
            self.send_response(code)
            self.send_header("Cross-Origin-Opener-Policy", "same-origin")
            self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
            self.send_header("Cross-Origin-Resource-Policy", "same-origin")
            self.send_header("Accept-Ranges", "bytes")
            self.send_header("Content-Length", str(length))
            self.send_header(
                "Content-Type",
                mimetypes.guess_type(path)[0]
                or ("text/html" if path == "/" else "application/octet-stream"),
            )
            self.send_header("Cache-Control", "no-cache")
            if code == 206:
                self.send_header("Content-Range", f"bytes {begin}-{end}/{size}")
            self.end_headers()
            if not body:
                return
            try:
                if data is not None:
                    self.wfile.write(data[begin : end + 1])
                else:
                    with source.open("rb") as stream:
                        stream.seek(begin)
                        while length:
                            chunk = stream.read(min(length, 256 * 1024))
                            if not chunk:
                                break
                            self.wfile.write(chunk)
                            length -= len(chunk)
            except (BrokenPipeError, ConnectionResetError):
                pass

    server = ThreadingHTTPServer(("127.0.0.1", port), Handler)
    print(
        f"Space Rangers: http://127.0.0.1:{server.server_port}/ ({len(assets)} original files)",
        flush=True,
    )
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
