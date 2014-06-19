Strict

Import "shell.cpp"
Import os

Extern

Function Exec:Void(url:String)
	
Public

Function Main:Int()
	#If HOST = "winnt"
		Exec("bin\jentos.exe")
	#Else
		Exec("bin\jentos")
	#End
	
	Return 0
End