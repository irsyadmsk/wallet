"""Generate the owner-approved icon family locally; never build or publish."""
from pathlib import Path
import shutil
import subprocess

if __name__ == "__main__":
    wallet = Path(__file__).resolve().parents[1]
    source = wallet.parent / "irsyads" / "scripts" / "generate-service-icons.mjs"
    node = shutil.which("node")
    if not node or not source.is_file():
        raise SystemExit("Requires local Node.js and sibling irsyads icon source. No fallback to obsolete artwork.")
    subprocess.run([node, str(source), "--apply-wallet"], cwd=source.parent.parent, check=True)
