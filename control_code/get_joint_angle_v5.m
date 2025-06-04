% Work with main_7joint_sync_pegboard_v5_reverse.m

angle_prev = angle;

if ReverseTurnQ
    if turn_counter > 0
        if turn_direction == 'l'
            offset = -5;
            turn_counter = turn_counter - 1;
        elseif turn_direction == 'r'
            offset = 5;
            turn_counter = turn_counter - 1;
        else
            offset = 0;
        end
    elseif turn_counter == 0
        offset = 0;
        turn_counter = -1;
        turn_direction = '';
    else
        offset = 0;
    end
else
    offset = 0;
end

for k = 1:N
    angle(k) = A*sin(2*pi*omega_s*(k)/(N) - 2*pi*omega_t*t) + offset;
    angle(k) = min(90, max(-90, angle(k)));
end

command_angle = [command_angle, angle];
