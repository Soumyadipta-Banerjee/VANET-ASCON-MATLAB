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
        s(1,:) = bitxor(s(1,:), s(5,:));
        s(5,:) = bitxor(s(5,:), s(4,:));
        s(3,:) = bitxor(s(3,:), s(2,:));
        
        % Temporary variables for non-linear update (all vectorized)
        t0 = bitxor(s(1,:), bitand(bitcmp(s(2,:), 'uint64'), s(3,:)));
        t1 = bitxor(s(2,:), bitand(bitcmp(s(3,:), 'uint64'), s(4,:)));
        t2 = bitxor(s(3,:), bitand(bitcmp(s(4,:), 'uint64'), s(5,:)));
        t3 = bitxor(s(4,:), bitand(bitcmp(s(5,:), 'uint64'), s(1,:)));
        t4 = bitxor(s(5,:), bitand(bitcmp(s(1,:), 'uint64'), s(2,:)));
        
        % Linear transformation (diffusion layer) combined with S-box finalize
        t1 = bitxor(t1, t0);
        t3 = bitxor(t3, t2);
        t0 = bitxor(t0, t4);
        
        % 3. Linear Diffusion Layer (Inlined rotations for performance)
        % x0 = x0 ^ (x0 >>> 19) ^ (x0 >>> 28)
        rot19_t0 = bitor(bitshift(t0, -19), bitactive_shift_left(t0, 64-19));
        rot28_t0 = bitor(bitshift(t0, -28), bitactive_shift_left(t0, 64-28));
        s(1,:) = bitxor(t0, bitxor(rot19_t0, rot28_t0));
        
        % x1 = x1 ^ (x1 >>> 61) ^ (x1 >>> 39)
        rot61_t1 = bitor(bitshift(t1, -61), bitactive_shift_left(t1, 64-61));
        rot39_t1 = bitor(bitshift(t1, -39), bitactive_shift_left(t1, 64-39));
        s(2,:) = bitxor(t1, bitxor(rot61_t1, rot39_t1));
        
        % x2 = x2 ^ (x2 >>> 1) ^ (x2 >>> 6)
        rot1_t2 = bitor(bitshift(t2, -1), bitactive_shift_left(t2, 64-1));
        rot6_t2 = bitor(bitshift(t2, -6), bitactive_shift_left(t2, 64-6));
        s(3,:) = bitxor(t2, bitxor(rot1_t2, rot6_t2));
        
        % x3 = x3 ^ (x3 >>> 10) ^ (x3 >>> 17)
        rot10_t3 = bitor(bitshift(t3, -10), bitactive_shift_left(t3, 64-10));
        rot17_t3 = bitor(bitshift(t3, -17), bitactive_shift_left(t3, 64-17));
        s(4,:) = bitxor(t3, bitxor(rot10_t3, rot17_t3));
        
        % x4 = x4 ^ (x4 >>> 7) ^ (x4 >>> 41)
        rot7_t4 = bitor(bitshift(t4, -7), bitactive_shift_left(t4, 64-7));
        rot41_t4 = bitor(bitshift(t4, -41), bitactive_shift_left(t4, 64-41));
        s(5,:) = bitxor(t4, bitxor(rot7_t4, rot41_t4));
        
        % Invert x2 as per reference implementation
        s(3,:) = bitcmp(s(3,:), 'uint64');
    end
end

function y = bitactive_shift_left(x, n)
    % Manual left shift for uint64 matrix as bitshift(x, 64-n) can be sensitive
    y = bitshift(x, n);
end
