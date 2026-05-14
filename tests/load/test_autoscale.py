"""
Autoscale load test using Playwright's async HTTP request contexts.

Fires concurrent requests against the API for a configurable duration,
then prints a results summary. Designed to push CPU above the HPA threshold
(default 70%) so Kubernetes scales the deployment up.

Environment variables:
  APP_URL      Base URL of the app  (default: https://projectx.pbcv.dev)
  CONCURRENCY  Number of parallel workers  (default: 60)
  DURATION     Test duration in seconds     (default: 180)
"""

import asyncio
import os
import sys
import time
from collections import Counter

from playwright.async_api import async_playwright

APP_URL     = os.getenv("APP_URL", "https://projectx.pbcv.dev")
CONCURRENCY = int(os.getenv("CONCURRENCY", "60"))
DURATION    = int(os.getenv("DURATION", "180"))

ENDPOINTS = ["/", "/healthz", "/version"]


async def worker(
    context,
    worker_id: int,
    results: list,
    stop: asyncio.Event,
) -> None:
    idx = 0
    while not stop.is_set():
        endpoint = ENDPOINTS[idx % len(ENDPOINTS)]
        try:
            resp = await context.get(f"{APP_URL}{endpoint}")
            results.append(resp.status)
            await resp.dispose()
        except Exception:
            results.append(0)
        idx += 1
        # tiny yield so the event loop can breathe
        if idx % 10 == 0:
            await asyncio.sleep(0)


async def main() -> None:
    print(f"🎯  Target  : {APP_URL}")
    print(f"👷  Workers : {CONCURRENCY}")
    print(f"⏱️   Duration: {DURATION}s")
    print(f"📋  Endpoints: {', '.join(ENDPOINTS)}")
    print()

    results: list[int] = []
    stop = asyncio.Event()

    async with async_playwright() as p:
        contexts = [
            await p.request.new_context(
                base_url=APP_URL,
                extra_http_headers={"X-Load-Test": "playwright"},
            )
            for _ in range(CONCURRENCY)
        ]

        tasks = [
            asyncio.create_task(worker(ctx, i, results, stop))
            for i, ctx in enumerate(contexts)
        ]

        # Progress ticker every 30 s
        start = time.monotonic()
        while time.monotonic() - start < DURATION:
            elapsed = time.monotonic() - start
            remaining = DURATION - elapsed
            snapshot = len(results)
            rps = snapshot / elapsed if elapsed > 0 else 0
            ok = results.count(200) if results else 0
            rate = ok / snapshot * 100 if snapshot else 0
            print(
                f"  [{elapsed:>5.0f}s / {DURATION}s]  "
                f"reqs={snapshot}  rps={rps:.1f}  2xx={rate:.1f}%",
                flush=True,
            )
            await asyncio.sleep(min(30, remaining + 0.1))

        stop.set()
        await asyncio.gather(*tasks, return_exceptions=True)

        for ctx in contexts:
            await ctx.dispose()

    total    = len(results)
    counts   = Counter(results)
    ok       = counts.get(200, 0)
    errors   = total - ok
    elapsed  = time.monotonic() - start
    rps      = total / elapsed if elapsed > 0 else 0
    success  = ok / total * 100 if total else 0

    print()
    print("━" * 52)
    print("  Load test complete")
    print("━" * 52)
    print(f"  Total requests : {total:>8,}")
    print(f"  Successful (2xx): {ok:>7,}  ({success:.1f}%)")
    print(f"  Errors          : {errors:>7,}")
    print(f"  Avg RPS         : {rps:>7.1f}")
    print(f"  Duration        : {elapsed:>7.1f}s")
    print()
    print("  Status breakdown:")
    for code, n in sorted(counts.items()):
        label = "✅" if code == 200 else "❌"
        print(f"    {label} HTTP {code}: {n:,}")
    print("━" * 52)

    if success < 95.0:
        print(f"\n❌  Success rate {success:.1f}% is below 95% — failing.")
        sys.exit(1)

    print(f"\n✅  Success rate {success:.1f}% — load test passed.")


if __name__ == "__main__":
    asyncio.run(main())
