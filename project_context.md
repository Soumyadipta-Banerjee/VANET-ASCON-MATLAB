# Project Context: Context-Aware Adaptive Lightweight Cryptography for Low-Latency VANET Security

## Project Overview
The goal of this project is to develop a dynamic cryptographic controller for Vehicular Ad-hoc Networks (VANETs). The system scales the processing rounds of the ASCON-128 algorithm based on real-time network stress to optimize latency while ensuring cryptographic security.

## Core Mathematical Formulas

### Criticality Index ($C_i$)
The $C_i$ determines the network stress level and dictates the cryptographic round selection.
$$C_i = (w_1 \cdot \hat{v}) + (w_2 \cdot \hat{B}) + (w_3 \cdot P)$$

Where:
- $\hat{v}$: Normalized vehicle speed.
- $\hat{B}$: Normalized buffer occupancy.
- $P$: Message priority.
- $w_1, w_2, w_3$: Weight factors (to be tuned).

## Architectural Rules (STRICT CONSTRAINTS)

1.  **Algorithm**: ASCON-128
2.  **Adaptive Round Scaling**:
    - **Low Stress ($C_i < \text{Threshold}$)**: Use $p_a$ (12-round) permutation.
    - **High Stress ($C_i \geq \text{Threshold}$)**: Use $p_b$ (8-round) permutation.
3.  **Failsafe**: The system MUST NEVER drop below 8 rounds of permutation to maintain the minimum security margin.
4.  **Goal**: Prevent buffer overflow in High-Density/High-Mobility scenarios while maintaining a mathematically secure Avalanche Effect.

## Environment & Setup
- **MATLAB Version**: R2026a
- **Installation Path**: `/usr/local/MATLAB/R2026a`
- **Toolboxes**: Statistics and Machine Learning, Parallel Computing.

## Mid-Term Evaluation Modules
1.  **ASCON Core**: Vectorized MATLAB implementation of ASCON-128 (12 and 8 rounds).
2.  **Decision Engine**: Logic to calculate $C_i$ from synthetic vehicle telemetry.
3.  **Speed Benchmark**: Empirical latency reduction analysis over 10,000 messages.
4.  **SAC Analyzer**: Monte Carlo simulation to verify Strict Avalanche Criterion (~50% Hamming Distance).
