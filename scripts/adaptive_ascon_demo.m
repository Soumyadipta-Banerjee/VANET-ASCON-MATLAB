% ADAPTIVE_ASCON_DEMO Simulation script for Module 2
% Demonstrates real-time round scaling based on network criticality.

clc; clear;
fprintf('--- VANET Adaptive ASCON Simulation (Module 2) ---\n');

% 1. Setup Simulation Time
t = 0:1:100; % 100 seconds
n = length(t);

% 2. Generate Telemetry (Highway Scenario)
[v_trace, B_trace, P_trace] = telemetry_generator(t, 'Highway');

% 3. Run Decision Engine
Ci_trace = zeros(1, n);
rounds_trace = zeros(1, n);

for i = 1:n
    [Ci, r] = calculate_criticality(v_trace(i), B_trace(i), P_trace(i));
    Ci_trace(i) = Ci;
    rounds_trace(i) = r;
end

% 4. Visualization
figure('Name', 'VANET Adaptive Cryptographic Controller');
subplot(2,1,1);
plot(t, v_trace, 'b', 'LineWidth', 1.5); hold on;
plot(t, B_trace, 'r', 'LineWidth', 1.5);
plot(t, P_trace, 'g--', 'LineWidth', 1);
yline(0.7, 'k:', 'Stress Threshold (0.7)', 'LabelVerticalAlignment', 'bottom');
title('Vehicle Telemetry (Normalized)');
legend('Speed (v)', 'Buffer (B)', 'Priority (P)');
grid on;

subplot(2,1,2);
stairs(t, rounds_trace, 'm', 'LineWidth', 2);
ylim([6, 14]);
title('Adaptive ASCON Round Selection');
ylabel('Permutation Rounds');
xlabel('Time (s)');
grid on;

fprintf('Simulation Complete. Round selection adaptively toggled between 12 and 8.\n');
