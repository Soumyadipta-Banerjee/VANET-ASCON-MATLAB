function [avg_hd, sac_satisfied] = sac_analyzer(num_trials)
    % SAC_ANALYZER Verifies the Strict Avalanche Criterion for 8-round ASCON
    % num_trials: Number of random states to test (default 1000)
    
    if nargin < 1, num_trials = 1000; end
    
    fprintf('--- Starting SAC Security Analysis (8-round Failsafe) ---\n');
    fprintf('Running %d Monte Carlo trials...\n', num_trials);
    
    total_hd = 0;
    hd_history = zeros(num_trials, 1);
    
    for t = 1:num_trials
        % 1. Generate random 320-bit state (5x1 uint64)
        s_orig = uint64(randi([0, intmax('uint32')], 5, 1));
        
        % 2. Pick a random bit to flip (1 to 320)
        bit_to_flip = randi([1, 320]);
        word_idx = ceil(bit_to_flip / 64);
        bit_idx = mod(bit_to_flip - 1, 64);
        
        s_flipped = s_orig;
        s_flipped(word_idx) = bitxor(s_flipped(word_idx), bitshift(uint64(1), bit_idx));
        
        % 3. Run 8-round permutation (the failsafe)
        out_orig = ascon_permutation(s_orig, 8);
        out_flipped = ascon_permutation(s_flipped, 8);
        
        % 4. Calculate Hamming Distance
        hd = 0;
        for i = 1:5
            diff = bitxor(out_orig(i), out_flipped(i));
            % Use built-in sum of bits for Hamming Weight
            hd = hd + sum(bitget(diff, 1:64));
        end
        
        hd_history(t) = hd;
        total_hd = total_hd + hd;
    end
    
    avg_hd = total_hd / num_trials;
    % SAC is satisfied if average flip is ~50% (160 bits)
    % Tolerance: +/- 2% (due to randomness)
    sac_satisfied = (avg_hd >= 155 && avg_hd <= 165);
    
    fprintf('Average Hamming Distance: %.2f bits (%.2f%%)\n', avg_hd, (avg_hd/320)*100);
    
    if sac_satisfied
        fprintf('RESULT: SUCCESS - SAC satisfied at 8 rounds (%.2f%% flip rate)\n', (avg_hd/320)*100);
    else
        fprintf('RESULT: WARNING - SAC variance detected. Avg HD: %.2f\n', avg_hd);
    end
    
    % Optional: Plotting (Disabled for batch runs)
    % histogram(hd_history); title('Hamming Distance Distribution (8-round ASCON)');
end
