#!/usr/bin/env python3
"""
html-to-png.py - render a (self-contained) HTML file to a full-page PNG using
Chrome/Chromium in headless mode.

Why this exists: `chrome --headless --screenshot` only captures the viewport, so
tall pages get cut off. This script measures the full rendered page via the
DevTools protocol (Page.getLayoutMetrics) and captures it with
`captureBeyondViewport`, so the WHOLE page is in the PNG - nothing is cut off.
It also waits for Mermaid diagrams to finish rendering before capturing.

Requirements: python3 (stdlib only) and Google Chrome / Chromium.

Usage:
  python3 html-to-png.py --html docs/x.html --out docs/x.png [--width 1640]
                         [--scale 2] [--chrome /path/to/chrome] [--timeout 20]

Exit codes: 0 ok; 2 Chrome not found; 1 other failure.
"""
import argparse, base64, json, os, shutil, socket, struct, subprocess, sys, tempfile, threading, time, urllib.request
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer

CHROME_CANDIDATES = [
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    "/Applications/Chromium.app/Contents/MacOS/Chromium",
    "/Applications/Google Chrome Canary.app/Contents/MacOS/Google Chrome Canary",
    "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge",
]
PATH_NAMES = ["google-chrome", "google-chrome-stable", "chromium", "chromium-browser",
              "chrome", "microsoft-edge"]


def find_chrome(explicit):
    if explicit:
        if os.path.exists(explicit):
            return explicit
        sys.exit("error: --chrome path does not exist: %s" % explicit)
    for env in ("CHROME", "CHROME_PATH", "CHROME_BIN"):
        p = os.environ.get(env)
        if p and os.path.exists(p):
            return p
    for p in CHROME_CANDIDATES:
        if os.path.exists(p):
            return p
    for name in PATH_NAMES:
        p = shutil.which(name)
        if p:
            return p
    return None


# ---------- minimal WebSocket client (stdlib only) ----------
def _recvn(s, n):
    buf = b""
    while len(buf) < n:
        c = s.recv(n - len(buf))
        if not c:
            raise IOError("socket closed")
        buf += c
    return buf


def ws_connect(ws_url, timeout=40):
    rest = ws_url[len("ws://"):]
    hostport, _, path = rest.partition("/")
    path = "/" + path
    host, port = hostport.split(":")
    s = socket.create_connection((host, int(port)), timeout=timeout)
    key = base64.b64encode(os.urandom(16)).decode()
    s.sendall(("GET %s HTTP/1.1\r\nHost: %s:%s\r\nUpgrade: websocket\r\n"
               "Connection: Upgrade\r\nSec-WebSocket-Key: %s\r\n"
               "Sec-WebSocket-Version: 13\r\n\r\n" % (path, host, port, key)).encode())
    resp = b""
    while b"\r\n\r\n" not in resp:
        chunk = s.recv(4096)
        if not chunk:
            raise IOError("ws handshake: connection closed")
        resp += chunk
    if b" 101 " not in resp.split(b"\r\n", 1)[0]:
        raise IOError("ws handshake failed: %r" % resp[:120])
    s.settimeout(timeout)
    return s


def ws_send(s, obj):
    data = json.dumps(obj).encode("utf-8")
    hdr = bytearray([0x81])
    ln = len(data)
    mask = os.urandom(4)
    if ln < 126:
        hdr.append(0x80 | ln)
    elif ln < 65536:
        hdr.append(0x80 | 126); hdr += struct.pack(">H", ln)
    else:
        hdr.append(0x80 | 127); hdr += struct.pack(">Q", ln)
    hdr += mask
    s.sendall(bytes(hdr) + bytes(b ^ mask[i % 4] for i, b in enumerate(data)))


def ws_recv(s):
    msg = b""
    while True:
        b1 = _recvn(s, 1)[0]; fin = b1 & 0x80; op = b1 & 0x0F
        b2 = _recvn(s, 1)[0]; masked = b2 & 0x80; ln = b2 & 0x7F
        if ln == 126:
            ln = struct.unpack(">H", _recvn(s, 2))[0]
        elif ln == 127:
            ln = struct.unpack(">Q", _recvn(s, 8))[0]
        mask = _recvn(s, 4) if masked else None
        payload = _recvn(s, ln) if ln else b""
        if mask:
            payload = bytes(b ^ mask[i % 4] for i, b in enumerate(payload))
        if op == 0x8:  # close
            return None
        if op == 0x9:  # ping
            continue
        msg += payload
        if fin:
            break
    return json.loads(msg.decode("utf-8", "replace"))


class CDP:
    def __init__(self, s):
        self.s = s
        self._id = 0

    def call(self, method, params=None, timeout=40):
        self._id += 1
        mid = self._id
        ws_send(self.s, {"id": mid, "method": method, "params": params or {}})
        t0 = time.time()
        while time.time() - t0 < timeout:
            m = ws_recv(self.s)
            if m is None:
                raise IOError("devtools connection closed")
            if m.get("id") == mid:
                if "error" in m:
                    raise RuntimeError("%s: %s" % (method, json.dumps(m["error"])))
                return m.get("result", {})
        raise TimeoutError(method)


class _QuietHandler(SimpleHTTPRequestHandler):
    def log_message(self, *args, **kwargs):
        pass


def start_server(directory):
    handler = partial(_QuietHandler, directory=directory)
    httpd = ThreadingHTTPServer(("127.0.0.1", 0), handler)
    t = threading.Thread(target=httpd.serve_forever, daemon=True)
    t.start()
    return httpd, httpd.server_address[1]


def devtools_url(port, profile, timeout=30):
    # Prefer the DevToolsActivePort file (works with --remote-debugging-port=0).
    portfile = os.path.join(profile, "DevToolsActivePort")
    deadline = time.time() + timeout
    while time.time() < deadline:
        try:
            data = json.loads(urllib.request.urlopen("http://127.0.0.1:%d/json" % port, timeout=2).read())
            pages = [t for t in data if t.get("type") == "page" and t.get("webSocketDebuggerUrl")]
            if pages:
                return pages[0]["webSocketDebuggerUrl"]
        except Exception:
            pass
        # If port 0 was used, discover the real port from the profile file.
        if port == 0 and os.path.exists(portfile):
            try:
                with open(portfile) as f:
                    port = int(f.readline().strip())
            except Exception:
                pass
        time.sleep(0.3)
    raise RuntimeError("could not reach Chrome DevTools endpoint")


def render(chrome, url, out, width, scale, timeout):
    profile = tempfile.mkdtemp(prefix="acc-png-")
    rdp = 0  # ephemeral; real port read from DevToolsActivePort
    args = [chrome, "--headless=new", "--remote-debugging-port=%d" % rdp,
            "--user-data-dir=" + profile, "--no-first-run", "--no-default-browser-check",
            "--disable-gpu", "--no-proxy-server", "--hide-scrollbars", "--disable-extensions",
            "--disable-background-networking", "--disable-component-update",
            "--disable-renderer-backgrounding", "about:blank"]
    proc = subprocess.Popen(args, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    try:
        # find the assigned remote-debugging port from the profile file
        portfile = os.path.join(profile, "DevToolsActivePort")
        real_port = None
        deadline = time.time() + timeout
        while time.time() < deadline and real_port is None:
            if os.path.exists(portfile):
                try:
                    with open(portfile) as f:
                        real_port = int(f.readline().strip())
                except Exception:
                    real_port = None
            if real_port is None:
                time.sleep(0.2)
        if real_port is None:
            raise RuntimeError("Chrome did not expose a DevTools port")
        ws_url = devtools_url(real_port, profile, timeout=timeout)
        c = CDP(ws_connect(ws_url, timeout=max(40, timeout)))
        c.call("Page.enable")
        c.call("Runtime.enable")
        c.call("Emulation.setDeviceMetricsOverride",
               {"width": width, "height": 1200, "deviceScaleFactor": scale, "mobile": False})
        c.call("Page.navigate", {"url": url})

        # wait for document complete + all Mermaid diagrams rendered (or timeout)
        t0 = time.time()
        while time.time() - t0 < timeout:
            r = c.call("Runtime.evaluate", {"returnByValue": True, "expression":
                "JSON.stringify([document.querySelectorAll('pre.mermaid,.mermaid').length,"
                "document.querySelectorAll('pre.mermaid svg,.mermaid svg').length,"
                "document.readyState])"})
            try:
                total, rendered, ready = json.loads(r["result"]["value"])
            except Exception:
                total, rendered, ready = 0, 0, "loading"
            if ready == "complete" and (total == 0 or rendered >= total):
                break
            time.sleep(0.4)
        time.sleep(0.6)  # let layout settle after diagrams appear

        m = c.call("Page.getLayoutMetrics")
        css = m.get("cssContentSize") or m.get("contentSize")
        w = int(round(css["width"]))
        h = int(round(css["height"]))
        shot = c.call("Page.captureScreenshot", {
            "format": "png", "captureBeyondViewport": True,
            "clip": {"x": 0, "y": 0, "width": w, "height": h, "scale": 1}})
        with open(out, "wb") as f:
            f.write(base64.b64decode(shot["data"]))
        return w, h, w * scale, h * scale
    finally:
        proc.terminate()
        try:
            proc.wait(timeout=5)
        except Exception:
            proc.kill()
        shutil.rmtree(profile, ignore_errors=True)


def main():
    ap = argparse.ArgumentParser(description="Render an HTML file to a full-page PNG via headless Chrome.")
    ap.add_argument("--html", required=True, help="path to the input HTML file")
    ap.add_argument("--out", required=True, help="path to the output PNG file")
    ap.add_argument("--width", type=int, default=1640, help="CSS layout width in px (default 1640)")
    ap.add_argument("--scale", type=float, default=2.0, help="device scale factor for crispness (default 2)")
    ap.add_argument("--chrome", default=None, help="explicit path to the Chrome/Chromium binary")
    ap.add_argument("--timeout", type=float, default=20.0, help="max seconds to wait for load/diagrams")
    a = ap.parse_args()

    html_path = os.path.abspath(a.html)
    if not os.path.isfile(html_path):
        sys.exit("error: HTML file not found: %s" % html_path)
    out_path = os.path.abspath(a.out)
    os.makedirs(os.path.dirname(out_path) or ".", exist_ok=True)

    chrome = find_chrome(a.chrome)
    if not chrome:
        sys.stderr.write(
            "error: could not find Chrome/Chromium. Install Google Chrome or set "
            "CHROME=/path/to/chrome (or pass --chrome). Skipping PNG generation.\n")
        sys.exit(2)

    directory = os.path.dirname(html_path)
    httpd, port = start_server(directory)
    url = "http://127.0.0.1:%d/%s" % (port, os.path.basename(html_path))
    try:
        cw, ch, pw, ph = render(chrome, url, out_path, a.width, a.scale, a.timeout)
        print("Rendered full page %dx%d CSS px -> %s (%dx%d px @%gx)" % (cw, ch, out_path, pw, ph, a.scale))
    finally:
        httpd.shutdown()


if __name__ == "__main__":
    main()
