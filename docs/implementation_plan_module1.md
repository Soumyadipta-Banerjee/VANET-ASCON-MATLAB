# Implementation Plan: Module 1 — The ASCON Core

This module focuses on building the cryptographic heart of the project: the ASCON-128 algorithm. We will implement the core permutations and the Authenticated Encryption with Associated Data (AEAD) logic in vectorized MATLAB.

## User Review Required

> [!IMPORTANT]
> **Numerical Implementation**: MATLAB's `uint64` will be used for state representation. I will implement a custom bitwise rotation function (`rotate_right`) to handle the 64-bit rotations required by the Linear Diffusion layer, as MATLAB's standard `bitrol/bitror` may vary across versions.

> [!CAUTION]
> **Failsafe Enforcement**: This module will be hard-coded to support only 12-round ($p_a$) and 8-round ($p_b$) as per the architectural rules. Any attempt to use fewer rounds will trigger a failsafe error.

## Proposed Changes

### [Component] ASCON Core (MATLAB)

#### [NEW] [ascon_permutation.m](file:///home/soumya/SU2/VANET-ASCON-MATLAB/ascon_permutation.m)
Vectorized implementation of the ASCON permutation:
- **Round Constants Addition**: XORing $RC$ into the state.
- **Substitution Layer**: 5-bit S-box implemented via bitwise logic.
- **Linear Diffusion Layer**: Internal bitwise rotations and XORs.

#### [NEW] [ascon_aead.m](file:///home/soumya/SU2/VANET-ASCON-MATLAB/ascon_aead.m)
Top-level function for encryption/decryption:
- **Initialization Phase**: Key/Nonce setup.
- **Processing Associated Data**: Handling metadata.
- **Processing Plaintext/Ciphertext**: Streaming blocks through the state.
- **Finalization**: Tag generation.

#### [NEW] [verify_core.m](file:///home/soumya/SU2/VANET-ASCON-MATLAB/verify_core.m)
Test script that:
- Reads Selected Test Vectors from `ascon_reference/crypto_aead/ascon128v12/ref/KAT_ascon128v12.txt`.
- Compares MATLAB results against the reference.
- Prints a "CRYPTO-VALIDATION SUCCESS" message if they match.

## Open Questions

1. **Performance Logging**: Should I include timestamping inside the core functions for the upcoming Benchmark module, or keep them clean and handle timing in the Benchmark script?
2. **Bitwise Precision**: MATLAB `uint64` handles bitwise operations well, but bitwise NOT (`bitcmp`) requires the bit-length. Are you using a version of MATLAB newer than R2022b? (R2026a is installed, so we are safe).

## Verification Plan

### Automated Tests
- Once MATLAB is installed, run:
  `matlab -batch "verify_core"`
- The script must show a 0% error rate against the official 10,000-message test vector set.

### Manual Verification
- Visual inspection of the 320-bit state during the first 12 rounds of initialization to match standard documentation examples.
