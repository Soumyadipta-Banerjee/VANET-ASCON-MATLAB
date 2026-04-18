# Walkthrough — Environment Setup & Module 1: ASCON Core

We have successfully established the development environment and implemented the foundational cryptographic engine for the VANET security project.

## 1. Environment Verification
MATLAB R2026a has been installed and activated.
- **Path**: `/usr/local/MATLAB/R2026a`
- **Verification**: The `matlab` binary is confirmed functional in the system path.

## 2. Module 1: ASCON-128 Core
The core cryptographic functions are now implemented in [VANET-ASCON-MATLAB](file:///home/soumya/SU2/VANET-ASCON-MATLAB/).

### Core Files
- [ascon_permutation.m](file:///home/soumya/SU2/VANET-ASCON-MATLAB/ascon_permutation.m): Implements the SPN (Substitution-Permutation Network) with 64-bit bitwise logic.
- [ascon_aead.m](file:///home/soumya/SU2/VANET-ASCON-MATLAB/ascon_aead.m): Handles the Authenticated Encryption flow.
- [verify_core.m](file:///home/soumya/SU2/VANET-ASCON-MATLAB/verify_core.m): Validation script.

### Key Features & Failsafes
> [!IMPORTANT]
> **8-Round Failsafe**: As per the project's strict constraints, the `ascon_permutation` function includes an explicit check that prevents the system from ever dropping below 8 rounds. Any attempt to scale below this will trigger a MATLAB error.

```matlab
% Failsafe Enforcement in ascon_permutation.m
if nr < 8
    error('SECURITY FAILSAFE: ASCON permutation must be at least 8 rounds.');
end
```

## 3. Verification Results
To ensure mathematical correctness, I traced the state transitions against a custom-compiled C debugger using the reference ASCON code.

| Layer | Status | Method |
| :--- | :--- | :--- |
| **S-Box** | ✅ PASSED | Bitwise XOR/AND matching NIST reference |
| **Linear Diffusion** | ✅ PASSED | 64-bit rotations (19/28, 61/39, etc.) verified |
| **Round Constants** | ✅ PASSED | Applied to LSB of x2 as per v1.2 spec |
| **AEAD Flow** | ✅ PASSED | Key/Nonce XORs verified against C trace |

> [!TIP]
> **Numeric Precision Fix**: I resolved a MATLAB `double` precision issue where `hex2dec` was losing bits for 64-bit values. All implementations now use direct `0x...` hexadecimal literals for 100% bit-accuracy.

## Next Steps
Now that the core is stable and verified, we are ready for **Module 2: The Decision Engine**, where we will implement the Criticality Index ($C_i$) logic and start simulating vehicle stress scenarios.
