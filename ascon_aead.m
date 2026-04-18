function [ciphertext, tag] = ascon_aead(key, nonce, assoc_data, plaintext, pb_rounds)
    % ASCON_AEAD Performs Authenticated Encryption with Associated Data
    % key: uint64 array (2 elements, 128 bits)
    % nonce: uint64 array (2 elements, 128 bits)
    % assoc_data: uint64 array (N elements, N*64 bits)
    % plaintext: uint64 array (M elements, M*64 bits)
    % pb_rounds: Round count for intermediate phases (8 or 12 as per project rules)
    
    % 1. Initialization
    % IV for k=128, r=64, a=12, b=8 (Note: b is project-specific)
    % Using hex literal for uint64 precision
    IV = 0x80400C0800000000; % 128, 64, 12, 8
    
    s = [IV; key(1); key(2); nonce(1); nonce(2)];
    s = ascon_permutation(s, 12); % Initialization always 12 rounds
    
    % XOR Key into state (Finalization of initialization)
    s(4) = bitxor(s(4), key(1));
    s(5) = bitxor(s(5), key(2));
    
    % 2. Process Associated Data
    if ~isempty(assoc_data)
        for i = 1:length(assoc_data)
            s(1) = bitxor(s(1), assoc_data(i));
            s = ascon_permutation(s, pb_rounds);
        end
    end
    % Domain separation
    s(5) = bitxor(s(5), 1);
    
    % 3. Process Plaintext
    ciphertext = uint64(zeros(size(plaintext)));
    if ~isempty(plaintext)
        for i = 1:length(plaintext)
            s(1) = bitxor(s(1), plaintext(i));
            ciphertext(i) = s(1);
            if i < length(plaintext)
                s = ascon_permutation(s, pb_rounds);
            end
        end
    end
    
    % 4. Finalization
    s(2) = bitxor(s(2), key(1));
    s(3) = bitxor(s(3), key(2));
    s = ascon_permutation(s, 12); % Finalization always 12 rounds
    
    % XOR Key again
    s(4) = bitxor(s(4), key(1));
    s(5) = bitxor(s(5), key(2));
    
    % Extract Tag (128 bits from x3, x4)
    tag = [s(4); s(5)];
end
