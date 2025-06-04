present_position = zeros(NUM_BODY_SERVOS,1);
present_current = zeros(NUM_BODY_SERVOS,1);

groupSyncReadTxRxPacket(group_num_read_position);
dxl_comm_result = getLastTxRxResult(port_num, PROTOCOL_VERSION);
if dxl_comm_result ~= COMM_SUCCESS
    fprintf('%s\n', getTxRxResult(PROTOCOL_VERSION, dxl_comm_result));
end

groupSyncReadTxRxPacket(group_num_read_current);
dxl_comm_result = getLastTxRxResult(port_num, PROTOCOL_VERSION);
if dxl_comm_result ~= COMM_SUCCESS
    fprintf('%s\n', getTxRxResult(PROTOCOL_VERSION, dxl_comm_result));
end

for k = 1:NUM_BODY_SERVOS
    present_position(k) = groupSyncReadGetData(group_num_read_position, ID(k), ADDR_PRO_PRESENT_POSITION, LEN_PRO_PRESENT_POSITION);
    present_position(k) = typecast(uint32(present_position(k)), 'int32');
    present_current(k) = groupSyncReadGetData(group_num_read_current, ID(k), ADDR_PRO_PRESENT_CURRENT, LEN_PRO_PRESENT_CURRENT);
    present_current(k) = typecast(uint16(present_current(k)), 'int16');
end

dxl_present_position = [dxl_present_position, present_position];
dxl_present_current = [dxl_present_current, present_current];

present_time = toc(start_gait);
dxl_present_time = [dxl_present_time, present_time];