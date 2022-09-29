function export_kinematics(data, output_path)

fname=fullfile(output_path,'kinematic_data.csv');
fid=fopen(fname,'w');
fprintf(fid,'day,trial,condition,rt,mt,pt\n');

rts=data.metadata.hand_mvmt_onset-data.metadata.go;
mts=data.metadata.obj_contact-data.metadata.hand_mvmt_onset;
pts=data.metadata.place-data.metadata.obj_contact;

for t=1:data.ntrials
   date=data.trial_date(t);
   condition=data.metadata.condition{t};
   fprintf(fid,'%d,%d,%s,%.4f,%.4f,%.4f\n', date, t, condition, rts(t), mts(t), pts(t));
end
fclose(fid);
   
