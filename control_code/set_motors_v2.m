for k = 1:NUM_BODY_SERVOS
    if LargeTorqueReactionQ
        if overload_counter(k) <= 0
            dxl_addparam_result = groupSyncWriteAddParam(group_num_write, ID(k), typecast(int32(round(motor_pos_decimal(k,index))),'uint32'), LEN_PRO_GOAL_POSITION);
        else
            dxl_addparam_result = groupSyncWriteAddParam(group_num_write, ID(k), typecast(int32(round(motor_pos_decimal(k,index)-200*sqrt(overload_counter(k)))),'uint32'), LEN_PRO_GOAL_POSITION);
        end
    else
        dxl_addparam_result = groupSyncWriteAddParam(group_num_write, ID(k), typecast(int32(round(motor_pos_decimal(k,index))),'uint32'), LEN_PRO_GOAL_POSITION);
    end
    if dxl_addparam_result ~= true
        fprintf('[ID:%02d] groupSyncWrite addparam fail', ID(k));
        closePort(port_num);
        return;
    end
end

% Syncwrite goal position
groupSyncWriteTxPacket(group_num_write);
if getLastTxRxResult(port_num, PROTOCOL_VERSION) ~= COMM_SUCCESS
    printTxRxResult(PROTOCOL_VERSION, getLastTxRxResult(port_num, PROTOCOL_VERSION));
end
% Clear syncwrite parameter storage
groupSyncWriteClearParam(group_num_write);
