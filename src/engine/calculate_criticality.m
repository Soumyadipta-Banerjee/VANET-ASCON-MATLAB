function [Ci, rounds] = calculate_criticality(v, B, P)
    % CALCULATE_CRITICALITY Computes the Criticality Index and selects ASCON rounds
    % v: Normalized speed (0-1)
    % B: Normalized buffer occupancy (0-1)
    % P: Message priority (0 or 1)
    
    % Weighting Factors (Architecture Rule)
    w1 = 0.4; % Speed weight
    w2 = 0.4; % Buffer weight
    w3 = 0.2; % Priority weight
    
    % Formula implementation
    Ci = (w1 * v) + (w2 * B) + (w3 * P);
    
    % Decision Logic (Threshold = 0.7)
    if Ci >= 0.7
        rounds = 8; % High stress -> Low latency mode
    else
        rounds = 12; % Low stress -> High security mode
    end
end
