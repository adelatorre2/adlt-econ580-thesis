import os
import re
from typing import List, Optional

import pandas as pd
import requests
from bs4 import BeautifulSoup

BASE_URL = (
    "https://wiaa-dna4aga5arc0gyeb.westus2-01.azurewebsites.net/results/trackfield"
)
MEET_DIRS = ["2A3A4A", "1B2B1A"]

REQUIRED_EVENTS = {
    "100m",
    "200m",
    "800m",
    "1600m",
    "3200m",
    "4x100",
    "4x400",
    "Shot Put",
    "Discus",
    "Long Jump",
    "Triple Jump",
    "High Jump",
}

TRACK_EVENTS = {"100m", "200m", "800m", "1600m", "3200m", "4x100", "4x400"}
FIELD_EVENTS = REQUIRED_EVENTS - TRACK_EVENTS

EVENT_MAP = {
    "100 meter dash": "100m",
    "100 meters": "100m",
    "200 meter dash": "200m",
    "200 meters": "200m",
    "800 meter run": "800m",
    "800 meters": "800m",
    "1600 meter run": "1600m",
    "1,600 meter run": "1600m",
    "1600 meters": "1600m",
    "1,600 meters": "1600m",
    "3200 meter run": "3200m",
    "3,200 meter run": "3200m",
    "3200 meters": "3200m",
    "3,200 meters": "3200m",
    "4x100 meter relay": "4x100",
    "4 x 100 meter relay": "4x100",
    "4x400 meter relay": "4x400",
    "4 x 400 meter relay": "4x400",
    "shot put": "Shot Put",
    "discus": "Discus",
    "long jump": "Long Jump",
    "triple jump": "Triple Jump",
    "high jump": "High Jump",
}

TEST_YEAR = 2015


def season_code(year: int) -> str:
    start = (year - 1) % 100
    end = year % 100
    return f"{start:02d}-{end:02d}"


def download_results(year: int) -> List[str]:
    raw_dir = os.path.join("data", "raw")
    os.makedirs(raw_dir, exist_ok=True)

    season = season_code(year)
    raw_files = []

    for meet_dir in MEET_DIRS:
        base_url = f"{BASE_URL}/{season}/{meet_dir}/"
        index_url = base_url + "evtindex.htm"
        resp = requests.get(index_url, timeout=30)
        resp.raise_for_status()

        raw_path = os.path.join(raw_dir, f"wiaa_track_{year}_{meet_dir}_evtindex.htm")
        with open(raw_path, "w", encoding="utf-8") as f:
            f.write(resp.text)
        raw_files.append(raw_path)

    return raw_files


def standardize_event(event_name: str) -> Optional[str]:
    if not event_name:
        return None

    name = event_name.lower()
    if "hurdle" in name or "hurdles" in name:
        return None

    for key, canonical in EVENT_MAP.items():
        if key in name:
            return canonical

    return None


def infer_meet_dir(raw_file_path: str) -> str:
    filename = os.path.basename(raw_file_path)
    for meet_dir in MEET_DIRS:
        if meet_dir in filename:
            return meet_dir
    raise ValueError(f"Unable to infer meet directory from {raw_file_path}")


def extract_event_info(event_line: str) -> (str, Optional[str]):
    classification = None
    match = re.search(r"\b(1B|2B|1A|2A|3A|4A)\b", event_line)
    if match:
        classification = match.group(1)

    name = re.sub(r"^Event\s+\d+\s+", "", event_line).strip()
    if classification:
        name = re.sub(rf"\s+{re.escape(classification)}\s*$", "", name).strip()
    name = re.sub(r"\b(Girls|Boys|Women|Men|Mixed)\b", "", name, flags=re.I).strip()
    name = re.sub(r"\s+", " ", name)

    return name, classification


def parse_time_to_seconds(value: str) -> Optional[float]:
    value = value.strip()
    if not value:
        return None
    if re.search(r"[A-Za-z]", value):
        return None

    if ":" in value:
        parts = value.split(":")
        if len(parts) != 2:
            return None
        try:
            minutes = int(parts[0])
            seconds = float(parts[1])
            return minutes * 60 + seconds
        except ValueError:
            return None

    try:
        return float(value)
    except ValueError:
        return None


def parse_distance_to_inches(value: str) -> Optional[float]:
    value = value.strip()
    if not value:
        return None
    if re.search(r"[A-Za-z]", value):
        return None

    if "-" in value:
        try:
            feet, inches = value.split("-", 1)
            return int(feet) * 12 + float(inches)
        except ValueError:
            return None

    try:
        return float(value)
    except ValueError:
        return None


def parse_mark(value: str, event_type: str) -> Optional[float]:
    if event_type == "track":
        return parse_time_to_seconds(value)
    return parse_distance_to_inches(value)


def standardize_school(school_name: str) -> str:
    return re.sub(r"\s+", " ", school_name).strip()


def parse_result_line(line: str, event_type: str) -> Optional[dict]:
    if not line.strip():
        return None
    if not line.lstrip()[0].isdigit():
        return None

    parts = re.split(r"\s{2,}", line.strip())
    if len(parts) < 2:
        return None

    first_tokens = parts[0].split()
    if not first_tokens or not first_tokens[0].isdigit():
        return None

    place = int(first_tokens[0])
    if place > 50:
        return None
    name_or_school = " ".join(first_tokens[1:]).strip()

    school = None
    mark_str = None

    if len(parts) >= 3:
        second = parts[1].strip()
        second_tokens = second.split()
        if second_tokens and second_tokens[0].isdigit() and len(second_tokens) >= 2:
            school = " ".join(second_tokens[1:])
            mark_str = parts[2].strip()
        else:
            school = name_or_school
            mark_str = parts[1].strip()
    else:
        school = name_or_school
        mark_str = parts[1].strip()

    mark_val = parse_mark(mark_str, event_type)
    if mark_val is None:
        for candidate in parts[2:]:
            candidate = candidate.strip()
            if not candidate:
                continue
            mark_val = parse_mark(candidate, event_type)
            if mark_val is not None:
                mark_str = candidate
                break

    if mark_val is None:
        return None

    return {
        "school_name": standardize_school(school),
        "mark_numeric": mark_val,
        "place": place,
    }


def link_matches_required(text: str) -> bool:
    t = text.lower()
    if "latest" in t:
        return False
    if "prelim" in t or "prelims" in t or "preliminaries" in t or "heats" in t:
        return False
    if "hurdle" in t or "hurdles" in t:
        return False

    keywords = [
        "100 meter",
        "200 meter",
        "800 meter",
        "1600 meter",
        "1,600",
        "3200",
        "3,200",
        "4x100",
        "4x400",
        "shot put",
        "discus",
        "long jump",
        "triple jump",
        "high jump",
    ]
    return any(k in t for k in keywords)


def parse_event_page(html_text: str, year: int) -> List[dict]:
    soup = BeautifulSoup(html_text, "html.parser")
    pre = soup.find("pre")
    if not pre:
        return []

    lines = pre.get_text("\n").splitlines()
    event_line = None
    for line in lines:
        if line.strip().startswith("Event"):
            event_line = line.strip()
            break

    if not event_line:
        return []

    event_name_raw, classification = extract_event_info(event_line)
    event = standardize_event(event_name_raw)
    if event not in REQUIRED_EVENTS:
        return []

    event_type = "track" if event in TRACK_EVENTS else "field"

    rows = []
    for line in lines:
        result = parse_result_line(line, event_type)
        if not result:
            continue
        result.update(
            {
                "classification": classification,
                "year": year,
                "event": event,
                "is_track": event_type == "track",
            }
        )
        rows.append(result)

    return rows


def parse_results(raw_file_path: str, year: int) -> pd.DataFrame:
    meet_dir = infer_meet_dir(raw_file_path)
    base_url = f"{BASE_URL}/{season_code(year)}/{meet_dir}/"

    with open(raw_file_path, "r", encoding="utf-8") as f:
        index_html = f.read()

    soup = BeautifulSoup(index_html, "html.parser")
    links = [
        (a.get_text(" ", strip=True), a.get("href"))
        for a in soup.find_all("a")
        if a.get("href")
    ]

    session = requests.Session()
    rows = []

    for text, href in links:
        if not link_matches_required(text):
            continue

        url = base_url + href
        resp = session.get(url, timeout=30)
        resp.raise_for_status()
        rows.extend(parse_event_page(resp.text, year))

    return pd.DataFrame(rows)


def aggregate_results(parsed_df: pd.DataFrame) -> pd.DataFrame:
    if parsed_df.empty:
        return parsed_df

    df = parsed_df.dropna(subset=["mark_numeric"]).copy()

    group_cols = ["school_name", "classification", "year", "event"]

    def summarize(sub: pd.DataFrame, ascending: bool) -> pd.DataFrame:
        if sub.empty:
            return pd.DataFrame(columns=group_cols + ["n_qualifiers", "best_mark", "avg_top3_mark"])

        counts = sub.groupby(group_cols)["mark_numeric"].count().rename("n_qualifiers")
        if ascending:
            best = sub.groupby(group_cols)["mark_numeric"].min().rename("best_mark")
            avg_top3 = (
                sub.groupby(group_cols)["mark_numeric"]
                .apply(lambda s: s.nsmallest(3).mean() if len(s) >= 3 else None)
                .rename("avg_top3_mark")
            )
        else:
            best = sub.groupby(group_cols)["mark_numeric"].max().rename("best_mark")
            avg_top3 = (
                sub.groupby(group_cols)["mark_numeric"]
                .apply(lambda s: s.nlargest(3).mean() if len(s) >= 3 else None)
                .rename("avg_top3_mark")
            )

        return pd.concat([counts, best, avg_top3], axis=1).reset_index()

    track_df = df[df["is_track"]].copy()
    field_df = df[~df["is_track"]].copy()

    summary = pd.concat(
        [summarize(track_df, ascending=True), summarize(field_df, ascending=False)],
        ignore_index=True,
    )

    return summary


def run_pipeline(year: int) -> str:
    raw_files = download_results(year)
    parsed_frames = []
    for raw_file in raw_files:
        parsed_frames.append(parse_results(raw_file, year))

    parsed_df = pd.concat(parsed_frames, ignore_index=True) if parsed_frames else pd.DataFrame()
    aggregated = aggregate_results(parsed_df)

    clean_dir = os.path.join("data", "clean")
    os.makedirs(clean_dir, exist_ok=True)
    output_path = os.path.join(clean_dir, f"wa_state_track_panel_{year}.csv")

    aggregated.to_csv(output_path, index=False)

    if aggregated.empty:
        print("No rows parsed. Check source URLs and parsing logic.")
        return output_path

    print("Pipeline summary")
    print(f"Schools: {aggregated['school_name'].nunique()}")
    print(f"Events: {aggregated['event'].nunique()}")
    print(f"Rows: {len(aggregated)}")

    return output_path


if __name__ == "__main__":
    run_pipeline(TEST_YEAR)
