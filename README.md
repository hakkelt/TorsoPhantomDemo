# TorsoPhantomDemo

This demo runs a set of experiments to showcase the GeometricMedicalPhantoms torso phantom.

## Setup

```bash
julia --project=. -e 'using Pkg; Pkg.instantiate()'
```

*Note: This project assumes Julia version 1.12. While it may work on older or newer versions, we recommend using 1.12 for best compatibility and reproducibility. To make it work with other versions, you may need to adjust the `Project.toml` file to specify compatible versions of dependencies, then run `Pkg.resolve()` to update the environment.*

## Experiments

```bash
julia --project=. scripts/experiment_a_montage.jl
julia --project=. scripts/experiment_b_validation.jl
julia --project=. scripts/experiment_c_benchmark.jl
julia --project=. scripts/experiment_d_recon.jl
```

Outputs are written to the `output/` folder as PNG/PDF files.
