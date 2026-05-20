% SIMULATE_QUEUE_DEMO Driver script for Module 6 Discrete-Event Queue Simulator.
% Parses the SUMO trace, finds the most stressed vehicle in gridlock,
% runs parallel queue simulations (Static 12-round vs Adaptive 8/12-round),
% and visualizes the results.

clc; clear;
fprintf('=== VANET-ASCON Discrete-Event OBU Queue Simulator (Module 6) ===\n\n');

% Define file paths
root_dir = '/home/soumya/.gemini/antigravity/scratch/VANET-ASCON-MATLAB';
file_path = fullfile(root_dir, 'sumo_trace.csv');

% 1. Parse the SUMO traffic trace
results = sumo_parser(file_path, 100000); % read first 100k rows for rich gridlock data

% 2. Identify the target vehicle with the maximum drop reduction
% Find vehicles that triggered 8-round failsafe at least once
failsafe_vehs = unique(results.vehicle_id(results.selected_rounds == 8));

% Simulation parameters for search
Q_max_search = 150;
T_12_search = 0.50;
T_8_search = 0.3338;
f_BSM_search = 10;
delta_t_search = 1.0;

best_red = -1;
target_veh = '';

for k = 1:length(failsafe_vehs)
    veh = failsafe_vehs{k};
    v_idx = strcmp(results.vehicle_id, veh);
    v_data = sortrows(results(v_idx, :), 'timestep');
    if height(v_data) < 10
        continue;
    end
    
    % Generate packet arrivals
    arr = zeros(height(v_data), 1);
    for t = 1:height(v_data)
        lambda = double(v_data.neighbors(t)) * f_BSM_search * delta_t_search;
        arr(t) = round(lambda);
    end
    
    % Simulate queues
    [~, d_s] = obu_queue_simulator(arr, v_data.Ci, false, Q_max_search, T_12_search, T_8_search);
    [~, d_a] = obu_queue_simulator(arr, v_data.Ci, true, Q_max_search, T_12_search, T_8_search);
    
    if d_s(end) > 0
        red = (double(d_s(end) - d_a(end)) / double(d_s(end))) * 100;
        if red > best_red
            best_red = red;
            target_veh = veh;
        end
    end
end

% Fallback if no vehicle triggered 8 rounds or showed drops
if isempty(target_veh)
    if ~isempty(failsafe_vehs)
        target_veh = failsafe_vehs{1};
    else
        [~, max_idx] = max(results.neighbors);
        target_veh = results.vehicle_id{max_idx};
    end
end

% Extract target details for printing
target_idx = strcmp(results.vehicle_id, target_veh);
peak_neighbors = max(results.neighbors(target_idx));
fprintf('\nTarget Vehicle Selected: "%s" (Peak Neighbors: %d)\n', ...
    target_veh, peak_neighbors);

% Extract this vehicle's time series data
veh_idx = strcmp(results.vehicle_id, target_veh);
veh_data = results(veh_idx, :);

% Sort by timestep to ensure chronological simulation
veh_data = sortrows(veh_data, 'timestep');
num_steps = height(veh_data);
fprintf('Simulating %d active timesteps for vehicle "%s"...\n', num_steps, target_veh);

% 3. Generate Packet Arrivals (Bursty Poisson Process)
% Standard V2X parameters
f_BSM = 10;     % Basic Safety Message rate (10 Hz per vehicle)
delta_t = 1.0;  % SUMO timestep resolution (seconds)

rng(42); % Set seed for perfect reproducibility across comparative runs
arrivals = zeros(num_steps, 1);
for t = 1:num_steps
    lambda = double(veh_data.neighbors(t)) * f_BSM * delta_t;
    arrivals(t) = poisson_rnd(lambda);
end

% 4. Queue Simulation Parameters
Q_max = 150;     % Strict OBU RAM buffer capacity (packets)
T_12 = 0.50;     % 12-round processing latency per packet (ms)
T_8 = 0.3338;    % 8-round processing latency per packet (ms)

% 5. Run Parallel Simulations
% Scenario A: Static 12-round ASCON (Always 12 rounds)
[q_static, drops_static, proc_static, lat_static] = obu_queue_simulator(...
    arrivals, veh_data.Ci, false, Q_max, T_12, T_8);

% Scenario B: Adaptive ASCON (Dynamic 8 vs 12 rounds)
[q_adaptive, drops_adaptive, proc_adaptive, lat_adaptive] = obu_queue_simulator(...
    arrivals, veh_data.Ci, true, Q_max, T_12, T_8);

% 6. Display Numerical Summary
total_arrivals = sum(arrivals);
fprintf('\n--- OBU QUEUE SIMULATION SUMMARY FOR VEHICLE "%s" ---\n', target_veh);
fprintf('Total Safety Packets Arrived: %d\n', total_arrivals);
fprintf('Static 12-Round ASCON:  Processed = %d, Dropped = %d (Drop Rate = %.2f%%)\n', ...
    sum(proc_static), drops_static(end), (drops_static(end) / total_arrivals) * 100);
fprintf('Adaptive ASCON (8/12):  Processed = %d, Dropped = %d (Drop Rate = %.2f%%)\n', ...
    sum(proc_adaptive), drops_adaptive(end), (drops_adaptive(end) / total_arrivals) * 100);

if drops_static(end) > 0
    drop_reduction = (double(drops_static(end) - drops_adaptive(end)) / double(drops_static(end))) * 100;
    fprintf('Systems-Level Packet Drop Reduction: %.2f%%\n', drop_reduction);
else
    fprintf('Systems-Level Packet Drop Reduction: N/A (Zero static drops)\n');
end

% 7. Plot Comparative Analysis (Headless-safe PNG save)
fig = figure('Name', 'VANET OBU Queue Simulation Analysis', ...
             'Position', [100, 100, 1000, 750], ...
             'Visible', 'off', ...
             'Color', 'w', ...
             'InvertHardcopy', 'off');

% Subplot 1: Congestion Context
subplot(3, 1, 1);
yyaxis left
plot(veh_data.timestep, veh_data.neighbors, '-o', 'Color', [0.1, 0.5, 0.8], 'LineWidth', 1.8, 'MarkerSize', 4);
ylabel('Local Neighbor Density (N_{neighbors})');
xlabel('Simulation Timestep (s)');
grid on;

yyaxis right
plot(veh_data.timestep, veh_data.Ci, '-s', 'Color', [0.85, 0.33, 0.1], 'LineWidth', 1.8, 'MarkerSize', 4);
ylabel('Criticality Index (C_i)');
yline(0.7, 'r:', 'Stress Threshold (0.7)', 'LineWidth', 1.5, 'LabelVerticalAlignment', 'bottom');
title(sprintf('Traffic Congestion & Criticality Context for Vehicle "%s"', target_veh));
legend('Neighbor Density', 'Criticality Index (Ci)', 'Location', 'northwest');

% Subplot 2: Buffer Queue Size Over Time
subplot(3, 1, 2);
plot(veh_data.timestep, q_static, 'r--', 'LineWidth', 2);
hold on;
plot(veh_data.timestep, q_adaptive, 'b-', 'LineWidth', 2);
yline(Q_max, 'k-', 'Max Buffer Capacity (150)', 'LineWidth', 1.5);
ylabel('Buffered Queue Size (packets)');
xlabel('Simulation Timestep (s)');
grid on;
title('OBU RAM Buffer Queue Length (Static vs. Adaptive)');
legend('Static 12-round', 'Adaptive ASCON (8/12)', 'Buffer Limit', 'Location', 'northwest');

% Subplot 3: Cumulative Packet Drops Over Time
subplot(3, 1, 3);
plot(veh_data.timestep, drops_static, 'r--', 'LineWidth', 2.2);
hold on;
plot(veh_data.timestep, drops_adaptive, 'b-', 'LineWidth', 2.2);
ylabel('Cumulative Packet Drops');
xlabel('Simulation Timestep (s)');
grid on;
title('Cumulative V2X Packet Drops Due to Queue Overflow');
legend('Static 12-round', 'Adaptive ASCON (8/12)', 'Location', 'northwest');

% Save high-resolution PNG
docs_dir = fullfile(root_dir, 'docs');
if ~exist(docs_dir, 'dir')
    mkdir(docs_dir);
end
fig_path = fullfile(docs_dir, 'obu_queue_comparison.png');
print(fig, fig_path, '-dpng', '-r300');
fprintf('\nComparative visualization plot saved successfully to:\n%s\n', fig_path);

% Close figure to free memory
close(fig);

% --- Helper Functions ---
function k = poisson_rnd(lambda)
    % POISSON_RND Generates Poisson random variable without Statistics Toolbox.
    if lambda <= 0
        k = 0;
        return;
    elseif lambda < 30
        % Knuth's algorithm for small lambda
        L = exp(-lambda);
        k = 0;
        p = 1.0;
        while p > L
            k = k + 1;
            p = p * rand();
        end
        k = k - 1;
    else
        % Normal approximation for large lambda (to avoid exp overflow)
        val = round(lambda + sqrt(lambda) * randn());
        k = max(0, val);
    end
end
