from __future__ import annotations

from typing import Any, Dict, Iterable, Optional, Sequence

from .opts_models import PipelineOpts, to_matlab_structs


def _common_kwargs_from_pipeline(
    pipeline_opts: Optional[PipelineOpts],
) -> Dict[str, Any]:
    """
    Build a kwargs dict for MATLAB entry points from PipelineOpts.

    This does not call MATLAB itself. It only prepares a mapping that can be
    passed to matlab.engine or serialized into a .mat file.
    """

    if pipeline_opts is None:
        return {}
    return to_matlab_structs(pipeline_opts)


def build_spectral2processed_batch_call(
    filenames: Sequence[str],
    output_dir: str = "",
    pipeline_opts: Optional[PipelineOpts] = None,
    num_workers: Optional[int] = None,
    pool_type: str = "process",
) -> Dict[str, Any]:
    """
    Prepare arguments for MATLAB psoct.file.spectral2processed_batch.

    Returns a dictionary with keys:
      - function: MATLAB function name as string
      - args: positional argument list suitable for matlab.engine
    """

    filenames_list = list(filenames)
    kwargs = _common_kwargs_from_pipeline(pipeline_opts)

    spectral_opts = kwargs.get("spectralOpts", {})
    surface_opts = kwargs.get("surfaceOpts", {})
    enface_opts = kwargs.get("enfaceOpts", {})
    acquisition_opts = kwargs.get("acquisitionOpts", {})
    output_opts = kwargs.get("outputOpts", {})
    volume_opts = kwargs.get("volumeOpts", {})
    opts_mat_file = kwargs.get("optsMatFile", "")

    args: Iterable[Any] = [
        filenames_list,
        output_dir,
        spectral_opts,
        surface_opts,
        enface_opts,
        acquisition_opts,
        output_opts,
        volume_opts,
        opts_mat_file,
        num_workers if num_workers is not None else [],
        pool_type,
    ]

    return {"function": "psoct.file.spectral2processed_batch", "args": list(args)}


def build_complex2processed_batch_call(
    filenames: Sequence[str],
    output_dir: str = "",
    pipeline_opts: Optional[PipelineOpts] = None,
    num_workers: Optional[int] = None,
    pool_type: str = "process",
) -> Dict[str, Any]:
    """
    Prepare arguments for MATLAB psoct.file.complex2processed_batch.
    """

    filenames_list = list(filenames)
    kwargs = _common_kwargs_from_pipeline(pipeline_opts)

    surface_opts = kwargs.get("surfaceOpts", {})
    enface_opts = kwargs.get("enfaceOpts", {})
    acquisition_opts = kwargs.get("acquisitionOpts", {})
    output_opts = kwargs.get("outputOpts", {})
    volume_opts = kwargs.get("volumeOpts", {})
    opts_mat_file = kwargs.get("optsMatFile", "")

    args: Iterable[Any] = [
        filenames_list,
        output_dir,
        surface_opts,
        enface_opts,
        acquisition_opts,
        output_opts,
        volume_opts,
        opts_mat_file,
        num_workers if num_workers is not None else [],
        pool_type,
    ]

    return {"function": "psoct.file.complex2processed_batch", "args": list(args)}


def build_spectral2complex_batch_call(
    filenames: Sequence[str],
    output_dir: str = "",
    pipeline_opts: Optional[PipelineOpts] = None,
    num_workers: Optional[int] = None,
    pool_type: str = "process",
) -> Dict[str, Any]:
    """
    Prepare arguments for MATLAB psoct.file.spectral2complex_batch.
    """

    filenames_list = list(filenames)
    kwargs = _common_kwargs_from_pipeline(pipeline_opts)

    spectral_opts = kwargs.get("spectralOpts", {})
    output_opts = kwargs.get("outputOpts", {})
    opts_mat_file = kwargs.get("optsMatFile", "")

    args: Iterable[Any] = [
        filenames_list,
        output_dir,
        spectral_opts,
        output_opts,
        opts_mat_file,
        num_workers if num_workers is not None else [],
        pool_type,
    ]

    return {"function": "psoct.file.spectral2complex_batch", "args": list(args)}


