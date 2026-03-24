#!/usr/bin/env python3
"""
search.py - 搜索B站番剧
用法: python3 search.py --keyword "间谍过家家"
      python3 search.py --keyword "41410"        (season_id 直接查)
      python3 search.py --keyword "ss41410"       (ss号)
      python3 search.py --keyword "ep785726"      (ep号)
      python3 search.py --keyword "md28233"       (md号)
输出: JSON array to stdout
"""

import argparse
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from bili_cookie import get_session

SEARCH_API = "https://api.bilibili.com/x/web-interface/search/type"
SEASON_API = "https://api.bilibili.com/pgc/view/web/season"


def search_bangumi(keyword: str) -> list[dict]:
    keyword = keyword.strip()

    # 纯数字 → season_id 直接查
    if keyword.isdigit():
        r = _fetch_season(int(keyword))
        return [r] if r else []

    # ss/ep/md 前缀
    m = re.match(r'^ss(\d+)$', keyword, re.IGNORECASE)
    if m:
        r = _fetch_season(int(m.group(1)))
        return [r] if r else []

    m = re.match(r'^ep(\d+)$', keyword, re.IGNORECASE)
    if m:
        r = _fetch_season_by_ep(int(m.group(1)))
        return [r] if r else []

    m = re.match(r'^md(\d+)$', keyword, re.IGNORECASE)
    if m:
        r = _fetch_season_by_md(int(m.group(1)))
        return [r] if r else []

    # 关键词 → 番剧搜索 API
    return _search_by_keyword(keyword)


def _search_by_keyword(keyword: str) -> list[dict]:
    session = get_session()
    resp = session.get(
        SEARCH_API,
        params={"search_type": "media_bangumi", "keyword": keyword},
        timeout=10,
    )
    resp.raise_for_status()
    data = resp.json()

    if data.get("code") != 0:
        return []

    raw = data.get("data", {}).get("result") or []
    results = []
    for item in raw:
        # 直接解析搜索结果，不再逐个调 season 详情 API
        areas = item.get("areas", "")
        if isinstance(areas, list):
            areas = ", ".join(str(a) for a in areas)

        styles = item.get("styles", "")
        if isinstance(styles, list):
            styles = " ".join(str(s) for s in styles)

        score = 0.0
        try:
            score = float(item.get("media_score", {}).get("score", 0))
        except (TypeError, ValueError):
            pass

        results.append({
            "media_id": item.get("media_id", 0),
            "season_id": item.get("season_id", 0),
            "title": _clean_html(item.get("title", "")),
            "coverURL": item.get("cover", ""),
            "areas": areas,
            "styles": styles,
            "evaluate": item.get("desc", ""),
            "totalEpisodes": item.get("ep_size", 0),
            "score": score,
        })
    return results


def _fetch_season(season_id: int) -> dict | None:
    session = get_session()
    resp = session.get(SEASON_API, params={"season_id": season_id}, timeout=10)
    resp.raise_for_status()
    data = resp.json()
    if data.get("code") != 0:
        return None
    return _format_season(data.get("result", {}))


def _fetch_season_by_ep(ep_id: int) -> dict | None:
    session = get_session()
    resp = session.get(SEASON_API, params={"ep_id": ep_id}, timeout=10)
    resp.raise_for_status()
    data = resp.json()
    if data.get("code") != 0:
        return None
    return _format_season(data.get("result", {}))


def _fetch_season_by_md(media_id: int) -> dict | None:
    session = get_session()
    resp = session.get(
        "https://api.bilibili.com/pgc/review/user",
        params={"media_id": media_id},
        timeout=10,
    )
    resp.raise_for_status()
    data = resp.json()
    if data.get("code") != 0:
        return None
    sid = data.get("result", {}).get("media", {}).get("season_id")
    return _fetch_season(sid) if sid else None


def _format_season(result: dict) -> dict:
    areas = result.get("areas", [])
    if isinstance(areas, list):
        areas = ", ".join(a.get("name", "") if isinstance(a, dict) else str(a) for a in areas)

    styles = result.get("styles", [])
    if isinstance(styles, list):
        styles = " ".join(s.get("name", "") if isinstance(s, dict) else str(s) for s in styles)

    rating = result.get("rating", {})
    score = rating.get("score", 0) if isinstance(rating, dict) else 0

    return {
        "media_id": result.get("media_id", 0),
        "season_id": result.get("season_id", 0),
        "title": _clean_html(result.get("title", "")),
        "coverURL": result.get("cover", ""),
        "areas": areas,
        "styles": styles,
        "evaluate": result.get("evaluate", ""),
        "totalEpisodes": len(result.get("episodes", [])),
        "score": float(score),
    }


def _clean_html(text: str) -> str:
    return re.sub(r"<[^>]+>", "", text)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--keyword", required=True)
    args = parser.parse_args()
    try:
        results = search_bangumi(args.keyword)
        json.dump(results, sys.stdout, ensure_ascii=False)
    except Exception as e:
        print(json.dumps({"error": str(e)}), file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
