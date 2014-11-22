
Import transcc

Import android
Import android_ndk
Import flash
Import glfw
Import html5
Import ios
Import psm
Import stdcpp
Import winrt
Import xna
Import javatool

Class Builders
	
	Function Add(id:String, builder:Builder)
		If Not Builders Init()
		Builders.Insert id,builder
	End
	
	Function Replace(id:String, builder:Builder)
		If Not Builders Init()
		Builders.Set id,builder
	End
	
	Function Clear:Void()
		If Not Builders Init(True)
		Builders.Clear()		
	End Function
	
	Function Load:StringMap<Builder>(tcc:TransCC)
		If Not Builders Init()
	
		For Local b:=EachIn Builders.Values()
			b.Load tcc
		Next
		
		Return Builders
	End
	
Private

	Global Builders:StringMap<Builder>
	
	Function Init(empty:Bool=False)
		Builders=New StringMap<Builder>
		If empty Return

		Builders.Set "android",New AndroidBuilder
		Builders.Set "android_ndk",New AndroidNdkBuilder
		Builders.Set "glfw",New GlfwBuilder
		Builders.Set "html5",New Html5Builder
		Builders.Set "ios",New IosBuilder
		Builders.Set "flash",New FlashBuilder
		Builders.Set "psm",New PsmBuilder
		Builders.Set "stdcpp",New StdcppBuilder
		Builders.Set "winrt",New WinrtBuilder
		Builders.Set "xna",New XnaBuilder
		Builders.Set "javatool",New JavaToolBuilder
	End

End Class
