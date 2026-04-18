function [ciphertext, tag] = ascon_aead(key, nonce, assoc_data, plaintext, pa_rounds, pb_rounds)
    % ASCON_AEAD Performs Authenticated Encryption with Associated Data (VECTORIZED)
    % key: uint64 matrix (2 x N)
    % nonce: uint64 matrix (2 x N)
    % assoc_data: uint64 matrix (M_ad x N)
    % plaintext: uint64 matrix (M_pt x N)
    % pa_rounds: Round count for Initialization/Finalization
    % pb_rounds: Round count for intermediate blocks
    
    N = size(key, 2); % Number of messages in batch
    
    % 1. Initialization
    IV = 0x80400C0800000000; 
    % Expand state to 5 x N
    s = [repmat(IV, 1, N); key; nonce];
    s = ascon_permutation(s, pa_rounds); % ADAPTIVE boundaries
    
    % XOR Key into state
    s(4,:) = bitxor(s(4,:), key(1,:));
    s(5,:) = bitxor(s(5,:), key(2,:));
    
    % 2. Process Associated Data
    if ~isempty(assoc_data)
        for i = 1:size(assoc_data, 1)
            s(1,:) = bitxor(s(1,:), assoc_data(i,:));
            s = ascon_permutation(s, pb_rounds);
        end
    end
    s(5,:) = bitxor(s(5,:), 1); % Domain separation
    
    % 3. Process Plaintext
    ciphertext = uint64(zeros(size(plaintext)));
    if ~isempty(plaintext)
        for i = 1:size(plaintext, 1)
            s(1,:) = bitxor(s(1,:), plaintext(i,:));
            ciphertext(i,:) = s(1,:);
            if i < size(plaintext, 1)
                s = ascon_permutation(s, pb_rounds);
            end
        end
    end
    
    % 4. Finalization
    s(2,:) = bitxor(s(2,:), key(1,:));
    s(3,:) = bitxor(s(3,:), key(2,:));
    s = ascon_permutation(s, pa_rounds); % ADAPTIVE boundaries
    
    % XOR Key again
    s(4,:) = bitxor(s(4,:), key(1,:));
    s(5,:) = bitxor(s(5,:), key(2,:));
    
    tag = [s(4,:); s(5,:)];
end
