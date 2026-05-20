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
fig = figure('Name', 'VANET Adaptive Cryptographic Controller', ...
             'Position', [100, 100, 1000, 750], ...
             'Visible', 'off', ...
             'Color', 'w', ...
             'InvertHardcopy', 'off');

subplot(2,1,1);
plot(t, v_trace, 'b', 'LineWidth', 2); hold on;
plot(t, B_trace, 'r', 'LineWidth', 2);
title('Real-Time Vehicle Telemetry', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Value (Normalized)', 'FontSize', 11, 'FontWeight', 'bold');
legend('Vehicle Speed', 'Network Buffer', 'Location', 'northeast');
grid on;

subplot(2,1,2);
stairs(t, rounds_trace, 'm', 'LineWidth', 2.5);
ylim([6, 14]);
title('Adaptive ASCON Round Selection', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Encryption Rounds', 'FontSize', 11, 'FontWeight', 'bold');
xlabel('Time (s)', 'FontSize', 11, 'FontWeight', 'bold');
grid on;

% Save high-resolution PNG
root_dir = '/home/soumya/.gemini/antigravity/scratch/VANET-ASCON-MATLAB';
docs_dir = fullfile(root_dir, 'docs');
if ~exist(docs_dir, 'dir')
    mkdir(docs_dir);
end
fig_path = fullfile(docs_dir, 'adaptive_ascon_demo.png');
apply_white_theme(fig);
print(fig, fig_path, '-dpng', '-r300');
fprintf('\nSimulation Complete. Round selection adaptively toggled between 12 and 8.\n');
fprintf('Adaptive ASCON demo plot saved successfully to:\n%s\n', fig_path);

close(fig);

% --- Helper Functions ---
function apply_white_theme(fig)
    set(fig, 'Color', 'w');
    set(fig, 'InvertHardcopy', 'off');
    
    % Find all axes objects
    ax_handles = findall(fig, 'type', 'axes');
    for i = 1:length(ax_handles)
        ax = ax_handles(i);
        set(ax, 'Color', 'w');
        set(ax, 'XColor', 'k');
        
        % Check YAxis color properties for yyaxis
        if isprop(ax, 'YAxis') && length(ax.YAxis) >= 2
            for y_idx = 1:length(ax.YAxis)
                if isequal(ax.YAxis(y_idx).Color, [1, 1, 1]) || sum(ax.YAxis(y_idx).Color) > 2.7
                    ax.YAxis(y_idx).Color = 'k';
                end
            end
        else
            set(ax, 'YColor', 'k');
        end
        
        % Force labels and titles to black
        if ~isempty(ax.Title)
            ax.Title.Color = 'k';
        end
        if ~isempty(ax.XLabel)
            ax.XLabel.Color = 'k';
        end
        if ~isempty(ax.YLabel)
            ax.YLabel.Color = 'k';
        end
        
        % Force grid color to light grey
        set(ax, 'GridColor', [0.7, 0.7, 0.7]);
        set(ax, 'GridAlpha', 0.6);
    end
    
    % Find all legend objects
    leg_handles = findall(fig, 'type', 'legend');
    for i = 1:length(leg_handles)
        leg = leg_handles(i);
        set(leg, 'Color', 'w');
        set(leg, 'TextColor', 'k');
        set(leg, 'EdgeColor', [0.8, 0.8, 0.8]);
    end
end
