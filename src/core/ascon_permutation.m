function s = ascon_permutation(s, nr)
    % ASCON_PERMUTATION Performs nr rounds of ASCON permutation
    % s: 5 x N uint64 array representing N 320-bit states (VECTORIZED)
    % nr: Number of rounds to perform (12 or 8)
    
    % Failsafe Enforcement: Minimum 8 rounds
    if nr < 8
        error('SECURITY FAILSAFE: ASCON permutation must be at least 8 rounds.');
    end
    
    % Round Constants (RC)
    RC = uint64([0xf0, 0xe1, 0xd2, 0xc3, 0xb4, 0xa5, 0x96, 0x87, 0x78, 0x69, 0x5a, 0x4b]);
    
    % Round indexing depends on nr 
    start_idx = 13 - nr;
    
    for i = start_idx:12
        % 1. Addition of Round Constant (into x2)
        s(3,:) = bitxor(s(3,:), RC(i));
        
        % 2. Substitution Layer (S-box)
        x0 = s(1,:);
        x1 = s(2,:);
        x2 = s(3,:);
        x3 = s(4,:);
        x4 = s(5,:);
        
        % S-box Step 1: XORs
        w0 = bitxor(x0, x4);
        w1 = x1;
        w2 = bitxor(x2, x1);
        w3 = x3;
        w4 = bitxor(x4, x3);
        
        % S-box Step 2: Non-linear updates
        T0 = bitand(bitcmp(w0, 'uint64'), w1);
        T1 = bitand(bitcmp(w1, 'uint64'), w2);
        T2 = bitand(bitcmp(w2, 'uint64'), w3);
        T3 = bitand(bitcmp(w3, 'uint64'), w4);
        T4 = bitand(bitcmp(w4, 'uint64'), w0);
        
        % S-box Step 3: Simultaneous updates
        w_prime_0 = bitxor(w0, T1);
        w_prime_1 = bitxor(w1, T2);
        w_prime_2 = bitxor(w2, T3);
        w_prime_3 = bitxor(w3, T4);
        w_prime_4 = bitxor(w4, T0);
        
        % S-box Step 4: Final XORs
        y1 = bitxor(w_prime_1, w_prime_0);
        y0 = bitxor(w_prime_0, w_prime_4);
        y3 = bitxor(w_prime_3, w_prime_2);
        y2 = bitcmp(w_prime_2, 'uint64');
        y4 = w_prime_4;
        
        % 3. Linear Diffusion Layer (vectorized and inlined)
        rot19_y0 = bitor(bitshift(y0, -19), bitshift(y0, 64-19));
        rot28_y0 = bitor(bitshift(y0, -28), bitshift(y0, 64-28));
        s(1,:) = bitxor(y0, bitxor(rot19_y0, rot28_y0));
        
        rot61_y1 = bitor(bitshift(y1, -61), bitshift(y1, 64-61));
        rot39_y1 = bitor(bitshift(y1, -39), bitshift(y1, 64-39));
        s(2,:) = bitxor(y1, bitxor(rot61_y1, rot39_y1));
        
        rot1_y2 = bitor(bitshift(y2, -1), bitshift(y2, 64-1));
        rot6_y2 = bitor(bitshift(y2, -6), bitshift(y2, 64-6));
        s(3,:) = bitxor(y2, bitxor(rot1_y2, rot6_y2));
        
        rot10_y3 = bitor(bitshift(y3, -10), bitshift(y3, 64-10));
        rot17_y3 = bitor(bitshift(y3, -17), bitshift(y3, 64-17));
        s(4,:) = bitxor(y3, bitxor(rot10_y3, rot17_y3));
        
        rot7_y4 = bitor(bitshift(y4, -7), bitshift(y4, 64-7));
        rot41_y4 = bitor(bitshift(y4, -41), bitshift(y4, 64-41));
        s(5,:) = bitxor(y4, bitxor(rot7_y4, rot41_y4));
    end
end
