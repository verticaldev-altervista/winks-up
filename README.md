<h1>W-UP</h1>

It is a minimal browser based on webkit. Directly derived from the demo vala webkit characteristics such as the absence of the frame, it is always in full screen and only has a small bar at the top of the home page is indirizzo.La startpage and if intrudci a research topic on the url bar running research as chrome.Ho filled w-up in linux (ubuntu) and in raspbian where it has the lightest of midori. 

The project is still in early stage and lacks many features. 

Seeking help in particular to: 

set the download of the file (the current one is at least fake) 
manage and store cookies (to implement) 
manage and save your favorite (my idea is to manage it directly online with a website) 
 

UPDATE 

I was able to progress a lot. w-up is now gtk3 The new interface is much more cute

I used part of the code of winks and I have the support of cookies is not perfect yet but definitely very good. 

For downloads use an auto-generated script that is set in ~ / .config / winks-up and uses wget and zenity. In this way it is possible to modify the script and use any downloader. 

Now thanks to the winks program has an icon and is a desktop file to the applications in the menu aggiugerlo distribution. 

I have introduced a system alias. In practice it is possible to create a shortcut for typing on the address bar: 

alias x http://www.x.com 

so typing on the bar just the alias will reach the desired address. 

pressing esc cancels automatically the address bar and the focus is placed editoare for them. After a while it becomes instinctive to use and fast :) 

There is still no support for plugins and some improvements but we are at a good level of usability given that I'm using to write these notes without problems 

you can be downloaded from the repository on github https://github.com/vroby65/winks-up
