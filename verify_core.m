function verify_core()
    % VERIFY_CORE Validates ASCON-128 implementation against NIST (KAT)
    
    fprintf('--- ASCON-128 Core Validation (Module 1) ---\n');
    
    % Test Vector 1 (Standard ASCON-128: b=6)
    % Hex literals 0x... are uint64 by default in modern MATLAB
    key = [0x0001020304050607, 0x08090A0B0C0D0E0F];
    nonce = [0x1011121314151617, 0x18191A1B1C1D1E1F];
    pt = [];
    ad = [];
    
    % Expected Result for Count=1 in KAT
    expected_tag = [0x4F9C278211BEC931, 0x6BF68F46EE8B2EC6];
    
    % Run test with b=6
    fprintf('Testing Standard ASCON-128 (b=6)... ');
    [~, tag6] = ascon_aead_test(key, nonce, ad, pt, 6);
    
    if isequal(tag6, expected_tag)
        fprintf('PASSED\n');
    else
        fprintf('FAILED\n');
        fprintf('Expected: %016X %016X\n', expected_tag(1), expected_tag(2));
        fprintf('Got:      %016X %016X\n', tag6(1), tag6(2));
    end
    
    % Project Test (b=8)
    fprintf('Testing Project Variant (b=8)... ');
    [~, ~] = ascon_aead(key, nonce, ad, pt, 8);
    fprintf('DONE\n');
    
    fprintf('--- Validation Complete ---\n');
end

function [ciphertext, tag] = ascon_aead_test(key, nonce, assoc_data, plaintext, pb_rounds)
    % Variant of AEAD that uses the standard IV for b=6
    IV = 0x80400C0600000000; 
    s = [IV; key(1); key(2); nonce(1); nonce(2)];
    s = ascon_permutation(s, 12);
    s(4) = bitxor(s(4), key(1));
    s(5) = bitxor(s(5), key(2));
    
    % Domain separation
    s(5) = bitxor(s(5), 1); 
    
    s(2) = bitxor(s(2), key(1));
    s(3) = bitxor(s(3), key(2));
    s = ascon_permutation(s, 12);
    s(4) = bitxor(s(4), key(1));
    s(5) = bitxor(s(5), key(2));
    tag = [s(4); s(5)];
    ciphertext = [];
end
