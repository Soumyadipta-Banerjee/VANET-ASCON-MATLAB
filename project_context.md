# Project Context: Context-Aware Adaptive Lightweight Cryptography for Performance-Critical VANETs

## Project Objective
Development of a dynamic cryptographic controller for Vehicular Ad-hoc Networks (VANETs) that balances latency and security by scaling ASCON-128 processing rounds ($12 \leftrightarrow 8$) based on real-time vehicle telemetry and network stress.

## Core Architectural Design (Midterm Baseline)

### 1. Decision Engine Logic
Scaling is driven by the **Criticality Index ($C_i$)**:
$$C_i = (0.4 \cdot v) + (0.4 \cdot B) + (0.2 \cdot P)$$
- **Threshold**: **0.7** (Transition to high-performance mode).
- **Security Failsafe**: ENFORCED floor of **8 rounds**. Dropping below 8 rounds results in a system-level interrupt.

### 2. High-Performance Vectorized Core
- **Implementation**: bit-accurate matrix-based ASCON-128.
- **Optimization**: Parallel bitwise operations and inlined rotations.
- **Verified Status**: Logic correct against ASCON Official Reference Vectors.

## Midterm Performance Deliverables [ESTABLISHED]

### Statistical Performance (Module 3)
- **Methodology**: High-Integrity 100-run consistency audit (Mean filtering).
- **Mean Latency Reduction**: **33.24%** (matches theoretical algorithmic limit).
- **Precision**: 95% Confidence Interval with $\sigma = 1.70\%$.

### Security Integrity (Module 4)
- **Methodology**: Strict Avalanche Criterion (SAC) via Monte Carlo simulation (10,000 trials).
- **Hamming Distance**: **50.07%** (Target: 50.00%).
- **Conclusion**: 8-round mode provides full cryptographic diffusion for safety messages.

## Environment Configuration
- **MATLAB**: R2026a (Statistics, Parallel, Control System toolboxes).
- **Visualization**: Matplotlib (Research-Grade aesthetic, v2).

## Future Development (Phase 2)
1. **Module 5**: FPGA/ASIC Hardware Synthesis Feasibility.
2. **Module 6**: Integration with Network Simulators (OMNeT++/SUMO).
