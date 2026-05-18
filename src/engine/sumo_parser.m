function results = sumo_parser(file_path, max_rows)
    % SUMO_PARSER Reads a SUMO trace CSV, processes vehicular gridlock physics,
    % and triggers adaptive 8-round vs 12-round ASCON decisions.
    %
    % Inputs:
    %   file_path - Absolute or relative path to sumo_trace.csv
    %   max_rows  - (Optional) Max number of rows to parse for speed/memory savings
    %
    % Outputs:
    %   results - Table containing processed telemetry and ASCON round decisions
    
    if nargin < 2
        max_rows = inf;
    end
    
    fprintf('--- SUMO Trace Parser (Module 5) Running ---\n');
    
    % Read table with Semicolon delimiter (user requirement)
    opts = detectImportOptions(file_path, 'Delimiter', ';');
    opts.VariableTypes{strcmp(opts.VariableNames, 'vehicle_id')} = 'char';
    opts.VariableTypes{strcmp(opts.VariableNames, 'vehicle_type')} = 'char';
    opts.VariableTypes{strcmp(opts.VariableNames, 'vehicle_lane')} = 'char';
    
    if isfinite(max_rows)
        opts.DataLines = [2, max_rows + 1];
        trace_data = readtable(file_path, opts);
        fprintf('Performance Optimization: Limited parsing to first %d rows.\n', max_rows);
    else
        trace_data = readtable(file_path, opts);
    end
    
    % Support both 'timestep' and 'timestep_time' column names (robust to different SUMO exporters)
    if ismember('timestep_time', trace_data.Properties.VariableNames)
        trace_data.Properties.VariableNames{strcmp(trace_data.Properties.VariableNames, 'timestep_time')} = 'timestep';
    end
    
    % Constants
    Rc = 300.0;     % Communications range (meters)
    V_max = 20.0;   % Max normalization speed (m/s, for 72 km/h urban limit)
    
    % Find unique timesteps
    unique_times = unique(trace_data.timestep);
    num_rows = height(trace_data);
    
    % Initialize parsed output arrays
    neighbors = zeros(num_rows, 1);
    v_norm = zeros(num_rows, 1);
    B = zeros(num_rows, 1);
    P = zeros(num_rows, 1);
    Ci = zeros(num_rows, 1);
    selected_rounds = zeros(num_rows, 1);
    
    % Process timestep by timestep to isolate localized gridlock physics
    for t_idx = 1:length(unique_times)
        t = unique_times(t_idx);
        idx = find(trace_data.timestep == t);
        
        % Number of vehicles active in this timestep
        N = length(idx);
        if N == 0, continue; end
        
        % Extract positions and speeds
        X = trace_data.vehicle_x(idx);
        Y = trace_data.vehicle_y(idx);
        speeds = trace_data.vehicle_speed(idx);
        types = trace_data.vehicle_type(idx);
        
        % Vectorized Pairwise Distance Computation (user requirement)
        % Using X-X' and Y-Y' broadcast matrices
        dx = X - X';
        dy = Y - Y';
        D = sqrt(dx.^2 + dy.^2);
        
        % Compute neighborhood size (distance <= Rc, excluding self-distance = 0)
        % For N = 1, neighbors is 0
        if N > 1
            node_neighbors = sum(D <= Rc, 2) - 1;
        else
            node_neighbors = 0;
        end
        
        % Model Gridlock Buffer Occupancy B = min(N_neighbors/10, 1.0)
        node_B = min(double(node_neighbors) / 10.0, 1.0);
        
        % Speed Normalization v = min(speed/V_max, 1.0)
        node_v = min(speeds / V_max, 1.0);
        
        % Map Priority P based on vehicle types:
        % trucks are heavy infrastructure nodes (Priority=1), others are standard (Priority=0)
        node_P = zeros(N, 1);
        for i = 1:N
            if contains(types{i}, 'truck')
                node_P(i) = 1.0;
            else
                node_P(i) = 0.0;
            end
        end
        
        % Calculate Criticality Index and Trigger Rounds
        node_Ci = zeros(N, 1);
        node_rounds = zeros(N, 1);
        for i = 1:N
            [node_Ci(i), node_rounds(i)] = calculate_criticality(node_v(i), node_B(i), node_P(i));
        end
        
        % Store back into arrays
        neighbors(idx) = node_neighbors;
        v_norm(idx) = node_v;
        B(idx) = node_B;
        P(idx) = node_P;
        Ci(idx) = node_Ci;
        selected_rounds(idx) = node_rounds;
    end
    
    % Assemble final results table
    results = trace_data;
    results.neighbors = neighbors;
    results.v_norm = v_norm;
    results.B = B;
    results.P = P;
    results.Ci = Ci;
    results.selected_rounds = selected_rounds;
    
    fprintf('Processed %d vehicular entries across %d unique timesteps.\n', num_rows, length(unique_times));
    fprintf('--- SUMO Trace Processing Complete ---\n');
end
