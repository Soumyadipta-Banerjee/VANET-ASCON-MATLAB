% PARSE_TRACE_DEMO Simulation script for Module 5
% Demonstrates parsing real SUMO traffic data, localized gridlock neighborhood
% physics, and triggering the 8-round vs 12-round ASCON adaptive failsafe.

clc; clear;
fprintf('=== VANET-ASCON Real Traffic Trace Parser & Failsafe Controller ===\n\n');

% Define file paths
root_dir = '/home/soumya/.gemini/antigravity/scratch/VANET-ASCON-MATLAB';
file_path = fullfile(root_dir, 'sumo_trace.csv');

% Run the SUMO trace parser (limit to first 100,000 rows for instant execution)
results = sumo_parser(file_path, 100000);

% Print the telemetry summary table
fprintf('\n--- VEHICULAR TELEMETRY & ADAPTIVE CRYPTO DECISIONS SUMMARY ---\n');
disp(results(:, {'timestep', 'vehicle_id', 'vehicle_type', 'vehicle_speed', 'neighbors', 'v_norm', 'B', 'P', 'Ci', 'selected_rounds'}));

% Plot gridlock topology and cryptographic scheduling decisions
figure('Name', 'VANET ASCON Systems-Level Gridlock Controller', 'Position', [100, 100, 900, 600]);

% Subplot 1: Spatial Gridlock Neighborhood
subplot(2, 1, 1);
unique_ids = unique(results.vehicle_id);
colors = lines(length(unique_ids));
for i = 1:length(unique_ids)
    idx_veh = strcmp(results.vehicle_id, unique_ids{i});
    scatter(results.vehicle_x(idx_veh), results.vehicle_y(idx_veh), 60, colors(i, :), 'filled', 'DisplayName', unique_ids{i});
    hold on;
end
% Draw a communication neighborhood circle of Rc = 300m for motorcycle0 at t=0
idx_m0 = find(strcmp(results.vehicle_id, 'motorcycle0') & results.timestep == 0.00);
if ~isempty(idx_m0)
    theta = linspace(0, 2*pi, 100);
    x_circle = results.vehicle_x(idx_m0) + 300 * cos(theta);
    y_circle = results.vehicle_y(idx_m0) + 300 * sin(theta);
    plot(x_circle, y_circle, 'r--', 'LineWidth', 1.2);
    plot(results.vehicle_x(idx_m0), results.vehicle_y(idx_m0), 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 8);
    text(results.vehicle_x(idx_m0)+15, results.vehicle_y(idx_m0)+15, 'motorcycle0 (Center)', 'Color', 'r', 'FontWeight', 'bold');
end
title('Spatial Vehicle Topology & Communication Neighborhood (Rc = 300m, t = 0s)');
xlabel('X Position (meters)');
ylabel('Y Position (meters)');
grid on;
axis equal;

% Subplot 2: Criticality index vs Adaptive rounds
subplot(2, 1, 2);
[unique_times, ~, time_idx] = unique(results.timestep);
avg_Ci = accumarray(time_idx, results.Ci, [], @mean);
min_rounds = accumarray(time_idx, results.selected_rounds, [], @min);

yyaxis left
plot(unique_times, avg_Ci, '-o', 'LineWidth', 2, 'MarkerFaceColor', 'b');
ylabel('Mean Criticality Index (Ci)');
ylim([0 1]);
hold on;
yline(0.7, 'r:', 'Stress Threshold (0.7)', 'LineWidth', 1.5, 'LabelVerticalAlignment', 'bottom');

yyaxis right
stairs(unique_times, min_rounds, '-s', 'LineWidth', 2, 'MarkerFaceColor', 'm');
ylabel('Triggered ASCON Rounds (8 vs 12)');
ylim([6 14]);

title('Localized stress evolution & adaptive cryptosystem response');
xlabel('Simulation Timestep (seconds)');
grid on;

fprintf('\nDemo script finished successfully. Plotted vehicular topology and cryptographic responses.\n');
