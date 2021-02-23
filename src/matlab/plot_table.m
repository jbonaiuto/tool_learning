function plot_table(exp_info, ax, varargin)

defaults=struct('color','k');
params=struct(varargin{:});
for f=fieldnames(defaults)'
    if ~isfield(params, f{1})
        params.(f{1})=defaults.(f{1});
    end
end


colors=get(ax,'ColorOrder');
hold all;

circle(exp_info.laser_exp_start_right_laser_pos(1),exp_info.laser_exp_start_right_laser_pos(3),2.5,colors(1,:));
circle(exp_info.laser_exp_start_left_laser_pos(1),exp_info.laser_exp_start_left_laser_pos(3),2.5,colors(2,:));
circle(exp_info.laser_exp_grasp_center_laser_pos(1),exp_info.laser_exp_grasp_center_laser_pos(3),2.5,colors(3,:));
circle(exp_info.monkey_tool_right_laser_pos(1),exp_info.monkey_tool_right_laser_pos(3),2.5,colors(4,:));
circle(exp_info.monkey_tool_left_laser_pos(1),exp_info.monkey_tool_left_laser_pos(3),2.5,colors(5,:));
circle(exp_info.exp_start_platform_left(1),exp_info.exp_start_platform_left(3),2,params.color);
circle(exp_info.exp_start_platform_right(1),exp_info.exp_start_platform_right(3),2,params.color);
circle(exp_info.exp_place_left(1),exp_info.exp_place_left(3),1,params.color);
circle(exp_info.exp_place_right(1),exp_info.exp_place_right(3),1,params.color);
circle(exp_info.exp_grasp_center(1),exp_info.exp_grasp_center(3),1,params.color);
circle(exp_info.monkey_handle(1),exp_info.monkey_handle(3),1.25,params.color);
circle(exp_info.monkey_tool_left(1),exp_info.monkey_tool_left(3),1,params.color);
circle(exp_info.monkey_tool_mid_left(1),exp_info.monkey_tool_mid_left(3),1,params.color);
circle(exp_info.monkey_tool_center(1),exp_info.monkey_tool_center(3),1,params.color);
circle(exp_info.monkey_tool_mid_right(1),exp_info.monkey_tool_mid_right(3),1,params.color);
circle(exp_info.monkey_tool_right(1),exp_info.monkey_tool_right(3),1,params.color);

N=100;
rangle=linspace(0,pi,N);
radius=12.5;
xy=[radius*cos(rangle); radius*sin(rangle)];
plot(xy(1,:),xy(2,:)+3,'Color',params.color,'LineWidth',2);
radius=10;
xy=[radius*cos(rangle); radius*sin(rangle)];
plot(xy(1,:),xy(2,:)+3,'Color',params.color,'LineWidth',2);
plot([-12.5 -10],[3 3],'Color',params.color,'LineWidth',2);
plot([10 12.5],[3 3],'Color',params.color,'LineWidth',2);

plot([exp_info.table_corner_4(1) exp_info.table_corner_1(1)],[exp_info.table_corner_4(3) exp_info.table_corner_1(3)],'Color',params.color,'LineWidth',2);
plot([exp_info.table_corner_1(1) exp_info.table_corner_2(1)],[exp_info.table_corner_1(3) exp_info.table_corner_2(3)],'Color',params.color,'LineWidth',2);
plot([exp_info.table_corner_2(1) exp_info.table_corner_3(1)],[exp_info.table_corner_2(3) exp_info.table_corner_3(3)],'Color',params.color,'LineWidth',2);
plot([exp_info.table_corner_4(1) exp_info.table_corner_4(1)+22.5],[exp_info.table_corner_4(3) exp_info.table_corner_4(3)],'Color',params.color,'LineWidth',2);
plot([exp_info.table_corner_4(1)+22.5 exp_info.table_corner_4(1)+22.5],[exp_info.table_corner_4(3) exp_info.table_corner_4(3)-6.9],'Color',params.color,'LineWidth',2);
plot([exp_info.table_corner_4(1)+22.5 exp_info.table_corner_4(1)+22.5+20],[exp_info.table_corner_4(3)-6.9 exp_info.table_corner_4(3)-6.9],'Color',params.color,'LineWidth',2);
plot([exp_info.table_corner_4(1)+22.5+20 exp_info.table_corner_4(1)+22.5+20],[exp_info.table_corner_4(3)-6.9 exp_info.table_corner_4(3)],'Color',params.color,'LineWidth',2);
plot([exp_info.table_corner_4(1)+22.5+20 exp_info.table_corner_3(1)],[exp_info.table_corner_4(3) exp_info.table_corner_3(3)],'Color',params.color,'LineWidth',2);

axis equal
xlim([-35 35]);
ylim([-7.5 65]);