function [q, drops, processed, latencies, Ci_out] = attacker_simulation(...
    legit_arrivals, v_norm, is_adaptive, Q_max, T_12, T_8, attack_start, attack_end, f_attack)
    % ATTACKER_SIMULATION Simulates OBU queue dynamics under high-priority DDoS flooding.
    %
    % Inputs:
    %   legit_arrivals : Column vector of legitimate background packet arrivals
    %   v_norm         : Column vector of normalized speeds (0-1)
    %   is_adaptive    : Boolean flag to enable context-aware round scaling
    %   Q_max          : Strict buffer capacity limit (packets)
    %   T_12           : Processing latency of standard 12-round ASCON (ms)
    %   T_8            : Processing latency of failsafe 8-round ASCON (ms)
    %   attack_start   : Timestep where rogue node begins injection
    %   attack_end     : Timestep where rogue node stops injection
    %   f_attack       : Adversarial injection rate (packets/second)
    
    num_steps = length(legit_arrivals);
    
    % Initialize time-series state records
    q = zeros(num_steps, 1);
    drops = zeros(num_steps, 1);
    processed = zeros(num_steps, 1);
    latencies = zeros(num_steps, 1);
    Ci_out = zeros(num_steps, 1);
    
    current_q = 0;
    total_drops = 0;
    
    for t = 1:num_steps
        % 1. Adversarial Injection Logic
        if t >= attack_start && t <= attack_end
            A_attack = f_attack; % Attack packets injected this second
        else
            A_attack = 0;
        end
        
        A_legit = legit_arrivals(t);
        A_total = A_legit + A_attack;
        
        % 2. Calculate Real-Time Threat Metrics for Victim OBU
        % Normalized buffer occupancy B based on current queue size
        B_t = double(current_q) / double(Q_max);
        
        % Mixed traffic priority P (ratio of malicious high-priority packets)
        if A_total > 0
            P_t = double(A_attack) / double(A_total);
        else
            P_t = 0.0;
        end
        
        % 3. Decision Engine Criticality Index Ci(t)
        % Formula: Ci = 0.4*v + 0.4*B + 0.2*P
        Ci_t = (0.4 * v_norm(t)) + (0.4 * B_t) + (0.2 * P_t);
        Ci_out(t) = Ci_t;
        
        % 4. Select Cryptographic Failsafe & Capacity
        if is_adaptive && (Ci_t >= 0.7)
            T_proc = T_8;
        else
            T_proc = T_12;
        end
        
        % Throughput capacity (max packets processed in 1000 ms)
        capacity = floor(1000.0 / T_proc);
        
        % 5. Continuous-Processing Queue Transition Equations
        q_temp = current_q + A_total;
        
        % Process packets up to throughput capacity
        processed_t = min(q_temp, capacity);
        processed(t) = processed_t;
        
        % Remaining un-processed packets in queue
        q_remaining = q_temp - processed_t;
        
        % Apply strict RAM buffer limit Q_max
        if q_remaining > Q_max
            drops_t = q_remaining - Q_max;
            current_q = Q_max;
        else
            drops_t = 0;
            current_q = q_remaining;
        end
        
        % 6. Log Simulation Time-Step Results
        total_drops = total_drops + drops_t;
        drops(t) = total_drops;
        q(t) = current_q;
        latencies(t) = T_proc;
    end
end
