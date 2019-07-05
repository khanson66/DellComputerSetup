# ComputerSetupSourceFiles

- see powershell comment in code for core details

-Functions.psm1
	contains functions that are used in the scripts.

-ProgramsDrivers.ps1
	File that installs drivers and programs. It also adds the scheduled task

-SetupAD.ps1
	file to be run after reboot. It removes the scheduled task and adds the computer to AD


supporting files

-config.xml
	Holds the data about logon task name, the url's to request and the AD domain to join

-niniteauto.exe/.au3
	built with AutoIT. it run ninte automaticatly and removes the gui. 
	it works by waiting to see the word finished appear on screen closing the program.
	
	Not using the PSModule version to retain system compatibilty and reduce download
	and conflicts
