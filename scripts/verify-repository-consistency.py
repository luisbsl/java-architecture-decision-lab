#!/usr/bin/env python3
from __future__ import annotations

import os
import re
import stat
import subprocess
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
NS = {"m": "http://maven.apache.org/POM/4.0.0"}
ERRORS: list[str] = []


def error(message: str) -> None:
    ERRORS.append(message)


def read(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except Exception as exc:  # pragma: no cover - defensive CLI path
        error(f"cannot_read:{path.relative_to(ROOT)}:{exc}")
        return ""


def xml_text(root: ET.Element, path: str) -> str | None:
    element = root.find(path, NS)
    return element.text.strip() if element is not None and element.text else None


def verify_maven() -> None:
    root_pom = ROOT / "pom.xml"
    try:
        model = ET.parse(root_pom).getroot()
    except ET.ParseError as exc:
        error(f"invalid_root_pom:{exc}")
        return

    version = xml_text(model, "m:version")
    java_version = xml_text(model, "m:properties/m:java.version")
    compiler_release = xml_text(model, "m:properties/m:maven.compiler.release")
    if version != "1.0.0":
        error(f"unexpected_project_version:{version}")
    if java_version != "21" or compiler_release != "21":
        error(f"java_release_mismatch:java.version={java_version}:compiler={compiler_release}")

    modules = [item.text.strip() for item in model.findall("m:modules/m:module", NS) if item.text]
    expected = {
        "labs/01-loom-vs-reactive-checkout/external-services-simulator",
        "labs/01-loom-vs-reactive-checkout/mvc-virtual-threads",
        "labs/01-loom-vs-reactive-checkout/webflux-reactor",
    }
    if set(modules) != expected:
        error(f"module_set_mismatch:{modules}")

    for module in modules:
        pom = ROOT / module / "pom.xml"
        if not pom.is_file():
            error(f"missing_module_pom:{module}")
            continue
        try:
            child = ET.parse(pom).getroot()
        except ET.ParseError as exc:
            error(f"invalid_module_pom:{module}:{exc}")
            continue
        parent_version = xml_text(child, "m:parent/m:version")
        if parent_version != version:
            error(f"module_parent_version_mismatch:{module}:{parent_version}:{version}")


def verify_wrapper() -> None:
    props = {}
    for line in read(ROOT / ".mvn/wrapper/maven-wrapper.properties").splitlines():
        if "=" in line:
            key, value = line.split("=", 1)
            props[key] = value
    expected_url = (
        "https://repo.maven.apache.org/maven2/org/apache/maven/"
        "apache-maven/3.9.16/apache-maven-3.9.16-bin.zip"
    )
    if props.get("distributionUrl") != expected_url:
        error(f"unexpected_maven_distribution:{props.get('distributionUrl')}")
    checksum = props.get("distributionSha512Sum", "")
    if not re.fullmatch(r"[0-9a-f]{128}", checksum):
        error("invalid_maven_sha512")
    if read(ROOT / ".java-version").strip() != "21":
        error("java_version_file_must_be_21")


def verify_evidence_protocol() -> None:
    suite = read(ROOT / "labs/01-loom-vs-reactive-checkout/scripts/run-evidence-suite.sh")
    makefile = read(ROOT / "labs/01-loom-vs-reactive-checkout/Makefile")
    if not re.search(r"^PAIRS=4$", suite, re.MULTILINE):
        error("suite_default_pairs_must_be_4")
    if "PAIRS % 2 == 0" not in suite:
        error("suite_must_enforce_even_pair_count")
    if "PAIRS:-4" not in makefile:
        error("makefile_default_pairs_must_be_4")
    if "PROTOCOL_VERSION=5" not in suite:
        error("protocol_version_must_be_5")
    if "export LC_ALL=C" not in suite:
        error("protocol_fingerprint_must_be_locale_stable")
    if "SUITE_CONFIG_FINGERPRINT" not in suite:
        error("suite_must_pin_runtime_configuration")
    if "Formal paired evidence requires an initialized Git repository" not in suite:
        error("suite_must_require_git_identity")


def repository_source_paths() -> list[Path]:
    """Return files that belong to the source tree, excluding ignored local outputs.

    In an initialized Git repository, tracked files plus non-ignored untracked files
    are the authoritative source set. Ignored runtime artifacts such as __pycache__,
    target, and .artifacts must not poison a local consistency run. Before Git is
    initialized (for example while validating a delivery archive), every extracted
    file remains in scope.
    """
    if (ROOT / ".git").exists():
        completed = subprocess.run(
            [
                "git",
                "-C",
                str(ROOT),
                "ls-files",
                "--cached",
                "--others",
                "--exclude-standard",
                "-z",
            ],
            check=False,
            capture_output=True,
        )
        if completed.returncode == 0:
            paths: list[Path] = []
            for raw in completed.stdout.split(b"\0"):
                if not raw:
                    continue
                candidate = ROOT / raw.decode("utf-8", errors="surrogateescape")
                if candidate.exists():
                    paths.append(candidate)
            return paths

    return [path for path in ROOT.rglob("*") if path.is_file()]


def verify_no_delivery_debris() -> None:
    candidate_prefix = "R" + "C"
    forbidden_names = {
        f"{candidate_prefix}7_DELIVERY.md",
        "RUNTIME_" + "FIX_REPORT.md",
        "RUNTIME_STARTUP_" + "FIX_REPORT.md",
        "RELEASE_" + "VERIFICATION.md",
    }
    for path in repository_source_paths():
        relative = path.relative_to(ROOT)
        if path.name in forbidden_names:
            error(f"delivery_only_file_present:{relative}")
        if path.name == "__pycache__" or path.suffix == ".pyc":
            error(f"python_cache_present:{relative}")
        if "target" in relative.parts or ".artifacts" in relative.parts:
            error(f"generated_artifact_present:{relative}")

    candidate_pattern = r"\b" + "R" + "C" + r"\d+\b"
    marketing_pattern = "Hard" + "-Pro"
    rc_pattern = re.compile(candidate_pattern + "|" + marketing_pattern, re.IGNORECASE)
    for path in ROOT.rglob("*.md"):
        if rc_pattern.search(read(path)):
            error(f"release_candidate_language_present:{path.relative_to(ROOT)}")


def verify_markdown_links() -> None:
    pattern = re.compile(r"(?<!!)\[[^\]]+\]\(([^)]+)\)")
    for markdown in ROOT.rglob("*.md"):
        for target in pattern.findall(read(markdown)):
            target = target.strip()
            if not target or target.startswith(("#", "http://", "https://", "mailto:")):
                continue
            path_part = target.split("#", 1)[0]
            if path_part and not (markdown.parent / path_part).resolve().exists():
                error(f"broken_markdown_link:{markdown.relative_to(ROOT)}:{target}")


def verify_scripts() -> None:
    paths = [ROOT / "mvnw"] + list((ROOT / "scripts").glob("*.sh"))
    paths += list((ROOT / "labs/01-loom-vs-reactive-checkout/scripts").glob("*.sh"))
    for script in paths:
        if not script.is_file():
            error(f"missing_script:{script.relative_to(ROOT)}")
            continue
        mode = script.stat().st_mode
        if not mode & stat.S_IXUSR:
            error(f"script_not_executable:{script.relative_to(ROOT)}")
        first = read(script).splitlines()[:1]
        if not first or not first[0].startswith("#!"):
            error(f"script_missing_shebang:{script.relative_to(ROOT)}")


def main() -> int:
    verify_maven()
    verify_wrapper()
    verify_evidence_protocol()
    verify_no_delivery_debris()
    verify_markdown_links()
    verify_scripts()

    if ERRORS:
        for issue in ERRORS:
            print(f"[ERROR] {issue}", file=sys.stderr)
        print(f"[FAILED] Repository consistency errors={len(ERRORS)}", file=sys.stderr)
        return 1
    print("[OK] Repository consistency verification passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
