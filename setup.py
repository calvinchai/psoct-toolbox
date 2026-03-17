from pathlib import Path
from shutil import copytree, ignore_patterns, rmtree

from setuptools import setup
from setuptools.command.build_py import build_py as _build_py


class build_py(_build_py):
    """
    Custom build_py command that copies the root +psoct MATLAB toolbox into
    the Python package tree (psoct_toolbox/matlab/+psoct) at build time.

    This lets us keep a single source of truth for the MATLAB code at the
    repository root while still shipping it as package data in the wheel.
    """

    def run(self) -> None:
        repo_root = Path(__file__).parent.resolve()
        src = repo_root / "+psoct"
        dst = repo_root / "psoct_toolbox" / "matlab" / "+psoct"

        if not src.is_dir():
            raise RuntimeError(f"Expected MATLAB toolbox at {src}, but it was not found.")

        # Remove any existing build artifact before copying
        if dst.exists():
            rmtree(dst)

        dst.parent.mkdir(parents=True, exist_ok=True)

        copytree(
            src,
            dst,
            ignore=ignore_patterns("__pycache__", "*.pyc", "*.pyo", ".git"),
        )

        super().run()


setup(cmdclass={"build_py": build_py})

