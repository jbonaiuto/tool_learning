import os
from datetime import datetime

log_condition_map={
    'motor-grasp_left': 'motor_grasp_left',
    'motor-grasp_center': 'motor_grasp_center',
    'motor-grasp_right': 'motor_grasp_right',
    'motor-rake_center' : 'motor_rake_center',
    'motor-rake_center with cube': 'motor_rake_center',
    'motor-rake_center catch': 'motor_rake_center_catch',
    'Rake pull_right': 'visual_rake_pull_right',
    'Rake pull_left': 'visual_rake_pull_left',
    'Pliers_right': 'visual_pliers_right',
    'Pliers_left': 'visual_pliers_left',
    'Grasping_right': 'visual_grasp_right',
    'Grasping_left': 'visual_grasp_left',
    'Fixation_': 'fixation',
    'Fixation_Center': 'fixation',
    'motor-rake_right': 'motor_rake_right',
    'motor-rake_left': 'motor_rake_left',
    'motor-rake_right-cube': 'motor_rake_right',
    'motor-rake_right-food': 'motor_rake_food_right',
    'motor-rake_left-cube': 'motor_rake_left',
    'motor-rake_left-food': 'motor_rake_food_left',
    'motor-rake_center-cube': 'motor_rake_center',
    'motor-rake_center-food': 'motor_rake_food_center',
    'Rake push_left': 'visual_rake_push_left',
    'Rake push_right': 'visual_rake_push_right',
    'Stick_left': 'visual_stick_left',
    'Stick_right': 'visual_stick_right'
}

class EventIDELogSet:
    """
    A set of log files for recording of a subject in a single day (multiple sessions)
    """

    def __init__(self, subj_name, date, log_dir, plexon_data_dir):
        self.subj_name=subj_name
        self.date=date
        self.log_dir=log_dir

        self.logs=[]

        self.read_log_files(plexon_data_dir)


    """
    Read log files for this day
    """
    def read_log_files(self, plexon_data_dir):
        recording_date = datetime.strptime(self.date, '%d.%m.%y')

        # Get list of all log file names, tasks, and timestamps
        log_file_tasks = []
        log_file_names = []
        log_file_dates = []
        for x in os.listdir(self.log_dir):
            if os.path.splitext(x)[1] == '.csv':
                fparts = os.path.splitext(x)[0].split('_')
                try:
                    filedate = datetime.strptime(fparts[-1], '%Y-%d-%m--%H-%M')
                    if filedate.year == recording_date.year and filedate.month == recording_date.month and filedate.day == recording_date.day:
                        log_file_tasks.append('_'.join(fparts[0:-1]))
                        log_file_dates.append(filedate)
                        log_file_names.append(x)
                except:
                    pass

        # Sort files by timestamp
        sorted_logs = sorted(zip(log_file_dates, log_file_tasks, log_file_names))
        log_file_names = [x[2] for x in sorted_logs]
        log_file_tasks = [x[1] for x in sorted_logs]

        # Only read log files for which there is a corresponding plexon recording
        last_session_number = {}
        for log_file, task in zip(log_file_names,log_file_tasks):
            # Figure out session number
            if not task in last_session_number:
                session_number = 1
            else:
                session_number = last_session_number[task] + 1
            last_session_number[task] = session_number

            plx_file_name = '%s_%s_%s_%d.plx' % (self.subj_name, task, self.date, session_number)
            if os.path.exists(os.path.join(plexon_data_dir, plx_file_name)):
                self.logs.append(EventIDELog(self.subj_name,self.date,task,os.path.join(self.log_dir,log_file)))
        return log_file_names, log_file_tasks


    """
    Get total number of trials
    """
    def total_trials(self):
        total=0
        for log in self.logs:
            total=total+len(log.trial_durations)
        return total

    """
    Get all trial durations
    """
    def trial_durations(self):
        durations=[]
        for log in self.logs:
            durations.extend(log.trial_durations)
        return durations


class EventIDELog:
    """
    A log file for one recording session
    """
    def __init__(self, subj_name, date, task, log_file):
        self.subj_name=subj_name
        self.date=date
        self.task=task
        self.file=log_file

        self.trial_conditions = []
        self.trial_durations = []

        self.read_log_file()


    """
    Read trial conditions and durations from log file
    """
    def read_log_file(self):
        # Read log file
        f = open(os.path.join(self.file), 'r')
        trials_started = False
        trial_start = None

        for line in f:
            # Remove extra characters
            line = line.strip()
            # Trial states start after first blank line
            if len(line) == 0:
                trials_started = True
                continue

            if trials_started:
                # Parse line and get trial number
                line_parts = line.split(',')
                # Recording started - parse condition
                if line_parts[5] == 'StartLaser':
                    # location = line_parts[4]
                    # trial_locs.append(location)
                    last_condition = log_condition_map['%s_%s' % (line_parts[3], line_parts[4])]
                    self.trial_conditions.append(last_condition)
                    trial_start = float(line_parts[6])
                elif line_parts[5] == 'EndTrial' and trial_start is not None:
                    trial_end = float(line_parts[6])
                    self.trial_durations.append(trial_end - trial_start)
                    trial_start=None
        f.close()