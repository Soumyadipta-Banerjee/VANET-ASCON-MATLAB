function [v, B, P] = telemetry_generator(t, scenario)
    % TELEMETRY_GENERATOR Simulates vehicle telemetry for VANET
    % t: Time vector (seconds)
    % scenario: 'Highway', 'Urban', or 'Emergency'
    
    n = length(t);
    rng(42); % For reproducibility
    
    switch scenario
        case 'Highway'
            % High speed, relatively low buffer, mixed priority
            v = 0.8 + 0.1 * sin(0.1 * t) + 0.05 * randn(1, n); % 80-90% speed
            B = 0.2 + 0.1 * cumsum(rand(1, n) - 0.5); % Floating buffer
            P = double(rand(1, n) > 0.8); % 20% high priority
            
        case 'Urban'
            % Low speed, high buffer usage, high priority messages frequent
            v = 0.3 + 0.2 * sin(0.05 * t) + 0.1 * randn(1, n); % urban speed
            B = 0.6 + 0.3 * rand(1, n); % 60-90% buffer
            P = double(rand(1, n) > 0.5); % 50% high priority
            
        case 'Emergency'
            % High speed (straining), high buffer, critical priority
            v = 0.9 * ones(1, n) + 0.02 * randn(1, n);
            B = 0.8 * ones(1, n) + 0.1 * rand(1, n);
            P = ones(1, n); % All critical
            
        otherwise
            % Default: Random walk
            v = rand(1, n);
            B = rand(1, n);
            P = double(rand(1, n) > 0.5);
    end
    
    % Clamp values to [0, 1]
    v = max(0, min(1, v));
    B = max(0, min(1, B));
end
