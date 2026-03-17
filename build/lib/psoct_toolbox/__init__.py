from __future__ import annotations

from importlib import resources
from pathlib import Path


def get_matlab_root() -> Path:
    """
    Return the filesystem path to the installed +psoct MATLAB toolbox.

    This is the directory that should be added to the MATLAB path, e.g.:

        import psoct_toolbox
        matlab_root = psoct_toolbox.get_matlab_root()
        # pass `str(matlab_root)` to MATLAB / MATLAB Engine
    """

    # This resolves to the directory containing this __init__.py file
    pkg_root = Path(resources.files(__package__))
    return pkg_root / "matlab" 


__all__ = ["get_matlab_root"]

