
__T={SC=SC,main=main,content=content,gui=gui,selectGame=selectGame,autoTrack=autoTrack,
 getPower=function()return SC.rapidFirePower end,setPower=function(n)SC.rapidFirePower=n end,
 setSelected=function(p)SC.selectedPlayer=p SC.enabled=true end,
 setTeleport=function(p)teleportState.target=p end,
 trackTarget=currentTrackTarget,
 setTrack=function(p)SC.trackPlayer=p SC.trackEnabled=true end,
 startAuto=function()SC.trackEnabled=true autoTrack.mode="Leather"autoTrack.nextScan=0 end,
 interval=rapidFireInterval}
