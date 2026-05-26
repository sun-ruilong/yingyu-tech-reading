"""Generate missing audio for 高频句式 examples. Run on your machine:
   python gen_pattern_audio.py
"""
import asyncio, os, edge_tts

VOICE = "en-US-AndrewNeural"
RATE = "-6%"
OUT_DIR = os.path.join(os.path.dirname(__file__), "_audio", "2026-05-14 Codex CLI 是什么")

ITEMS = [
    ("pattern-ex-01", "Codex C L I is a local coding agent from Open A I."),
    ("pattern-ex-02", "Supabase is a backend platform for developers."),
    ("pattern-ex-03", "Claude Code is a coding tool from Anthropic."),
    ("pattern-ex-04", "You use it in a terminal, where it can run commands."),
    ("pattern-ex-05", "You use it in a browser, where it can open web pages."),
    ("pattern-ex-06", "You use it in an editor, where it can read your code."),
    ("pattern-ex-07", "To get started, install the package."),
    ("pattern-ex-08", "To get started, create an account."),
    ("pattern-ex-09", "To get started, run the setup command."),
    ("pattern-ex-10", "New versions are released regularly, so read the changelog."),
    ("pattern-ex-11", "Updates are released regularly, so keep your tool current."),
]

async def gen(name, text):
    path = os.path.join(OUT_DIR, f"{name}.mp3")
    if os.path.exists(path):
        print(f"  skip {name}.mp3 (exists)")
        return
    c = edge_tts.Communicate(text, VOICE, rate=RATE)
    await c.save(path)
    print(f"  done {name}.mp3")

async def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    for name, text in ITEMS:
        await gen(name, text)
    print("All done!")

asyncio.run(main())
