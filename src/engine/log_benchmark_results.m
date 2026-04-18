function log_benchmark_results(results_struct)
    % LOG_BENCHMARK_RESULTS Saves benchmark metrics to a file and displays summary
    % results_struct: Structure containing timing and speedup data
    
    timestamp = datestr(now, 'yyyy-mm-dd_HH-MM-SS');
    filename = sprintf('benchmark_results_%s.log', timestamp);
    
    fid = fopen(filename, 'w');
    fprintf(fid, '--- ASCON-128 Speed Benchmark Results ---\n');
    fprintf(fid, 'Timestamp: %s\n', timestamp);
    fprintf(fid, 'Message Count: %d\n', results_struct.count);
    fprintf(fid, 'Average Fixed Latency (12-round): %.6f ms\n', results_struct.avg_fixed * 1000);
    fprintf(fid, 'Average Adaptive Latency:       %.6f ms\n', results_struct.avg_adaptive * 1000);
    fprintf(fid, 'Overall Speedup Factor:         %.2fx\n', results_struct.speedup);
    fprintf(fid, 'Latency Reduction:              %.2f%%\n', results_struct.reduction_pct);
    fclose(fid);
    
    % Display to console
    fprintf('\n--- Benchmark Summary ---\n');
    fprintf('Total Messages: %d\n', results_struct.count);
    fprintf('Latency Reduction: %.2f%%\n', results_struct.reduction_pct);
    fprintf('Results saved to: %s\n', filename);
end
