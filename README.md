# TorsoPhantomDemo

This demo runs a set of experiments to showcase the GeometricMedicalPhantoms torso phantom.

## Setup

```bash
julia --project=. -e 'using Pkg; Pkg.instantiate()'
```

## Experiments

```bash
julia --project=. scripts/experiment_a_montage.jl
julia --project=. scripts/experiment_b_validation.jl
julia --project=. scripts/experiment_c_benchmark.jl
julia --project=. scripts/experiment_d_recon.jl
```

Outputs are written to the `output/` folder as PNG/PDF files.
