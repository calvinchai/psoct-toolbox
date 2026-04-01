from __future__ import annotations

from numbers import Number
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


def _matlab_quote(value: str) -> str:
    escaped = value.replace("'", "''")
    return f"'{escaped}'"


def _matlab_literal(value: Any) -> str:
    """
    Convert a Python value into a MATLAB literal string suitable for `matlab -batch`
    or `eng.eval(...)`.
    """
    if isinstance(value, dict):
        return dict_to_matlab_literal(value)
    if isinstance(value, bool):
        return "true" if value else "false"
    if value is None:
        return "''"
    if isinstance(value, str):
        return _matlab_quote(value)
    if isinstance(value, Number):
        return str(value)
    if isinstance(value, (list, tuple)):
        if not value:
            return "[]"
        return "[" + ", ".join(_matlab_literal(v) for v in value) + "]"
    raise TypeError(f"Unsupported value type for MATLAB literal: {type(value)}")


def dict_to_matlab_literal(value: dict[str, Any]) -> str:
    """
    Convert a (possibly nested) dict into a MATLAB `struct(...)` literal.
    """
    if not value:
        return "struct()"
    fields: list[str] = []
    for key, field_value in value.items():
        key_lit = _matlab_literal(str(key))
        value_lit = _matlab_literal(field_value)
        fields.append(f"{key_lit}, {value_lit}")
    return f"struct({', '.join(fields)})"


def _pipeline_struct_literal(pipeline_opts: Optional[PipelineOpts], key: str) -> str:
    """
    Convert a PipelineOpts sub-struct (e.g. spectralOpts) into a MATLAB struct literal.
    """
    kwargs = _common_kwargs_from_pipeline(pipeline_opts)
    field = kwargs.get(key, {})
    if not isinstance(field, dict):
        raise TypeError(f"Expected dict for {key}, got {type(field)}")
    return dict_to_matlab_literal(field)


def build_spectral2processed_batch_indexed_command(
    filenames: Sequence[str],
    *,
    output_dir: str,
    mosaic_id: int,
    tile_indices: Sequence[int],
    pipeline_opts: Optional[PipelineOpts] = None,
    num_workers: Optional[int] = None,
    pool_type: str = "process",
    opts_mat_file_override: Optional[str] = None,
) -> str:
    """
    Build a MATLAB command string for `psoct.file.spectral2processed_batch_indexed(...)`.
    """
    file_list_str = ",".join(_matlab_quote(str(p)) for p in filenames)
    output_dir_lit = _matlab_quote(output_dir)
    tile_indices_lit = "[" + ",".join(str(int(i)) for i in tile_indices) + "]"

    kwargs = _common_kwargs_from_pipeline(pipeline_opts)
    opts_mat_file = (
        opts_mat_file_override
        if opts_mat_file_override is not None
        else str(kwargs.get("optsMatFile") or "")
    )
    opts_mat_file_lit = "''" if not opts_mat_file else _matlab_quote(opts_mat_file)
    num_workers_lit = "[]" if num_workers is None else str(int(num_workers))
    pool_type_lit = _matlab_quote(pool_type)

    spectral_lit = _pipeline_struct_literal(pipeline_opts, "spectralOpts")
    surface_lit = _pipeline_struct_literal(pipeline_opts, "surfaceOpts")
    enface_lit = _pipeline_struct_literal(pipeline_opts, "enfaceOpts")
    acquisition_lit = _pipeline_struct_literal(pipeline_opts, "acquisitionOpts")
    output_lit = _pipeline_struct_literal(pipeline_opts, "outputOpts")
    volume_lit = _pipeline_struct_literal(pipeline_opts, "volumeOpts")

    return (
        "psoct.file.spectral2processed_batch_indexed("
        f"{{{file_list_str}}}, {output_dir_lit}, {int(mosaic_id)}, {tile_indices_lit}, "
        f"{spectral_lit}, {surface_lit}, {enface_lit}, {acquisition_lit}, {output_lit}, {volume_lit}, "
        f"{opts_mat_file_lit}, {num_workers_lit}, {pool_type_lit})"
    )


def build_complex2processed_batch_indexed_command(
    filenames: Sequence[str],
    *,
    output_dir: str,
    mosaic_id: int,
    tile_indices: Sequence[int],
    pipeline_opts: Optional[PipelineOpts] = None,
    num_workers: Optional[int] = None,
    pool_type: str = "process",
    opts_mat_file_override: Optional[str] = None,
) -> str:
    """
    Build a MATLAB command string for `psoct.file.complex2processed_batch_indexed(...)`.
    """
    file_list_str = ",".join(_matlab_quote(str(p)) for p in filenames)
    output_dir_lit = _matlab_quote(output_dir)
    tile_indices_lit = "[" + ",".join(str(int(i)) for i in tile_indices) + "]"

    kwargs = _common_kwargs_from_pipeline(pipeline_opts)
    opts_mat_file = (
        opts_mat_file_override
        if opts_mat_file_override is not None
        else str(kwargs.get("optsMatFile") or "")
    )
    opts_mat_file_lit = "''" if not opts_mat_file else _matlab_quote(opts_mat_file)
    num_workers_lit = "[]" if num_workers is None else str(int(num_workers))
    pool_type_lit = _matlab_quote(pool_type)

    surface_lit = _pipeline_struct_literal(pipeline_opts, "surfaceOpts")
    enface_lit = _pipeline_struct_literal(pipeline_opts, "enfaceOpts")
    acquisition_lit = _pipeline_struct_literal(pipeline_opts, "acquisitionOpts")
    output_lit = _pipeline_struct_literal(pipeline_opts, "outputOpts")
    volume_lit = _pipeline_struct_literal(pipeline_opts, "volumeOpts")

    return (
        "psoct.file.complex2processed_batch_indexed("
        f"{{{file_list_str}}}, {output_dir_lit}, {int(mosaic_id)}, {tile_indices_lit}, "
        f"{surface_lit}, {enface_lit}, {acquisition_lit}, {output_lit}, {volume_lit}, "
        f"{opts_mat_file_lit}, {num_workers_lit}, {pool_type_lit})"
    )


def build_thruplane_from_files_command(
    fixed_ori_path: str,
    moving_ori_path: str,
    fixed_biref_path: str,
    moving_biref_path: str,
    *,
    output_dir: str = "",
    gamma: float = -15.0,
) -> str:
    """
    Build a MATLAB command string for `thruplane_from_files(...)`.

    Intended for execution via `matlab -batch` or `eng.eval(...)`.
    """
    args_str = ", ".join(
        [
            _matlab_literal(str(fixed_ori_path)),
            _matlab_literal(str(moving_ori_path)),
            _matlab_literal(str(fixed_biref_path)),
            _matlab_literal(str(moving_biref_path)),
            _matlab_literal(str(output_dir)),
            _matlab_literal(float(gamma)),
        ]
    )
    return f"thruplane_from_files({args_str})"
