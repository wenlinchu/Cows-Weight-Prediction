%% Animal Weight Prediction Model Evaluation Script
% Evaluates the performance of FNN (Feedforward Neural Network) 
% and GPR (Gaussian Process Regression) models for predicting cattle weight
% using different body region measurements.
%
% MATLAB Version: 2025a
% 
% Description:
% - Loads pre-trained FNN and GPR models
% - Tests models on different body regions (Dorsal, Hips, Side)
% - Compares model predictions with farm weight estimations

clc; clear; close all;

%% Configuration Parameters
% Define body region to analyze (1: Dorsal, 2: Hips, 3: Side)
REGION_INDEX = 1;

% Define animal ID for analysis
% Available options: cid111, cid514, cid603, cid660, cid700
CATTLE_ID = "cid700"; 

% Define body region names and corresponding data fields
BODY_REGIONS = {"Dorsal-region", "Hips-region", "Side-region"};
DATA_FIELDS = {"sn299_Dorsalregion", "sn729_Hips", "sn003_Side"};

%% Load Pre-trained Models and Test Data
try
    % Load trained machine learning models
    load("Model\FNNmodel.mat"); % FNN model with normalization parameters
    load("Model\GPRmodel.mat"); % GPR model
    
    % Load test data and interpolate missing values
    load("Dataset.mat", 'tmpData');
    alldata = interpolateStructFields(tmpData, 1);
    
    fprintf('✓ Successfully loaded models and test data\n');
catch ME
    error('Failed to load required files: %s\n', ME.message);
end

%% Data Preparation
% Select body region based on configuration
selected_region = BODY_REGIONS{REGION_INDEX};
selected_field = DATA_FIELDS{REGION_INDEX};

% Extract data for specified animal and body region
animal_data = alldata.(CATTLE_ID).(selected_field);
data_matrix = table2array(struct2table(animal_data));

% Separate features and targets
X = data_matrix(:, 1:5);  % Input features (body measurements)
Y = data_matrix(:, 6);    % Ground truth weight (kg)
E = data_matrix(:, 7);    % Farm estimated weight (kg)

fprintf('✓ Data prepared for %s - %s\n', CATTLE_ID, selected_region);
fprintf('  Number of samples: %d\n', length(Y));
fprintf('  Number of features: %d\n', size(X, 2));

%% Define Evaluation Metrics
% Standard regression evaluation metrics
mse = @(y_true, y_pred) mean((y_true - y_pred).^2);
rmse = @(y_true, y_pred) sqrt(mse(y_true, y_pred));
mae = @(y_true, y_pred) mean(abs(y_true - y_pred));
mape = @(y_true, y_pred) mean(abs((y_true - y_pred) ./ y_true)) * 100;

%% FNN Model Prediction
% Standardize input features using pre-computed parameters
X_standardized = (X - global_mu) ./ global_sigma;
X_standardized = single(X_standardized);  % Convert to single precision

% Generate predictions using FNN model
FNN_predictions = predict(FNNmodel, X_standardized);

fprintf('✓ FNN predictions completed\n');

%% GPR Model Prediction
% Generate predictions using GPR model (no standardization needed)
GPR_predictions = predict(gprModel, X);

fprintf('✓ GPR predictions completed\n');

%% Data Visualization Setup
week_numbers = 1:length(Y);
all_data = [Y; FNN_predictions; GPR_predictions; E];

% Calculate data range for plot scaling
[max_values, ~] = max(all_data, [], 1);
[min_values, ~] = min(all_data, [], 1);

%% Generate Prediction Results Plot
fig1 = figure;

% Create highlighted test region background
hold on;
test_start = 10;
test_end = 16;
fill([test_start test_end test_end test_start], ...
     [min_values-150 min_values-150 max_values+50 max_values+50], ...
     [0.6350 0.0780 0.1840], 'EdgeColor', 'none', 'FaceAlpha', 0.1);

% Plot prediction curves with distinct styles
plot(week_numbers, Y, 'gpentagram-', 'LineWidth', 1.5, 'MarkerFaceColor', 'w', ...
     'DisplayName', 'Real weight');
plot(week_numbers, FNN_predictions, 'bo-', 'LineWidth', 1.5, 'MarkerFaceColor', 'auto', ...
     'DisplayName', 'FNN Prediction');
plot(week_numbers, GPR_predictions, 'co-', 'LineWidth', 1.5, 'MarkerFaceColor', 'auto', ...
     'DisplayName', 'GPR Prediction');
plot(week_numbers, E, 'm^-', 'LineWidth', 1.5, 'MarkerFaceColor', 'auto', ...
     'DisplayName', 'Farm Estimation');

% Configure plot appearance
xlabel('Week Number', 'FontName', 'Times New Roman', 'FontSize', 14);
ylabel('Weight (kg)', 'FontName', 'Times New Roman', 'FontSize', 14);
title(sprintf('%s %s Weight Prediction Results', CATTLE_ID, selected_region), ...
      'FontName', 'Times New Roman', 'FontSize', 16, 'FontWeight', 'bold');

% Set legend and axis limits
legend({'Test Period', 'Ground Truth', 'FNN Prediction', 'GPR Prediction', 'Farm Estimation'}, ...
       'Location', 'best', 'FontSize', 14, 'FontName', 'Times New Roman');
xlim([1, length(Y)]);
ylim([min_values-150, max_values+50]);

grid on;
hold off;
theme(fig1, "light"); % MATLAB Version: 2025a

% Save prediction plot
output_dir = sprintf('testResults\\%s', CATTLE_ID);
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end
saveas(gcf, sprintf('%s\\%s_%s_Prediction_Results.svg', output_dir, CATTLE_ID, selected_region));

fprintf('✓ Prediction results plot saved\n');

%% Calculate Performance Metrics
% Define test data range (weeks 10 onwards)
test_range = 10:length(Y);

% Extract test data
Y_test = Y(test_range);
FNN_test = FNN_predictions(test_range);
GPR_test = GPR_predictions(test_range);
E_test = E(test_range);

% Calculate FNN model metrics
FNN_mse = mse(Y_test, FNN_test);
FNN_rmse = rmse(Y_test, FNN_test);
FNN_mae = mae(Y_test, FNN_test);
FNN_mape = mape(Y_test, FNN_test);

% Calculate GPR model metrics
GPR_mse = mse(Y_test, GPR_test);
GPR_rmse = rmse(Y_test, GPR_test);
GPR_mae = mae(Y_test, GPR_test);
GPR_mape = mape(Y_test, GPR_test);

% Calculate farm estimation metrics
Farm_mse = mse(Y_test, E_test);
Farm_rmse = rmse(Y_test, E_test);
Farm_mae = mae(Y_test, E_test);
Farm_mape = mape(Y_test, E_test);

fprintf('✓ Performance metrics calculated\n');

%% Generate Metrics Comparison Plot
% Organize metrics data
metric_names = ["MSE", "RMSE", "MAE", "MAPE"];
FNN_values = [FNN_mse, FNN_rmse, FNN_mae, FNN_mape];
GPR_values = [GPR_mse, GPR_rmse, GPR_mae, GPR_mape];
Farm_values = [Farm_mse, Farm_rmse, Farm_mae, Farm_mape];

metrics_matrix = [FNN_values; GPR_values; Farm_values];

% Define color scheme for models
model_colors = [0 0 1;    % Blue for FNN
                0 1 1;    % Cyan for GPR
                1 0 1];   % Magenta for Farm estimation

fig2 = figure;

% Create dual y-axis plot (MSE on left, others on right)
yyaxis left;
% Configure left y-axis for MSE
max_mse = max(metrics_matrix(:,1)) + 1000;
max_mse = ceil(max_mse / 1000) * 1000;
ylim([0, max_mse]);

num_ticks = 8;
ytick_step = ceil((max_mse / (num_ticks - 1)) / 1000) * 1000;
yticks(0:ytick_step:max_mse);
ylabel("MSE", 'Color', [0 0.4470 0.7410], 'FontSize', 14, 'FontName', 'Times New Roman');

hold on;
b1 = bar(1, metrics_matrix(:,1)', 'grouped');
for j = 1:3
    b1(j).FaceColor = model_colors(j, :);
end

% Configure right y-axis for RMSE, MAE, MAPE
yyaxis right;
max_other = max(metrics_matrix(:,2:4), [], 'all') + 10;
max_other = ceil(max_other / 10) * 10;
ylim([0, max_other]);

ytick_step_other = ceil((max_other / (num_ticks - 1)) / 10) * 10;
yticks(0:ytick_step_other:max_other);
ylabel("RMSE, MAE, MAPE", 'Color', [0.8500 0.3250 0.0980], 'FontSize', 14, 'FontName', 'Times New Roman');

b2 = bar(2:4, metrics_matrix(:,2:4)', 'grouped');
for j = 1:3
    b2(j).FaceColor = model_colors(j, :);
end

% Configure plot appearance
set(gca, 'XTick', 1:4, 'XTickLabel', metric_names, 'FontName', 'Times New Roman', 'FontSize', 14);
title(sprintf('%s %s Performance Metrics Comparison', CATTLE_ID, selected_region), ...
      'FontName', 'Times New Roman', 'FontSize', 16, 'FontWeight', 'bold', ...
      'Units', 'normalized', 'Position', [0.5, 1.05, 0]);

legend([b1(1), b1(2), b1(3)], {"FNN", "GPR", "Farm Estimation"}, ...
       'Location', 'best', 'FontSize', 14, 'FontName', 'Times New Roman');

% Add value labels on bars
for i = 1:length(metric_names)
    for j = 1:3
        % Set appropriate y-axis for labeling
        if i == 1
            yyaxis left;
        else
            yyaxis right;
        end
        
        % Calculate label position
        x_offset = (j - 2) * 0.3;
        x_pos = i + x_offset;
        y_pos = metrics_matrix(j, i);
        y_max = ylim;
        y_offset = max(y_max) * 0.03;
        
        % Adjust for overlapping labels
        if j > 1 && abs(metrics_matrix(j, i) - metrics_matrix(j-1, i)) < (max(y_max) * 0.02)
            y_offset = y_offset * 0.3;
        end
        
        % Format label text
        if i == 1
            label_text = sprintf('%.1e', y_pos);
        else
            label_text = sprintf('%.2f', y_pos);
        end
        
        % Add label
        text(x_pos, y_pos + y_offset, label_text, ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
            'FontName', 'Times New Roman', 'FontSize', 14, 'FontWeight', 'bold', 'Color', 'k');
    end
end

set(gca, 'Position', [0.15, 0.08, 0.7, 0.8]);
hold off;
theme(fig2, "light"); % MATLAB Version: 2025a

% Save metrics comparison plot
saveas(gcf, sprintf('%s\\%s_%s_Metrics_Comparison.svg', output_dir, CATTLE_ID, selected_region));

fprintf('✓ Metrics comparison plot saved\n');

%% Export Results to Markdown
markdown_filename = sprintf('%s\\%s_%s_Metrics.md', output_dir, CATTLE_ID, selected_region);
fileID = fopen(markdown_filename, 'w');

% Write markdown content
fprintf(fileID, '# %s %s Analysis Results\n\n', CATTLE_ID, selected_region);

fprintf(fileID, '## Test Configuration\n\n');
fprintf(fileID, '- **Cattle ID**: %s\n', CATTLE_ID);
fprintf(fileID, '- **Body Region**: %s\n', selected_region);
fprintf(fileID, '- **Test Period**: Weeks %d-%d\n', test_range(1), test_range(end));
fprintf(fileID, '- **Number of Test Samples**: %d\n\n', length(test_range));

fprintf(fileID, '## FNN Model Performance\n\n');
fprintf(fileID, '- **Mean Squared Error (MSE)**: %.4f\n', FNN_mse);
fprintf(fileID, '- **Root Mean Squared Error (RMSE)**: %.4f kg\n', FNN_rmse);
fprintf(fileID, '- **Mean Absolute Error (MAE)**: %.4f kg\n', FNN_mae);
fprintf(fileID, '- **Mean Absolute Percentage Error (MAPE)**: %.2f%%\n\n', FNN_mape);

fprintf(fileID, '## GPR Model Performance\n\n');
fprintf(fileID, '- **Mean Squared Error (MSE)**: %.4f\n', GPR_mse);
fprintf(fileID, '- **Root Mean Squared Error (RMSE)**: %.4f kg\n', GPR_rmse);
fprintf(fileID, '- **Mean Absolute Error (MAE)**: %.4f kg\n', GPR_mae);
fprintf(fileID, '- **Mean Absolute Percentage Error (MAPE)**: %.2f%%\n\n', GPR_mape);

fprintf(fileID, '## Farm Estimation Performance\n\n');
fprintf(fileID, '- **Mean Squared Error (MSE)**: %.4f\n', Farm_mse);
fprintf(fileID, '- **Root Mean Squared Error (RMSE)**: %.4f kg\n', Farm_rmse);
fprintf(fileID, '- **Mean Absolute Error (MAE)**: %.4f kg\n', Farm_mae);
fprintf(fileID, '- **Mean Absolute Percentage Error (MAPE)**: %.2f%%\n\n', Farm_mape);

fprintf(fileID, '## Performance Comparison\n\n');
fprintf(fileID, '![Performance Metrics](%s_%s_Metrics_Comparison.svg)\n\n', CATTLE_ID, selected_region);

fprintf(fileID, '## Prediction Results\n\n');
fprintf(fileID, '![Prediction Results](%s_%s_Prediction_Results.svg)\n\n', CATTLE_ID, selected_region);

% Close file
fclose(fileID);

fprintf('✓ Results exported to Markdown file\n');

%% Summary Report
fprintf('\n=== ANALYSIS COMPLETE ===\n');
fprintf('Cattle: %s, Region: %s\n', CATTLE_ID, selected_region);
fprintf('Best performing model (lowest RMSE): ');

[~, best_idx] = min([FNN_rmse, GPR_rmse, Farm_rmse]);
model_names = {'FNN', 'GPR', 'Farm Estimation'};
fprintf('%s (RMSE: %.2f kg)\n', model_names{best_idx}, min([FNN_rmse, GPR_rmse, Farm_rmse]));

fprintf('Files saved to: %s\n', output_dir);
fprintf('==============================\n');