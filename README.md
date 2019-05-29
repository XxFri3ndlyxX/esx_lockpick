
# esx_lockpick
Simple lockpick kit script for FiveM ESX servers

What does it do?
It is a lockpick system that locks all npc car. You need a lockpick to unlock the doors.
You can set the % of success and set the cops to be alerted if lockpick attempt is failed and with %
You can also set the alarm to be triggered fox x ammount of time.
You can also trigger a jammed handbrake when successfully unlocked the vehicle.
You can now whitelist some job to always have vehicle unlocked.
You can now blacklist some vehicle.
There is a chance the vehicle will be unlocked.

My attempt on making hotwiring longer failed so for the time being the jammed handbrake will do the job.

Join discord https://discord.gg/xncafqk

### Requirements
* es_extended
* esx_policejob
* pNotify
* mythic_progressbar https://github.com/XxFri3ndlyxX/progressbar

If you do not like Pnotify then Modify it to your needs. 

### Installation
Clone esx_lockpick

Drag the folder into your `<server-data>/resources/[esx]` folder and add this to your server.cfg
```
start esx_lockpick
```
Install esx_lockpick.sql
```
Add lockpick to your shop.
```
### CREDIT
This is a modified version of esx_repairkit:  
https://github.com/condolent/esx_repairkit/releases/latest)  
I use the cooldown from  
https://github.com/KlibrDM/esx_carthief  
I used the police notification code from  
https://github.com/TanguyOrtegat/esx_jb_outlawalert  
I use locking code from  
https://github.com/AxDSan/esx_nocarjack

Thanks!
