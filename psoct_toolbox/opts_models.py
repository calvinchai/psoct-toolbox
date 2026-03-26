from __future__ import annotations

from typing import Any, Dict, List, Literal, Optional, Union

from pydantic import BaseModel, ConfigDict, Field


class SpectralOpts(BaseModel):
    """Pydantic model mirroring MATLAB spectralOpts struct."""

    model_config = ConfigDict(populate_by_name=True)

    disp_comp_file: Optional[str] = Field(
        default=None,
        alias="dispCompFile",
        description=(
            "Path to dispersion compensation file. "
            "If None, MATLAB will use its toolbox default."
        ),
    )
    aline_size: int = Field(default=200, alias="AlineSize")
    bline_size: int = Field(default=350, alias="BlineSize")
    is_raw_format: bool = Field(default=False, alias="isRawFormat")

    def to_matlab_struct(self) -> Dict[str, Any]:
        data = self.model_dump(by_alias=True, exclude_none=True)
        return data


class EnfaceComputeFlags(BaseModel):
    """Logical flags for which enface modalities to compute."""

    model_config = ConfigDict(populate_by_name=True)

    aip: bool = True
    mip: bool = True
    ret: bool = True
    ori: bool = True
    biref: bool = True

    def to_matlab_struct(self) -> Dict[str, Any]:
        # MATLAB expects a struct with logical fields.
        return self.model_dump(by_alias=True)


class EnfaceOpts(BaseModel):
    """Pydantic model mirroring MATLAB enfaceOpts struct."""

    model_config = ConfigDict(populate_by_name=True)

    offset: float = Field(default=0.0, alias="Offset")
    depth: float = Field(default=70.0, alias="Depth")
    ori_method: Union[Literal["circularMean","legay"]] = Field(default="circularMean", alias="OriMethod")
    ori_method_args: Dict[str, Any] = Field(
        default_factory=dict,
        alias="OriMethodArgs",
    )
    biref_method: str = Field(default="legacy", alias="BirefMethod")
    biref_method_args: Dict[str, Any] = Field(
        default_factory=dict,
        alias="BirefMethodArgs",
    )
    compute: EnfaceComputeFlags = Field(
        default_factory=EnfaceComputeFlags,
        alias="Compute",
    )
    save_2d_as_3d: bool = Field(default=True, alias="Save2DAs3D")

    def to_matlab_struct(self) -> Dict[str, Any]:
        data = self.model_dump(by_alias=True)
        # Ensure Compute is a plain struct/dict
        compute = data.get("Compute")
        if isinstance(compute, BaseModel):
            data["Compute"] = compute.to_matlab_struct()
        return data


class AcquisitionOpts(BaseModel):
    """Pydantic model mirroring MATLAB acquisitionOpts struct."""

    model_config = ConfigDict(populate_by_name=True)

    pixel_dimensions_um: List[float] = Field(
        default_factory=lambda: [10.0, 10.0, 2.5],
        alias="PixelDimensionsUm",
    )
    wavelength_um: float = Field(default=0.0013, alias="WavelengthUm")
    slice_thickness_um: float = Field(default=500.0, alias="SliceThicknessUm")

    def to_matlab_struct(self) -> Dict[str, Any]:
        data = self.model_dump(by_alias=True)
        # MATLAB expects a numeric vector, list is fine for matlab.engine / savemat.
        if "PixelDimensionsUm" in data:
            data["PixelDimensionsUm"] = list(data["PixelDimensionsUm"])
        return data


class VolumeOpts(BaseModel):
    """Pydantic model mirroring MATLAB volumeOpts struct."""

    model_config = ConfigDict(populate_by_name=True)

    flip_phase: bool = Field(default=False, alias="flipPhase")
    phase_offset: float = Field(default=(100.0 / 180.0) * 3.141592653589793, alias="phaseOffset")
    flip_z: bool = Field(default=True, alias="flipZ")

    def to_matlab_struct(self) -> Dict[str, Any]:
        return self.model_dump(by_alias=True)


class OutputPaths(BaseModel):
    """Paths to all supported PS-OCT output modalities."""

    model_config = ConfigDict(populate_by_name=True)

    complex: Optional[str] = Field(default=None, alias="complex")
    dBI: Optional[str] = Field(default=None, alias="dBI")
    R3D: Optional[str] = Field(default=None, alias="R3D")
    O3D: Optional[str] = Field(default=None, alias="O3D")
    surf: Optional[str] = Field(default=None, alias="surf")
    aip: Optional[str] = Field(default=None, alias="aip")
    mip: Optional[str] = Field(default=None, alias="mip")
    ret: Optional[str] = Field(default=None, alias="ret")
    ori: Optional[str] = Field(default=None, alias="ori")
    biref: Optional[str] = Field(default=None, alias="biref")
    inplane_tiff: Optional[str] = Field(default=None, alias="inplaneTiff")
    inplane_jpg: Optional[str] = Field(default=None, alias="inplaneJpg")
    inplane_nii: Optional[str] = Field(default=None, alias="inplaneNii")
    thruplane_tiff: Optional[str] = Field(default=None, alias="thruplaneTiff")
    thruplane_jpg: Optional[str] = Field(default=None, alias="thruplaneJpg")
    thruplane_nii: Optional[str] = Field(default=None, alias="thruplaneNii")
    data_mat: Optional[str] = Field(default=None, alias="dataMat")
    axis_nii: Optional[str] = Field(default=None, alias="axisNii")
    axis_jpg: Optional[str] = Field(default=None, alias="axisJpg")
    axis_nii_norm: Optional[str] = Field(default=None, alias="axisNiiNorm")
    registered_biref_nii: Optional[str] = Field(
        default=None,
        alias="registeredBirefNii",
    )

    def to_matlab_struct(self) -> Dict[str, Any]:
        data = self.model_dump(by_alias=True)
        # Fill any missing modalities with empty string to mirror normalizeOutputOpts.
        modalities = [
            "complex",
            "dBI3D",
            "R3D",
            "O3D",
            "surf",
            "aip",
            "mip",
            "ret",
            "ori",
            "biref",
            "inplaneTiff",
            "inplaneJpg",
            "inplaneNii",
            "thruplaneTiff",
            "thruplaneJpg",
            "thruplaneNii",
            "dataMat",
            "axisNii",
            "axisJpg",
            "axisNiiNorm",
            "registeredBirefNii",
        ]
        for key in modalities:
            value = data.get(key)
            if value is None:
                data[key] = ""
        return data


class OutputOpts(BaseModel):
    """Pydantic model mirroring MATLAB outputOpts struct."""

    model_config = ConfigDict(populate_by_name=True)

    paths: Optional[OutputPaths] = Field(default=None, alias="Paths")
    info_like: Optional[Dict[str, Any]] = Field(default=None, alias="InfoLike")

    def to_matlab_struct(self) -> Dict[str, Any]:
        paths_struct: Dict[str, Any]
        if self.paths is None:
            paths_struct = OutputPaths().to_matlab_struct()
        else:
            paths_struct = self.paths.to_matlab_struct()

        data: Dict[str, Any] = {"Paths": paths_struct}
        if self.info_like is not None:
            data["InfoLike"] = dict(self.info_like)
        return data


class SurfaceOpts(BaseModel):
    """Minimal surface options model (currently only Spec)."""

    model_config = ConfigDict(populate_by_name=True)

    spec: Optional[str] = Field(default=None, alias="Spec")

    def to_matlab_struct(self) -> Dict[str, Any]:
        return self.model_dump(by_alias=True, exclude_none=True)


class PipelineOpts(BaseModel):
    """
    Aggregate options container mirroring the MATLAB opts .mat layout.

    All fields are optional; if a field is None it will be omitted from the
    exported MATLAB struct mapping, letting MATLAB use empty structs/defaults.
    """

    model_config = ConfigDict(populate_by_name=True)

    spectral: Optional[SpectralOpts] = None
    surface: Optional[SurfaceOpts] = None
    enface: Optional[EnfaceOpts] = None
    acquisition: Optional[AcquisitionOpts] = None
    output: Optional[OutputOpts] = None
    volume: Optional[VolumeOpts] = None
    opts_mat_file: Optional[str] = None

    def to_matlab_structs(self) -> Dict[str, Any]:
        """
        Return a mapping from MATLAB variable names to struct-like dicts.

        Keys match the variables expected in the Opts .mat files, i.e.:
        spectralOpts, surfaceOpts, enfaceOpts, acquisitionOpts, outputOpts,
        volumeOpts and optsMatFile.
        """

        mapping: Dict[str, Any] = {}

        if self.spectral is not None:
            mapping["spectralOpts"] = self.spectral.to_matlab_struct()
        if self.surface is not None:
            mapping["surfaceOpts"] = self.surface.to_matlab_struct()
        if self.enface is not None:
            mapping["enfaceOpts"] = self.enface.to_matlab_struct()
        if self.acquisition is not None:
            mapping["acquisitionOpts"] = self.acquisition.to_matlab_struct()
        if self.output is not None:
            mapping["outputOpts"] = self.output.to_matlab_struct()
        if self.volume is not None:
            mapping["volumeOpts"] = self.volume.to_matlab_struct()
        if self.opts_mat_file is not None:
            mapping["optsMatFile"] = self.opts_mat_file

        return mapping


def to_matlab_structs(pipeline_opts: PipelineOpts) -> Dict[str, Any]:
    """
    Convenience wrapper to export PipelineOpts into MATLAB-compatible structs.
    """

    return pipeline_opts.to_matlab_structs()






