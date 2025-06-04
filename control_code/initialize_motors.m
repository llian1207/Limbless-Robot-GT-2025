for k = 1:NUM_BODY_SERVOS
    write1ByteTxRx(port_num, PROTOCOL_VERSION, ID(k), ADDR_PRO_TORQUE_ENABLE, TORQUE_ENABLE);
    dxl_comm_result = getLastTxRxResult(port_num, PROTOCOL_VERSION);
    dxl_error = getLastRxPacketError(port_num, PROTOCOL_VERSION);
    if dxl_comm_result ~= COMM_SUCCESS
        fprintf('%s\n', getTxRxResult(PROTOCOL_VERSION, dxl_comm_result));
    elseif dxl_error ~= 0
        fprintf('%s\n', getRxPacketError(PROTOCOL_VERSION, dxl_error));
    else
        fprintf('Dynamixel [ID: %02d] has been successfully connected \n', ID(k));
    end
    
    % Add parameter storage for Dynamixel present position 
    dxl_addparam_result = groupSyncReadAddParam(group_num_read_position, ID(k));
    if dxl_addparam_result ~= true
        fprintf('[ID:%02d] groupBulkRead addparam failed', ID(k));
        return;
    end    
    
    % Add parameter storage for Dynamixel present current 
    dxl_addparam_result = groupSyncReadAddParam(group_num_read_current, ID(k));
    if dxl_addparam_result ~= true
        fprintf('[ID:%02d] groupBulkRead addparam failed', ID(k));
        return;
    end 
end