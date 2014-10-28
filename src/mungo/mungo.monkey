Strict

#If TARGET<>"stdcpp"
	#Error "Target<>stdcpp"
#Endif

#STDCPP_APP_ICON = "../../mungo.ico"

Import brl.process
Import brl.filepath

Function Main:Int()	
	Local args:=""
	
	For Local i:=1 Until AppArgs().Length()
		Local arg:=AppArgs()[i]
		If arg.Contains( " " ) arg="~q"+arg+"~q"
		args+=" "+arg
	Next
	
	Local dir:=ExtractDir(AppPath())
	Local app:="jentos"
	
#If HOST = "winnt"
	
	Execute "start /B /D ~q"+dir+"~q bin\"+app+".exe "+args
	
#ElseIf HOST="macos"

	Local cmd:=dir+"/bin/"+app+".app"
	If args cmd="open -n "+cmd+" --args"+args Else cmd="open "+cmd
	Execute cmd
	Sleep 100
	
#ElseIf HOST="linux"

	Execute dir+"/bin/"+app+args+" >/dev/null 2>/dev/null &"

#Endif
	
	Return 0
End