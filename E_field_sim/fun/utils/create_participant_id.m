function participant = create_participant_id(participant_id)
    if participant_id < 10
        participant = strcat('sub-00', num2str(participant_id));
    elseif participant_id >= 10 && participant_id < 100
        participant = strcat('sub-0', num2str(participant_id));
    else
        participant = strcat('sub-', num2str(participant_id));
    end  
end