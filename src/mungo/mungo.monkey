Strict

#GLFW_APP_ICON = "../../mungo.ico"

Import mojo.app

Function Main:Int()
	#If HOST = "winnt"
		OpenUrl("bin\jentos.exe")
	#Else
		OpenUrl("bin\jentos")
	#End
	
	Return 0
End