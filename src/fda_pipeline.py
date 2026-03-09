from __future__ import annotations

import re
import zipfile
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, Optional

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import requests

FDA_DATA_PAGE_URL = (
    "https://www.fda.gov/drugs/drug-approvals-and-databases/drugsfda-data-files"
)
FDA_ZIP_URL = "https://www.fda.gov/media/89850/download?attachment"
DEFAULT_USER_AGENT = "Mozilla/5.0 (compatible; econ580-thesis/0.1; +https://openai.com)"


@dataclass
class PipelinePaths:
    root: Path
    raw_dir: Path
    intermediate_dir: Path
    processed_dir: Path
    figures_dir: Path
    tables_dir: Path
    logs_dir: Path


def ensure_dirs(root: Path) -> PipelinePaths:
    raw_dir = root / "data" / "raw"
    intermediate_dir = root / "data" / "intermediate"
    processed_dir = root / "data" / "processed"
    figures_dir = root / "output" / "figures"
    tables_dir = root / "output" / "tables"
    logs_dir = root / "logs"

    for d in [
        raw_dir,
        intermediate_dir,
        processed_dir,
        figures_dir,
        tables_dir,
        logs_dir,
    ]:
        d.mkdir(parents=True, exist_ok=True)

    return PipelinePaths(
        root=root,
        raw_dir=raw_dir,
        intermediate_dir=intermediate_dir,
        processed_dir=processed_dir,
        figures_dir=figures_dir,
        tables_dir=tables_dir,
        logs_dir=logs_dir,
    )


def download_fda_zip(
    dest_path: Path,
    user_agent: str = DEFAULT_USER_AGENT,
    force: bool = False,
    log_path: Optional[Path] = None,
) -> Optional[Path]:
    if dest_path.exists() and not force:
        return dest_path

    headers = {"User-Agent": user_agent}
    try:
        response = requests.get(FDA_ZIP_URL, headers=headers, timeout=60)
        response.raise_for_status()
        dest_path.write_bytes(response.content)
        return dest_path
    except Exception as exc:  # pragma: no cover - best effort logging
        if log_path is not None:
            log_path.write_text(
                f"FDA zip download failed from {FDA_ZIP_URL}\nError: {exc}\n"
            )
        return None


def read_fda_table(zip_path: Path, filename: str) -> pd.DataFrame:
    with zipfile.ZipFile(zip_path, "r") as zf:
        with zf.open(filename) as f:
            return pd.read_csv(f, sep="\t", dtype=str, encoding="latin-1")


def _clean_series(series: pd.Series) -> pd.Series:
    return series.astype(str).str.strip().replace({"nan": pd.NA, "None": pd.NA})


def _agg_unique(values: Iterable[str]) -> Optional[str]:
    cleaned = sorted({str(v).strip() for v in values if pd.notna(v) and str(v).strip()})
    return "; ".join(cleaned) if cleaned else None


def normalize_text(value: Optional[str]) -> Optional[str]:
    if value is None or (isinstance(value, float) and np.isnan(value)):
        return None
    text = str(value).upper()
    text = re.sub(r"[^A-Z0-9]+", " ", text)
    return re.sub(r"\s+", " ", text).strip() or None


def build_backbone(
    applications: pd.DataFrame,
    submissions: pd.DataFrame,
    products: pd.DataFrame,
    submission_class_lookup: pd.DataFrame,
    submission_properties: pd.DataFrame,
) -> pd.DataFrame:
    apps = applications.rename(
        columns={
            "ApplNo": "appl_no",
            "ApplType": "appl_type",
            "ApplPublicNotes": "appl_public_notes",
            "SponsorName": "sponsor_name",
        }
    ).copy()
    subs = submissions.rename(
        columns={
            "ApplNo": "appl_no",
            "SubmissionClassCodeID": "submission_class_code_id",
            "SubmissionType": "submission_type",
            "SubmissionNo": "submission_no",
            "SubmissionStatus": "submission_status",
            "SubmissionStatusDate": "submission_status_date",
            "SubmissionsPublicNotes": "submissions_public_notes",
            "ReviewPriority": "review_priority",
        }
    ).copy()
    prods = products.rename(
        columns={
            "ApplNo": "appl_no",
            "ProductNo": "product_no",
            "Form": "dosage_form",
            "Strength": "strength",
            "ReferenceDrug": "reference_drug",
            "DrugName": "drug_name",
            "ActiveIngredient": "active_ingredient",
            "ReferenceStandard": "reference_standard",
        }
    ).copy()
    subcls = submission_class_lookup.rename(
        columns={
            "SubmissionClassCodeID": "submission_class_code_id",
            "SubmissionClassCode": "submission_class_code",
            "SubmissionClassCodeDescription": "submission_class_desc",
        }
    ).copy()
    props = submission_properties.rename(
        columns={
            "ApplNo": "appl_no",
            "SubmissionType": "submission_type",
            "SubmissionNo": "submission_no",
            "SubmissionPropertyTypeCode": "submission_property_type_code",
            "SubmissionPropertyTypeID": "submission_property_type_id",
        }
    ).copy()

    for col in ["appl_no", "appl_type", "sponsor_name"]:
        if col in apps:
            apps[col] = _clean_series(apps[col])

    for col in [
        "appl_no",
        "submission_class_code_id",
        "submission_type",
        "submission_no",
        "submission_status",
        "submission_status_date",
        "review_priority",
    ]:
        if col in subs:
            subs[col] = _clean_series(subs[col])

    for col in ["appl_no", "drug_name", "active_ingredient", "dosage_form", "strength"]:
        if col in prods:
            prods[col] = _clean_series(prods[col])

    for col in ["submission_class_code_id", "submission_class_code", "submission_class_desc"]:
        if col in subcls:
            subcls[col] = _clean_series(subcls[col])

    for col in ["appl_no", "submission_type", "submission_no", "submission_property_type_code"]:
        if col in props:
            props[col] = _clean_series(props[col])

    products_agg = (
        prods.groupby("appl_no", dropna=False)
        .agg(
            drug_name=("drug_name", _agg_unique),
            active_ingredient=("active_ingredient", _agg_unique),
            dosage_form=("dosage_form", _agg_unique),
            strength=("strength", _agg_unique),
        )
        .reset_index()
    )

    orphan = props[props["submission_property_type_code"].eq("Orphan")].copy()
    orphan = orphan[["appl_no", "submission_type", "submission_no"]].drop_duplicates()
    orphan["orphan_designation"] = True

    orig = subs[subs["submission_type"].eq("ORIG")].copy()

    orig = orig.merge(apps[["appl_no", "appl_type", "sponsor_name"]], on="appl_no", how="left")
    orig = orig.merge(
        subcls[["submission_class_code_id", "submission_class_code", "submission_class_desc"]],
        on="submission_class_code_id",
        how="left",
    )
    orig = orig.merge(products_agg, on="appl_no", how="left")
    orig = orig.merge(orphan, on=["appl_no", "submission_type", "submission_no"], how="left")

    orig["orphan_designation"] = orig["orphan_designation"].fillna(False)
    orig["approval_date"] = pd.to_datetime(orig["submission_status_date"], errors="coerce")
    orig["approval_year"] = orig["approval_date"].dt.year
    orig["is_tentative_approval"] = orig["submission_status"].eq("TA")

    priority_clean = orig["review_priority"].fillna("").str.strip().str.upper()
    orig["review_priority_clean"] = priority_clean.replace({"": pd.NA})
    orig["priority_review"] = priority_clean.eq("PRIORITY")
    orig["review_priority_group"] = np.select(
        [priority_clean.eq("PRIORITY"), priority_clean.eq("STANDARD"), priority_clean.eq("")],
        ["PRIORITY", "STANDARD", "MISSING"],
        default="OTHER/UNKNOWN",
    )

    orig["submission_date"] = pd.NaT
    orig["review_duration_days"] = pd.NA
    orig["review_duration_months"] = pd.NA

    orig["active_ingredient_norm"] = orig["active_ingredient"].map(normalize_text)
    orig["drug_name_norm"] = orig["drug_name"].map(normalize_text)

    columns = [
        "appl_no",
        "appl_type",
        "submission_type",
        "submission_no",
        "submission_class_code",
        "submission_class_desc",
        "submission_status",
        "approval_date",
        "approval_year",
        "submission_date",
        "review_duration_days",
        "review_duration_months",
        "review_priority_clean",
        "review_priority_group",
        "priority_review",
        "orphan_designation",
        "is_tentative_approval",
        "sponsor_name",
        "drug_name",
        "active_ingredient",
        "dosage_form",
        "strength",
        "drug_name_norm",
        "active_ingredient_norm",
    ]

    backbone = orig[columns].copy()
    return backbone


def build_data_dictionary() -> pd.DataFrame:
    entries = [
        ("appl_no", "FDA application number (string; preserves leading zeros).", "Applications.txt"),
        ("appl_type", "Application type (NDA, ANDA, BLA, etc.).", "Applications.txt"),
        ("submission_type", "Submission type; ORIG indicates original submission.", "Submissions.txt"),
        ("submission_no", "Submission number within application.", "Submissions.txt"),
        ("submission_class_code", "Submission class code (e.g., type codes).", "SubmissionClass_Lookup.txt"),
        ("submission_class_desc", "Submission class description.", "SubmissionClass_Lookup.txt"),
        ("submission_status", "Submission status (AP=approved, TA=tentative approval).", "Submissions.txt"),
        ("approval_date", "FDA approval (or tentative approval) date.", "Submissions.txt"),
        ("approval_year", "Calendar year of approval_date.", "Derived"),
        (
            "submission_date",
            "Not available in Drugs@FDA data files; placeholder for future merge.",
            "Not available",
        ),
        (
            "review_duration_days",
            "Not available without submission date; placeholder for future merge.",
            "Derived (requires submission_date)",
        ),
        (
            "review_duration_months",
            "Not available without submission date; placeholder for future merge.",
            "Derived (requires submission_date)",
        ),
        ("review_priority_clean", "Raw FDA review priority field.", "Submissions.txt"),
        (
            "review_priority_group",
            "Priority grouping: PRIORITY, STANDARD, OTHER/UNKNOWN, MISSING.",
            "Derived",
        ),
        ("priority_review", "Binary flag for PRIORITY review.", "Derived from review_priority"),
        ("orphan_designation", "Orphan designation flag (only if present).", "SubmissionPropertyType.txt"),
        ("is_tentative_approval", "True if submission_status == TA.", "Derived"),
        ("sponsor_name", "Sponsor/manufacturer name.", "Applications.txt"),
        ("drug_name", "Aggregated drug name(s) by application.", "Products.txt"),
        ("active_ingredient", "Aggregated active ingredient(s) by application.", "Products.txt"),
        ("dosage_form", "Aggregated dosage form(s) by application.", "Products.txt"),
        ("strength", "Aggregated strength(s) by application.", "Products.txt"),
        ("drug_name_norm", "Normalized drug name for merge scaffolding.", "Derived"),
        ("active_ingredient_norm", "Normalized active ingredient for merge scaffolding.", "Derived"),
    ]
    return pd.DataFrame(entries, columns=["variable", "description", "source"])


def create_summary_tables(backbone: pd.DataFrame) -> dict[str, pd.DataFrame]:
    tables: dict[str, pd.DataFrame] = {}

    approvals_by_year = (
        backbone.dropna(subset=["approval_year"])
        .groupby("approval_year", dropna=False)
        .size()
        .reset_index(name="approval_count")
        .sort_values("approval_year")
    )
    tables["approvals_by_year"] = approvals_by_year

    priority_by_year = (
        backbone.dropna(subset=["approval_year"])
        .groupby(["approval_year", "review_priority_group"], dropna=False)
        .size()
        .reset_index(name="count")
        .pivot(index="approval_year", columns="review_priority_group", values="count")
        .fillna(0)
        .reset_index()
        .sort_values("approval_year")
    )
    tables["priority_by_year"] = priority_by_year

    orphan_by_year = (
        backbone.dropna(subset=["approval_year"])
        .groupby("approval_year", dropna=False)["orphan_designation"]
        .sum()
        .reset_index(name="orphan_approvals")
        .sort_values("approval_year")
    )
    tables["orphan_by_year"] = orphan_by_year

    missingness = (
        backbone.isna()
        .mean()
        .mul(100)
        .round(2)
        .reset_index()
        .rename(columns={"index": "column", 0: "missing_pct"})
        .sort_values("missing_pct", ascending=False)
    )
    tables["missingness_summary"] = missingness

    ingredients = (
        backbone["active_ingredient"]
        .dropna()
        .str.split(";")
        .explode()
        .str.strip()
    )
    top_ingredients = ingredients.value_counts().head(25).reset_index()
    top_ingredients.columns = ["active_ingredient", "approval_count"]
    tables["top_active_ingredients"] = top_ingredients

    return tables


def save_summary_tables(tables: dict[str, pd.DataFrame], tables_dir: Path) -> None:
    for name, df in tables.items():
        df.to_csv(tables_dir / f"{name}.csv", index=False)


def make_plots(backbone: pd.DataFrame, tables: dict[str, pd.DataFrame], figures_dir: Path) -> None:
    plt.style.use("default")

    approvals_by_year = tables["approvals_by_year"]
    fig, ax = plt.subplots(figsize=(8, 4))
    ax.plot(approvals_by_year["approval_year"], approvals_by_year["approval_count"], color="black")
    ax.set_title("FDA Approvals by Year (ORIG submissions)")
    ax.set_xlabel("Approval year")
    ax.set_ylabel("Count")
    ax.grid(True, alpha=0.3)
    fig.tight_layout()
    fig.savefig(figures_dir / "approvals_by_year.png", dpi=150)
    plt.close(fig)

    priority_by_year = tables["priority_by_year"]
    fig, ax = plt.subplots(figsize=(8, 4))
    for col, color in [
        ("PRIORITY", "#1f77b4"),
        ("STANDARD", "#2ca02c"),
        ("OTHER/UNKNOWN", "#ff7f0e"),
        ("MISSING", "#7f7f7f"),
    ]:
        if col in priority_by_year:
            ax.plot(priority_by_year["approval_year"], priority_by_year[col], label=col, color=color)
    ax.set_title("Review Priority by Year (ORIG submissions)")
    ax.set_xlabel("Approval year")
    ax.set_ylabel("Count")
    ax.legend(frameon=False, fontsize=8)
    ax.grid(True, alpha=0.3)
    fig.tight_layout()
    fig.savefig(figures_dir / "review_priority_by_year.png", dpi=150)
    plt.close(fig)

    orphan_by_year = tables["orphan_by_year"]
    fig, ax = plt.subplots(figsize=(8, 4))
    ax.plot(orphan_by_year["approval_year"], orphan_by_year["orphan_approvals"], color="#8c564b")
    ax.set_title("Orphan Designation Approvals by Year (ORIG submissions)")
    ax.set_xlabel("Approval year")
    ax.set_ylabel("Count")
    ax.grid(True, alpha=0.3)
    fig.tight_layout()
    fig.savefig(figures_dir / "orphan_approvals_by_year.png", dpi=150)
    plt.close(fig)


def create_arcos_stub(backbone: pd.DataFrame, intermediate_dir: Path) -> None:
    ingredients = (
        backbone["active_ingredient"]
        .dropna()
        .str.split(";")
        .explode()
        .str.strip()
    )
    unique_ingredients = sorted({i for i in ingredients if i})

    mapping_stub = pd.DataFrame(
        {
            "active_ingredient": unique_ingredients,
            "active_ingredient_norm": [normalize_text(v) for v in unique_ingredients],
            "possible_controlled_substance": pd.NA,
            "dea_schedule": pd.NA,
            "arcos_merge_notes": "",
        }
    )
    mapping_stub.to_csv(
        intermediate_dir / "controlled_substance_mapping_stub.csv", index=False
    )

    candidates = backbone[
        [
            "appl_no",
            "submission_no",
            "appl_type",
            "drug_name",
            "active_ingredient",
            "sponsor_name",
            "approval_date",
            "review_priority_group",
            "orphan_designation",
            "active_ingredient_norm",
        ]
    ].copy()
    candidates["needs_manual_controlled_substance_flag"] = True
    candidates["arcos_merge_notes"] = ""
    candidates.to_csv(intermediate_dir / "arcos_merge_candidates.csv", index=False)


def run_pipeline(root: Path) -> dict[str, Path]:
    paths = ensure_dirs(root)
    zip_path = paths.raw_dir / "drugsatfda.zip"
    log_path = paths.logs_dir / "download_failures.log"
    zip_path = download_fda_zip(zip_path, log_path=log_path)

    if zip_path is None or not zip_path.exists():
        raise RuntimeError(
            "FDA data download failed. See logs/download_failures.log and place the "
            "FDA Drugs@FDA zip in data/raw/drugsatfda.zip."
        )

    applications = read_fda_table(zip_path, "Applications.txt")
    submissions = read_fda_table(zip_path, "Submissions.txt")
    products = read_fda_table(zip_path, "Products.txt")
    submission_class_lookup = read_fda_table(zip_path, "SubmissionClass_Lookup.txt")
    submission_properties = read_fda_table(zip_path, "SubmissionPropertyType.txt")

    backbone = build_backbone(
        applications, submissions, products, submission_class_lookup, submission_properties
    )

    backbone_path = paths.processed_dir / "fda_backbone.csv"
    backbone.to_csv(backbone_path, index=False)

    dictionary_path = paths.processed_dir / "fda_backbone_data_dictionary.csv"
    build_data_dictionary().to_csv(dictionary_path, index=False)

    tables = create_summary_tables(backbone)
    save_summary_tables(tables, paths.tables_dir)
    make_plots(backbone, tables, paths.figures_dir)
    create_arcos_stub(backbone, paths.intermediate_dir)

    return {
        "backbone": backbone_path,
        "dictionary": dictionary_path,
        "figures_dir": paths.figures_dir,
        "tables_dir": paths.tables_dir,
        "intermediate_dir": paths.intermediate_dir,
    }


if __name__ == "__main__":
    project_root = Path(__file__).resolve().parents[1]
    outputs = run_pipeline(project_root)
    print("Pipeline outputs:")
    for key, value in outputs.items():
        print(f"- {key}: {value}")
