% BENCHMARK_ADAPTIVE_ASCON Performance analysis for Module 3
% Compares static 12-round vs adaptive scaling over 10,000 messages.

clc; clear;
setup_project; % Ensure paths are loaded

fprintf('--- Starting Speed Benchmark (10,000 messages) ---\n');

% 1. Configuration
count = 10000;
t = 1:count;

% Generate telemetry (Mixture of scenarios to stress test scaling)
% First 5000: Highway (Mostly 12), Last 5000: Urban (Frequent 8)
[v1, B1, P1] = telemetry_generator(1:5000, 'Highway');
[v2, B2, P2] = telemetry_generator(1:5000, 'Urban');
v = [v1, v2]; B = [B1, B2]; P = [P1, P2];

% 2. Pre-generate common test data (avoiding generation overhead during timing)
% Generate 10,000 random keys/nonces using uint32 range to stay within randi limits, then cast to uint64
keys = uint64(randi([0, intmax('uint32')], count, 2));
nonces = uint64(randi([0, intmax('uint32')], count, 2));
ad = []; pt = uint64([0x0123456789ABCDEF]); % Single block payload

% 3. Benchmark Case A: Fixed 12-round (Baseline)
fprintf('Running baseline (Fixed 12-round)... ');
tic;
for i = 1:count
    [~, ~] = ascon_aead(keys(i,:), nonces(i,:), ad, pt, 12);
end
time_fixed = toc;
avg_fixed = time_fixed / count;
fprintf('DONE (%.4f sec)\n', time_fixed);

% 4. Benchmark Case B: Adaptive Round Scaling
fprintf('Running adaptive mechanism... ');
tic;
for i = 1:count
    % Decision Engine overhead included in timing
    [Ci, r] = calculate_criticality(v(i), B(i), P(i));
    [~, ~] = ascon_aead(keys(i,:), nonces(i,:), ad, pt, r);
end
time_adaptive = toc;
avg_adaptive = time_adaptive / count;
fprintf('DONE (%.4f sec)\n', time_adaptive);

% 5. Data Analysis
reduction_pct = (1 - (time_adaptive / time_fixed)) * 100;
speedup = time_fixed / time_adaptive;

results.count = count;
results.avg_fixed = avg_fixed;
results.avg_adaptive = avg_adaptive;
results.speedup = speedup;
results.reduction_pct = reduction_pct;

log_benchmark_results(results);
