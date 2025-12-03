# Scheduling the Trade Me Scraper

This guide explains how to schedule the scraper to run automatically using Windows Task Scheduler.

## Batch Files

Two batch files are provided:

1. **`run_scraper.bat`** - Full-featured version with logging
   - Creates log files in `logs/` directory
   - Logs all output with timestamps
   - Handles errors and logs exit codes
   - Best for scheduled tasks

2. **`run_scraper_simple.bat`** - Simple version
   - Basic execution without logging
   - Includes pause for manual testing
   - Good for quick manual runs

## Setting Up Windows Task Scheduler

### Method 1: Using Task Scheduler GUI

1. **Open Task Scheduler**
   - Press `Win + R`, type `taskschd.msc`, press Enter
   - Or search "Task Scheduler" in Start menu

2. **Create Basic Task**
   - Click "Create Basic Task" in the right panel
   - Name: "Trade Me Scraper"
   - Description: "Automatically scrape Trade Me property listings"

3. **Set Trigger**
   - Choose when to run (Daily, Weekly, etc.)
   - Set the time and frequency

4. **Set Action**
   - Action: "Start a program"
   - Program/script: Browse to `run_scraper.bat` in your project folder
   - Start in: Set to your project folder path (e.g., `C:\Users\OEM\TM-scraper-1`)

5. **Finish**
   - Review settings
   - Check "Open the Properties dialog" if you want to configure more options
   - Click Finish

### Method 2: Using Command Line (PowerShell as Administrator)

```powershell
# Create a scheduled task that runs daily at 2:00 AM
$action = New-ScheduledTaskAction -Execute "C:\Users\OEM\TM-scraper-1\run_scraper.bat" -WorkingDirectory "C:\Users\OEM\TM-scraper-1"
$trigger = New-ScheduledTaskTrigger -Daily -At 2am
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
Register-ScheduledTask -TaskName "Trade Me Scraper" -Action $action -Trigger $trigger -Settings $settings -Description "Automatically scrape Trade Me property listings"
```

### Method 3: Using schtasks command

```cmd
schtasks /create /tn "Trade Me Scraper" /tr "C:\Users\OEM\TM-scraper-1\run_scraper.bat" /sc daily /st 02:00 /ru SYSTEM
```

## Important Notes

- **Python Path**: Ensure Python is in your system PATH, or modify the batch file to use the full path to Python
- **Working Directory**: The batch file automatically sets the working directory, but ensure Task Scheduler's "Start in" is set correctly
- **Logs**: Logs are saved in the `logs/` directory with timestamps
- **Permissions**: The task may need to run with administrator privileges depending on your system settings
- **Network**: Ensure your computer is connected to the internet when the task runs

## Testing the Batch File

Before scheduling, test the batch file manually:

1. Double-click `run_scraper.bat` to run it
2. Check that it executes successfully
3. Verify that log files are created (if using the full version)
4. Check that output Excel files are created in the `output/` directory

## Viewing Logs

Logs are stored in the `logs/` directory with filenames like:
- `scraper_20250115_143022.log` (YYYYMMDD_HHMMSS format)

Each log file contains:
- Start timestamp
- All console output from the scraper
- End timestamp and exit status

## Troubleshooting

- **Task doesn't run**: Check Task Scheduler history for errors
- **Python not found**: Add Python to system PATH or use full path in batch file
- **No output files**: Check that the `output/` directory exists and is writable
- **Permission errors**: Run Task Scheduler as administrator or adjust task permissions

