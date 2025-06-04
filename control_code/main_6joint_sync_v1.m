% Author: Tianyu Wang 
% Date: 2024/4/9
% Available DXL model on this example : All models using Protocol 2.0
% This code is designed for using Dynamixel XC330-T288-T, and U2D2
% Sync read and write

clc;
clear;

%% Control table

cycles_per_exp = 10;

gait_para.Amp = 50; % Angular amplitude lateral wave
gait_para.spFreq = 1.1; % number of waves along the body (spatial frequency lateral wave)
gait_para.tmFreq = 4.0; % temporal frequency (Hz)

LargeTorqueReactionQ = false;
LargeTorqueStopQ = true;

%% Initialize library
run('initialize_library.m')

%% Control constants
% Control table address
ADDR_PRO_TORQUE_ENABLE       = 64;         % Control table address is different in Dynamixel model
ADDR_PRO_GOAL_POSITION       = 116;
ADDR_PRO_PRESENT_POSITION    = 132;
ADDR_PRO_PRESENT_CURRENT     = 126;

% Data Byte Length
LEN_PRO_GOAL_POSITION        = 4;
LEN_PRO_PRESENT_POSITION     = 4;
LEN_PRO_PRESENT_CURRENT      = 2;

% Protocol version
PROTOCOL_VERSION            = 2.0;          % See which protocol version is used in the Dynamixel

% Default setting
BAUDRATE                    = 1000000;
DEVICENAME                  = 'COM7';       % Check which port is being used on your controller
NUM_BODY_SERVOS             = 6;
ID                          = 1:NUM_BODY_SERVOS;
COMM_SUCCESS                = 0;            % Communication Success result value
COMM_TX_FAIL                = -1001;        % Communication Tx Failed

TORQUE_ENABLE               = 1;            % Value for enabling the torque
TORQUE_DISABLE              = 0;            % Value for disabling the torque
DXL_MAXIMUM_MOVING_SPEED    = 0;            % Dynamixel maximum moving speed value
DXL_MOVING_STATUS_THRESHOLD = 10;           % Dynamixel moving status threshold

% Initialize ports
run('initialize_ports.m')

dxl_comm_result = COMM_TX_FAIL;             % Communication result
dxl_error = 0;                              % Dynamixel error
dxl_present_position = [];                  % Present position
dxl_present_current = [];                      % Present load
dxl_present_time = [];                      % Present time

% Initialize Groupbulkread Structs
group_num_read_position = groupSyncRead(port_num, PROTOCOL_VERSION, ADDR_PRO_PRESENT_POSITION, LEN_PRO_PRESENT_POSITION);
group_num_read_current = groupSyncRead(port_num, PROTOCOL_VERSION, ADDR_PRO_PRESENT_CURRENT, LEN_PRO_PRESENT_CURRENT);
group_num_write = groupSyncWrite(port_num, PROTOCOL_VERSION, ADDR_PRO_GOAL_POSITION, LEN_PRO_GOAL_POSITION);
dxl_addparam_result = false;                % AddParam result
dxl_getdata_result = false;                 % GetParam result

%% Gait definition, motor position trajectory generation
% Serpenoid wave parameters
A = gait_para.Amp; % Angular amplitude lateral wave
omega_s = gait_para.spFreq; % number of waves along the body / spatial frequency lateral wave
N = NUM_BODY_SERVOS; % Number of joints
omega_t = gait_para.tmFreq; % Hz / temporal frequency

t = 0; % initialize time
dt = 0.001; %.001 time steps
angle = []; % motor angles for lateral wave
motor_pos_decimal = []; % motor positions for lateral wave
full_cycle_steps = (1/omega_t)/dt; % timesteps for one full cycle
all_steps = full_cycle_steps*cycles_per_exp; % timesteps for all cycles

for k = 1:N
    for i = 1:all_steps
        angle(k,i) = A*sin(2*pi*omega_s*(k)/(N) - 2*pi*omega_t*t);
        motor_pos_decimal(k,i) = angle(k,i)/0.0879+2048;
        t = t+dt;
    end
    t = 0;
end


%% Initialize motors
run('initialize_motors.m')

%% Zero position check
set_motors_zero;
disp("All motors at position 0, please check...");
% pause;
% pause(5);

%% Loop the gait
command_freq = 0.05;
% MOTORS_NEED_EXTRA = zeros(1, NUM_BODY_SERVOS);
overload_counter = ones(1, NUM_BODY_SERVOS) * -1;
overload_counter_record = overload_counter;

disp("Press any key to initialize shape...");
pause;
index = 1;
set_motors_v2;
disp("Press any key to start gait...");
pause;
pause(1);
start_gait = tic;

figure(100);
ButtonHandle = uicontrol('Style', 'PushButton', ...
    'String', 'Stop running', ...
    'Callback', 'delete(gcbf)');   % exit button

for index = 2:all_steps
    start_iter = tic;
    get_motor_feedback_v3;
    
    % ======= examine motor current load ============
    if LargeTorqueReactionQ
        large_load_idx = find(present_load > 700);
        overload_counter = overload_counter - 1;
        if ~isempty(large_load_idx)
            disp('triggered')
            for i = 1:length(large_load_idx)
                overload_counter(large_load_idx(i)) = 30;
            end
        end
        disp(overload_counter);
        overload_counter_record = [overload_counter_record; overload_counter];
    end
    
    if LargeTorqueStopQ
        disp(max(present_current))
        large_current_idx = find(present_current > 650);
        if ~isempty(large_current_idx)
            disp('!!!Overload protection triggered!!!');
            
            for DXL_ID = 1:NUM_BODY_SERVOS
                write1ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID, ADDR_PRO_TORQUE_ENABLE, TORQUE_DISABLE);
            end
            
            close(100);
            break;
        end
    end
    % ===============================================
    set_motors_v2;
    time = toc(start_iter);
    pause(max(command_freq-time, 0));
    
    if ~ishandle(ButtonHandle)
        disp('Stopped');
        break;
    end
end
get_motor_feedback_v3;
fbk.dxl_present_position = dxl_present_position;
fbk.dxl_present_current = dxl_present_current;
fbk.dxl_present_time = dxl_present_time;
fbk.overload_counter = overload_counter_record;

save_data;



%% Exit
disp("Gait done, press any key to reset motors to zeros...");
pause;
pause(3);
set_motors_zero;
index = index + 1;

pause(3);

run('clean_up.m')
% close all;
% clear;
