from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import List, Optional, Tuple

import matplotlib.pyplot as plt
import pandas as pd

from fda_pipeline import ensure_dirs, normalize_text


LIKELY_CONTROLLED_TOKENS = {
    # Opioids (high confidence)
    "MORPHINE",
    "CODEINE",
    "HYDROCODONE",
    "OXYCODONE",
    "HYDROMORPHONE",
    "OXYMORPHONE",
    "BUPRENORPHINE",
    "FENTANYL",
    "SUFENTANIL",
    "ALFENTANIL",
    "REMIFENTANIL",
    "METHADONE",
    "MEPERIDINE",
    "PETHIDINE",
    "TRAMADOL",
    "TAPENTADOL",
    "DIHYDROCODEINE",
    "LEVORPHANOL",
    "BUTORPHANOL",
    "PENTAZOCINE",
    "PROPOXYPHENE",
    # Stimulants (high confidence)
    "AMPHETAMINE",
    "DEXTROAMPHETAMINE",
    "METHAMPHETAMINE",
    "LISDEXAMFETAMINE",
    "METHYLPHENIDATE",
    "DEXMETHYLPHENIDATE",
    # Benzodiazepines (high confidence)
    "DIAZEPAM",
    "ALPRAZOLAM",
    "CLONAZEPAM",
    "LORAZEPAM",
    "MIDAZOLAM",
    "TEMAZEPAM",
    "OXAZEPAM",
    "TRIAZOLAM",
    "FLURAZEPAM",
    "CHLORDIAZEPOXIDE",
    "CLORAZEPATE",
    "ESTAZOLAM",
    "CLOBAZAM",
    # Barbiturates (high confidence)
    "PHENOBARBITAL",
    "SECOBARBITAL",
    "AMOBARBITAL",
    "PENTOBARBITAL",
    "BUTALBITAL",
    # Other controlled substances (high confidence)
    "KETAMINE",
    "COCAINE",
    "DRONABINOL",
    "NABILONE",
    "OXYBATE",
}

POSSIBLE_CONTROLLED_TOKENS = {
    # Sedative-hypnotics and other scheduled drugs (lower confidence without DEA validation)
    "ZOLPIDEM",
    "ZALEPLON",
    "ESZOPICLONE",
    "CARISOPRODOL",
    "PREGABALIN",
    "MODAFINIL",
    "ARMODAFINIL",
    "PHENTERMINE",
    "DIETHYLPROPION",
}

UNCLEAR_TOKENS = {
    # Cannabinoid terms and other ambiguous cases
    "CANNABIDIOL",
    "CANNABIS",
    "MARIJUANA",
    "HEMP",
    "TETRAHYDROCANNABINOL",
    "THC",
    "CBD",
    "GABAPENTIN",
}


@dataclass
class ScreeningResult:
    classification: str
    basis: str
    confidence: str
    notes: str


def _split_ingredients(active_ingredient: Optional[str]) -> List[str]:
    if active_ingredient is None or (isinstance(active_ingredient, float) and pd.isna(active_ingredient)):
        return []
    raw = str(active_ingredient)
    parts = [p.strip() for p in raw.split(";") if p.strip()]
    return parts


def _match_tokens(ingredient: str) -> Tuple[set, set, set]:
    normalized = normalize_text(ingredient)
    if not normalized:
        return set(), set(), set()
    tokens = set(normalized.split())
    return (
        tokens & LIKELY_CONTROLLED_TOKENS,
        tokens & POSSIBLE_CONTROLLED_TOKENS,
        tokens & UNCLEAR_TOKENS,
    )


def classify_ingredient_list(active_ingredient: Optional[str]) -> ScreeningResult:
    ingredients = _split_ingredients(active_ingredient)
    if not ingredients:
        return ScreeningResult(
            classification="unclear",
            basis="missing_active_ingredient",
            confidence="low",
            notes="Active ingredient missing or blank.",
        )

    likely_hits = set()
    possible_hits = set()
    unclear_hits = set()

    for ingredient in ingredients:
        likely, possible, unclear = _match_tokens(ingredient)
        likely_hits |= likely
        possible_hits |= possible
        unclear_hits |= unclear

    if likely_hits:
        return ScreeningResult(
            classification="likely_controlled_substance",
            basis="heuristic_token_match_likely",
            confidence="medium",
            notes=f"Matched tokens: {', '.join(sorted(likely_hits))}",
        )
    if possible_hits:
        return ScreeningResult(
            classification="possible_controlled_substance",
            basis="heuristic_token_match_possible",
            confidence="low",
            notes=f"Matched tokens: {', '.join(sorted(possible_hits))}",
        )
    if unclear_hits:
        return ScreeningResult(
            classification="unclear",
            basis="heuristic_token_match_unclear",
            confidence="low",
            notes=f"Matched tokens: {', '.join(sorted(unclear_hits))}",
        )

    return ScreeningResult(
        classification="unlikely_controlled_substance",
        basis="no_token_match",
        confidence="medium",
        notes="No controlled-substance tokens matched.",
    )


def add_screening_columns(df: pd.DataFrame) -> pd.DataFrame:
    results = df["active_ingredient"].apply(classify_ingredient_list)
    df = df.copy()
    df["controlled_substance_screen"] = results.apply(lambda r: r.classification)
    df["screening_basis"] = results.apply(lambda r: r.basis)
    df["screening_confidence"] = results.apply(lambda r: r.confidence)
    df["notes"] = results.apply(lambda r: r.notes)
    return df


def create_summary_tables(df: pd.DataFrame) -> dict[str, pd.DataFrame]:
    tables: dict[str, pd.DataFrame] = {}

    summary = (
        df.groupby("controlled_substance_screen")
        .size()
        .reset_index(name="count")
        .sort_values("count", ascending=False)
    )
    summary["share"] = (summary["count"] / summary["count"].sum()).round(4)
    tables["controlled_substance_support_summary"] = summary

    subset = df[df["controlled_substance_screen"].isin(
        ["likely_controlled_substance", "possible_controlled_substance"]
    )].copy()

    by_year = (
        subset.groupby(["approval_year", "controlled_substance_screen"], dropna=False)
        .size()
        .reset_index(name="count")
        .pivot(
            index="approval_year",
            columns="controlled_substance_screen",
            values="count",
        )
        .fillna(0)
        .reset_index()
        .sort_values("approval_year")
    )
    by_year["total_likely_possible"] = (
        by_year.get("likely_controlled_substance", 0)
        + by_year.get("possible_controlled_substance", 0)
    )
    tables["controlled_substance_by_year"] = by_year

    priority_summary = (
        subset.groupby("review_priority_group", dropna=False)
        .size()
        .reset_index(name="count")
        .sort_values("count", ascending=False)
    )
    tables["controlled_substance_priority_summary"] = priority_summary

    orphan_summary = (
        subset.groupby("orphan_designation", dropna=False)
        .size()
        .reset_index(name="count")
        .sort_values("count", ascending=False)
    )
    tables["controlled_substance_orphan_summary"] = orphan_summary

    appl_type_summary = (
        subset.groupby("appl_type", dropna=False)
        .size()
        .reset_index(name="count")
        .sort_values("count", ascending=False)
    )
    tables["controlled_substance_appl_type_summary"] = appl_type_summary

    ingredients = (
        subset["active_ingredient"]
        .dropna()
        .str.split(";")
        .explode()
        .str.strip()
    )
    top_ingredients = ingredients.value_counts().head(25).reset_index()
    top_ingredients.columns = ["active_ingredient", "approval_count"]
    tables["top_controlled_substance_candidates"] = top_ingredients

    return tables


def save_summary_tables(tables: dict[str, pd.DataFrame], tables_dir: Path) -> None:
    for name, df in tables.items():
        df.to_csv(tables_dir / f"{name}.csv", index=False)


def make_figures(df: pd.DataFrame, tables: dict[str, pd.DataFrame], figures_dir: Path) -> None:
    plt.style.use("default")

    summary = tables["controlled_substance_support_summary"]
    fig, ax = plt.subplots(figsize=(7, 4))
    ax.bar(summary["controlled_substance_screen"], summary["count"], color="#4C78A8")
    ax.set_title("Controlled-Substance Screening Breakdown")
    ax.set_xlabel("Screening category")
    ax.set_ylabel("Count")
    ax.tick_params(axis="x", rotation=20)
    fig.tight_layout()
    fig.savefig(figures_dir / "controlled_substance_screen_breakdown.png", dpi=150)
    plt.close(fig)

    by_year = tables["controlled_substance_by_year"]
    fig, ax = plt.subplots(figsize=(8, 4))
    ax.plot(
        by_year["approval_year"],
        by_year["total_likely_possible"],
        color="black",
        label="Likely + Possible",
    )
    ax.set_title("Likely/Possible Controlled-Substance Approvals by Year")
    ax.set_xlabel("Approval year")
    ax.set_ylabel("Count")
    ax.grid(True, alpha=0.3)
    ax.legend(frameon=False, fontsize=8)
    fig.tight_layout()
    fig.savefig(figures_dir / "controlled_substance_candidates_by_year.png", dpi=150)
    plt.close(fig)

    subset = df[df["controlled_substance_screen"].isin(
        ["likely_controlled_substance", "possible_controlled_substance"]
    )].copy()
    priority_by_year = (
        subset.dropna(subset=["approval_year"])
        .groupby(["approval_year", "review_priority_group"], dropna=False)
        .size()
        .reset_index(name="count")
        .pivot(index="approval_year", columns="review_priority_group", values="count")
        .fillna(0)
        .reset_index()
        .sort_values("approval_year")
    )

    fig, ax = plt.subplots(figsize=(8, 4))
    for col, color in [
        ("PRIORITY", "#1f77b4"),
        ("STANDARD", "#2ca02c"),
        ("OTHER/UNKNOWN", "#ff7f0e"),
        ("MISSING", "#7f7f7f"),
    ]:
        if col in priority_by_year:
            ax.plot(priority_by_year["approval_year"], priority_by_year[col], label=col, color=color)
    ax.set_title("Review Priority Within Likely/Possible Controlled Substances")
    ax.set_xlabel("Approval year")
    ax.set_ylabel("Count")
    ax.grid(True, alpha=0.3)
    ax.legend(frameon=False, fontsize=8)
    fig.tight_layout()
    fig.savefig(figures_dir / "controlled_substance_priority_by_year.png", dpi=150)
    plt.close(fig)


def run_support_audit(root: Path) -> dict[str, Path]:
    paths = ensure_dirs(root)
    backbone_path = paths.processed_dir / "fda_backbone.csv"
    if not backbone_path.exists():
        raise FileNotFoundError("Missing data/processed/fda_backbone.csv")

    backbone = pd.read_csv(backbone_path)

    screening_cols = [
        "appl_no",
        "appl_type",
        "submission_no",
        "approval_date",
        "approval_year",
        "review_priority_group",
        "priority_review",
        "orphan_designation",
        "sponsor_name",
        "drug_name",
        "active_ingredient",
        "active_ingredient_norm",
    ]
    screening_df = backbone[screening_cols].copy()
    screening_df = add_screening_columns(screening_df)

    screened_path = paths.intermediate_dir / "controlled_substance_screened_candidates.csv"
    screening_df.to_csv(screened_path, index=False)

    tables = create_summary_tables(screening_df)
    save_summary_tables(tables, paths.tables_dir)
    make_figures(screening_df, tables, paths.figures_dir)

    return {
        "screened_candidates": screened_path,
        "tables_dir": paths.tables_dir,
        "figures_dir": paths.figures_dir,
    }


if __name__ == "__main__":
    project_root = Path(__file__).resolve().parents[1]
    outputs = run_support_audit(project_root)
    print("Support audit outputs:")
    for key, value in outputs.items():
        print(f"- {key}: {value}")
