import subprocess
import datetime
import random
import math
import os

start_date = datetime.date(2026, 4, 19)
end_date = datetime.date(2026, 5, 9)

days = (end_date - start_date).days + 1
dates = [start_date + datetime.timedelta(days=i) for i in range(days)]

# Get all untracked files
result = subprocess.run(['git', 'ls-files', '-o', '--exclude-standard'], capture_output=True, text=True)
files = [f for f in result.stdout.split('\n') if f.strip()]

# Distribute files to days
files_per_day = math.ceil(len(files) / len(dates))

commit_msgs = [
    "Refactor {}",
    "Update {}",
    "Add {}",
    "Fix bug in {}",
    "Improve performance in {}",
    "Add tests for {}",
    "Clean up {}",
    "Optimize {}"
]

for i, day in enumerate(dates):
    day_files = files[i*files_per_day : (i+1)*files_per_day]
    if not day_files:
        break
    
    # Generate random times for each file
    # between 9:00 AM and 6:00 PM (9 hours = 32400 seconds)
    times = sorted([random.randint(0, 32400) for _ in range(len(day_files))])
    
    for file, offset in zip(day_files, times):
        dt = datetime.datetime.combine(day, datetime.time(9, 0)) + datetime.timedelta(seconds=offset)
        
        # Git add
        subprocess.run(['git', 'add', file])
        
        # Git commit
        msg_template = random.choice(commit_msgs)
        filename = os.path.basename(file)
        msg = msg_template.format(filename)
        
        date_str = dt.strftime('%Y-%m-%dT%H:%M:%S')
        env = os.environ.copy()
        env['GIT_AUTHOR_DATE'] = date_str
        env['GIT_COMMITTER_DATE'] = date_str
        
        subprocess.run(['git', 'commit', '-m', msg], env=env)
        
print("Done!")
