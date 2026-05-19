function [q_len, cumulative_drops, processed, latency_series] = obu_queue_simulator(arrivals, Ci, is_adaptive, Q_max, T_12, T_8)
    % OBU_QUEUE_SIMULATOR Simulates time-stepped OBU RAM buffer queue dynamics.
    %
    % Inputs:
    %   arrivals         - Vector of packet arrival counts per timestep
    %   Ci               - Vector of Criticality Index values per timestep
    %   is_adaptive      - Boolean flag (true = adaptive 8/12, false = static 12)
    %   Q_max            - Strict maximum queue size (RAM buffer limit)
    %   T_12             - Processing time per packet for 12-round mode (ms)
    %   T_8              - Processing time per packet for 8-round mode (ms)
    %
    % Outputs:
    %   q_len            - Queue length time-series
    %   cumulative_drops - Cumulative packet drops time-series
    %   processed        - Processed packet count time-series
    %   latency_series   - Selected processing latency per packet (ms) time-series

    num_steps = length(arrivals);
    
    % Preallocate outputs
    q_len = zeros(num_steps, 1);
    cumulative_drops = zeros(num_steps, 1);
    processed = zeros(num_steps, 1);
    latency_series = zeros(num_steps, 1);
    
    current_q = 0;
    total_drops = 0;
    
    for t = 1:num_steps
        % 1. Packet arrivals in this timestep
        A_t = arrivals(t);
        
        % 2. Calculate processing capacity (packets per second)
        % Timestep duration is 1 second (1000 ms)
        if is_adaptive && (Ci(t) >= 0.7)
            T_proc = T_8; % 8-round mode
        else
            T_proc = T_12; % 12-round mode
        end
        
        % Throughput capacity (max packets that can be processed in 1000 ms)
        capacity = floor(1000.0 / T_proc);
        
        % 3. Combine current queue with new packet arrivals
        q_temp = current_q + A_t;
        
        % 4. Process packets up to OBU throughput capacity in this timestep
        processed_t = min(q_temp, capacity);
        processed(t) = processed_t;
        
        % 5. Remaining packets that need to be buffered
        q_remaining = q_temp - processed_t;
        
        % 6. Apply strict OBU RAM buffer limit (drop if queue exceeds Q_max)
        if q_remaining > Q_max
            drops_t = q_remaining - Q_max;
            current_q = Q_max;
        else
            drops_t = 0;
            current_q = q_remaining;
        end
        
        total_drops = total_drops + drops_t;
        cumulative_drops(t) = total_drops;
        q_len(t) = current_q;
        
        % 7. Record processing latency for this timestep
        latency_series(t) = T_proc;
    end
end
