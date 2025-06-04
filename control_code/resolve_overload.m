%% Initialize library
run('initialize_library.m')

%% Control constants
% Control table address
ADDR_PRO_TORQUE_ENABLE       = 64;         % Control table address is different in Dynamixel model
ADDR_PRO_GOAL_POSITION       = 116;
ADDR_PRO_PRESENT_POSITION    = 132;
ADDR_PRO_PRESENT_LOAD        = 126;

% Data Byte Length
LEN_PRO_GOAL_POSITION        = 4;
LEN_PRO_PRESENT_POSITION     = 4;
LEN_PRO_PRESENT_LOAD         = 2;

% Protocol version
PROTOCOL_VERSION            = 2.0;          % See which protocol version is used in the Dynamixel

% Default setting
BAUDRATE                    = 1000000;
DEVICENAME                  = 'COM5';       % Check which port is being used on your controller
NUM_BODY_SERVOS             = 14;
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

POS_0_DEG                   = load('pos_0.mat').POS_0_DEG;

for k = 1:NUM_BODY_SERVOS/2
    k
    real_pos_odd = read4ByteTxRx(port_num, PROTOCOL_VERSION, ID(2*k-1), ADDR_PRO_PRESENT_POSITION);
    real_pos_even = read4ByteTxRx(port_num, PROTOCOL_VERSION, ID(2*k), ADDR_PRO_PRESENT_POSITION);
    real_pos_odd = typecast(uint32(round(real_pos_odd)),'int32');
    real_pos_even = typecast(uint32(round(real_pos_even)),'int32');
    reboot(port_num, PROTOCOL_VERSION, ID(2*k-1));
    reboot(port_num, PROTOCOL_VERSION, ID(2*k));
    pause(0.5);
    write1ByteTxRx(port_num, PROTOCOL_VERSION, ID(2*k-1), ADDR_PRO_TORQUE_ENABLE, TORQUE_ENABLE);
    write1ByteTxRx(port_num, PROTOCOL_VERSION, ID(2*k), ADDR_PRO_TORQUE_ENABLE, TORQUE_ENABLE);
    pause(0.5);
    reboot_pos_odd = mod(real_pos_odd, 4096);
    reboot_pos_even = mod(real_pos_even, 4096);
    command_pos_odd = POS_0_DEG(2*k-1) - (real_pos_odd - reboot_pos_odd);
    command_pos_even = POS_0_DEG(2*k) - (real_pos_even - reboot_pos_even);
    command_pos_odd_hex = typecast(int32(round(command_pos_odd)),'uint32');
    command_pos_even_hex = typecast(int32(round(command_pos_even)),'uint32');
    if real_pos_odd > 4096
        for ii = 1:10
            write4ByteTxRx(port_num, PROTOCOL_VERSION, ID(2*k-1), ADDR_PRO_GOAL_POSITION, command_pos_odd_hex);
        end
        pause(1);
        for ii = 1:10
            write4ByteTxRx(port_num, PROTOCOL_VERSION, ID(2*k), ADDR_PRO_GOAL_POSITION, command_pos_even_hex);
        end
        pause(1);
    elseif real_pos_even > 4096
        for ii = 1:10
            write4ByteTxRx(port_num, PROTOCOL_VERSION, ID(2*k), ADDR_PRO_GOAL_POSITION, command_pos_even_hex);
        end
        pause(1);
        for ii = 1:10
            write4ByteTxRx(port_num, PROTOCOL_VERSION, ID(2*k-1), ADDR_PRO_GOAL_POSITION, command_pos_odd_hex);
        end
        pause(1);
    else
        for ii = 1:10
            write4ByteTxRx(port_num, PROTOCOL_VERSION, ID(2*k), ADDR_PRO_GOAL_POSITION, command_pos_even_hex);
            write4ByteTxRx(port_num, PROTOCOL_VERSION, ID(2*k-1), ADDR_PRO_GOAL_POSITION, command_pos_odd_hex);
        end
        pause(1);
    end
    reboot(port_num, PROTOCOL_VERSION, ID(2*k-1));
    reboot(port_num, PROTOCOL_VERSION, ID(2*k));
    write1ByteTxRx(port_num, PROTOCOL_VERSION, ID(2*k-1), ADDR_PRO_TORQUE_ENABLE, TORQUE_ENABLE);
    write1ByteTxRx(port_num, PROTOCOL_VERSION, ID(2*k), ADDR_PRO_TORQUE_ENABLE, TORQUE_ENABLE);
end

run('clean_up.m')