function s = ascon_permutation(s, nr)
    % ASCON_PERMUTATION Performs nr rounds of ASCON permutation
    % s: 5x1 uint64 array representing the 320-bit state
    % nr: Number of rounds to perform (12 or 8)
    
    % Failsafe Enforcement: Minimum 8 rounds
    if nr < 8
        error('SECURITY FAILSAFE: ASCON permutation must be at least 8 rounds.');
    end
    
    % Round Constants (RC)
    RC = uint64([0xf0, 0xe1, 0xd2, 0xc3, 0xb4, 0xa5, 0x96, 0x87, 0x78, 0x69, 0x5a, 0x4b]);
    
    % Round indexing depends on nr (12-round uses all, 8-round uses last 8)
    start_idx = 13 - nr;
    
    for i = start_idx:12
        % 1. Addition of Round Constant (into x2)
        s(3) = bitxor(s(3), RC(i));
        
        % 2. Substitution Layer (S-box)
        s(1) = bitxor(s(1), s(5));
        s(5) = bitxor(s(5), s(4));
        s(3) = bitxor(s(3), s(2));
        
        % Temporary variables for non-linear update
        % MATLAB bitcmp needs 'uint64' to signify bit-length
        t0 = bitxor(s(1), bitand(bitcmp(s(2), 'uint64'), s(3)));
        t1 = bitxor(s(2), bitand(bitcmp(s(3), 'uint64'), s(4)));
        t2 = bitxor(s(3), bitand(bitcmp(s(4), 'uint64'), s(5)));
        t3 = bitxor(s(4), bitand(bitcmp(s(5), 'uint64'), s(1)));
        t4 = bitxor(s(5), bitand(bitcmp(s(1), 'uint64'), s(2)));
        
        % Linear transformation (diffusion layer) combined with S-box finalize
        t1 = bitxor(t1, t0);
        t3 = bitxor(t3, t2);
        t0 = bitxor(t0, t4);
        
        % 3. Linear Diffusion Layer
        % x0 = x0 ^ (x0 >>> 19) ^ (x0 >>> 28)
        s(1) = bitxor(t0, bitxor(rotate_right(t0, 19), rotate_right(t0, 28)));
        % x1 = x1 ^ (x1 >>> 61) ^ (x1 >>> 39)
        s(2) = bitxor(t1, bitxor(rotate_right(t1, 61), rotate_right(t1, 39)));
        % x2 = x2 ^ (x2 >>> 1) ^ (x2 >>> 6)
        s(3) = bitxor(t2, bitxor(rotate_right(t2, 1), rotate_right(t2, 6)));
        % x3 = x3 ^ (x3 >>> 10) ^ (x3 >>> 17)
        s(4) = bitxor(t3, bitxor(rotate_right(t3, 10), rotate_right(t3, 17)));
        % x4 = x4 ^ (x4 >>> 7) ^ (x4 >>> 41)
        s(5) = bitxor(t4, bitxor(rotate_right(t4, 7), rotate_right(t4, 41)));
        
        % Invert x2 as per reference implementation
        s(3) = bitcmp(s(3), 'uint64');
    end
end

function y = rotate_right(x, n)
    % ROTATE_RIGHT Efficient 64-bit right rotation
    y = bitor(bitshift(x, -n), bitshift(x, 64-n));
end
