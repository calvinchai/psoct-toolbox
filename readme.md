addpath('/autofs/cluster/octdata2/users/Hui/PSCalibration/code');
    addpath('/autofs/cluster/octdata2/users/Hui/tools/rob_utils');
    addpath('/autofs/cluster/octdata2/users/Chao/code/telesto');
    addpath('/autofs/cluster/octdata2/users/Chao/code/tools/freesurfer')
no external dependency


    use parfeval for concurrent writing 


% addpath ('/autofs/cluster/octdata2/users/Chao/code/demon_registration_version_8f');
% addpath('/autofs/cluster/octdata2/users/Chao/code/telesto');
% addpath ('/space/omega/1/users/3d_axis/PAPER/scripts');


eng.addpath(eng.genpath('/path/to/psoct-toolbox'), nargout=0)
addpath(genpath('/path/to/psoct-toolbox'))


Python packaging
================

This repository can also be installed as a Python package that ships the MATLAB
`+psoct` toolbox as data. This is intended for Python projects that depend on
the PS-OCT MATLAB code.

Install from a wheel or from PyPI (once published):

    pip install psoct-toolbox

From Python, you can locate the installed MATLAB toolbox directory using
`psoct_toolbox.get_matlab_root`:

```python
import psoct_toolbox

matlab_root = psoct_toolbox.get_matlab_root()
print(matlab_root)  # path containing the +psoct MATLAB package
```

You can then add this path to MATLAB (or the MATLAB Engine for Python), e.g.:

```python
import matlab.engine
import psoct_toolbox

eng = matlab.engine.start_matlab()
eng.addpath(eng.genpath(str(psoct_toolbox.get_matlab_root())), nargout=0)
```

Building and testing the wheel locally
--------------------------------------

To build a source distribution and wheel:

```bash
python -m pip install --upgrade build
python -m build
```

This will create `dist/*.whl` and `dist/*.tar.gz` containing the `psoct_toolbox`
Python package and the mirrored `psoct` MATLAB toolbox under
`psoct_toolbox/matlab/+psoct`.

To test installation in a fresh environment:

```bash
python -m venv .venv-test
source .venv-test/bin/activate
python -m pip install dist/psoct_toolbox-*.whl
python -c "import psoct_toolbox, pathlib; p = psoct_toolbox.get_matlab_root(); print(p, pathlib.Path(p).is_dir())"
```
