#!/usr/bin/env python3
"""
fetch_episodes.py - 通过 season_id 获取番剧集数列表（含 cid）
用法: python3 fetch_episodes.py --season-id 41410
输出: JSON array of episode objects to stdout
"""

import argparse
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from bili_cookie import get_session

SEASON_API = "https://api.bilibili.com/pgc/view/web/season"


def clean_html(text: str) -> str:
    """清理 HTML 标签残留"""
    return re.sub(r"<[^>]+>", "", text)


def fetch_episodes(season_id: int) -> list[dict]:
    session = get_session()
    resp = session.get(SEASON_API, params={"season_id": season_id}, timeout=10)
    resp.raise_for_status()
    data = resp.json()

    if data.get("code") != 0:
        raise RuntimeError(f"API error: {data.get('message', 'unknown')}")

    episodes = []
    for ep in data.get("result", {}).get("episodes", []):
        episodes.append({
            "ep_id": ep.get("ep_id", ep.get("id", 0)),
            "cid": ep.get("cid", 0),
            "aid": ep.get("aid", 0),
            "title": clean_html(str(ep.get("title", ""))),
            "longTitle": clean_html(ep.get("long_title", "")),
            "badge": "",    # 不传 badge
            "coverURL": ep.get("cover", ""),
        })

    return episodes


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--season-id", type=int, required=True)
    args = parser.parse_args()

    try:
        episodes = fetch_episodes(args.season_id)
        json.dump(episodes, sys.stdout, ensure_ascii=False)
    except Exception as e:
        print(json.dumps({"error": str(e)}), file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
