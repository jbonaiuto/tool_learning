function plot_kinematics(data)

rts=data.metadata.hand_mvmt_onset-data.metadata.go;
mts=data.metadata.obj_contact-data.metadata.hand_mvmt_onset;
pts=data.metadata.place-data.metadata.obj_contact;

conditions={'motor_grasp_center','motor_grasp_right','motor_grasp_left'};

cond_rts={};
cond_mts={};
cond_pts={};
for c=1:length(conditions)
    c_idx=find(strcmp(data.metadata.condition,conditions{c}));
    cond_rts{c}=rts(c_idx);
    cond_mts{c}=mts(c_idx);
    cond_pts{c}=pts(c_idx);
end
figure();
ax=subplot(1,3,1);
plot_state_statistics(cond_rts,conditions, 'zero_bounded',true,'density_type','rash','ax',ax);
ax=subplot(1,3,2);
plot_state_statistics(cond_mts,conditions, 'zero_bounded',true,'density_type','rash','ax',ax);
ax=subplot(1,3,3);
plot_state_statistics(cond_pts,conditions, 'zero_bounded',true,'density_type','rash','ax',ax);
