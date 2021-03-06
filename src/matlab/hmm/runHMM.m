addpath('..');
exp_info=init_exp_info();

%load('C:/Users/kirchher/project/tool_learning/data/HMM/betta/betta_stage1_F1_go.mat');

%dates={'26.02.19','27.02.19','28.02.19','01.03.19','05.03.19','07.03.19','08.03.19','13.03.19','14.03.19','15.03.19','18.03.19',...
    %'19.03.19','21.03.19','22.03.19','25.03.19''11.03.19','12.03.19','27.03.19','28.03.19','29.03.19',...
    %'01.04.19','02.04.19','03.04.19','05.04.19','08.04.19','09.04.19','10.04.19','11.04.19','12.04.19','15.04.19','16.04.19',...
    %'17.04.19','18.04.19','19.04.19','23.04.19','24.04.19','26.04.19','29.04.19','01.05.19','02.05.19','03.05.19','06.05.19',...
    %'07.05.19','09.05.19','10.05.19','13.05.19','15.05.19','16.05.19','17.05.19','20.05.19','21.05.19','22.05.19','23.05.19',...
    %'27.05.19'};
    %dates={'13.03.19','14.03.19','15.03.19','18.03.19','19.03.19','21.03.19'};%,'22.03.19','25.03.19','26.03.19'};
%dates={'13.03.19','14.03.19','15.03.19'};
%dates={'19.03.19','21.03.19','22.03.19'};
dates={'27.03.19','28.03.19','29.03.19'};
%dates={'27.03.19','28.03.19','29.03.19'};

for i=1:length(dates)
    plot_multialign_multiunit_array_data(exp_info, 'betta', dates(i), 'F1', {'motor_grasp_right'});
end

%model_name='13-15.03.19_motor_grasp_right_multilevel_poisson_filtered';
%model_name='19-22.03.19_motor_grasp_right_multilevel_poisson_10ms';
%model_name='25-29.03.19_motor_grasp_right_multilevel_poisson_10ms';
model_name='27-29.03.19_motor_grasp_right_multilevel_poisson';

HMM(exp_info, 'betta', dates, 'F1', {'motor_grasp_right'}, model_name);
model=get_model(exp_info, 'betta', model_name);

plotHMM_aligned(exp_info, 'betta', dates, 'F1', {'motor_grasp_right'}, model);
