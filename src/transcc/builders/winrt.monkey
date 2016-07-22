
Import builder
Import os
Import brl.databuffer
Import brl.filestream

Class WinrtBuilder Extends Builder

	Field shaders:StringStack

	Method New( tcc:TransCC )
		Super.New( tcc )
	End

	Method Config:String()
		Local config:=New StringStack
		For Local kv:=Eachin GetConfigVars()
			config.Push "#define CFG_"+kv.Key+" "+kv.Value
		Next
		Return config.Join( "~n" )
	End
	
	Method Content:String(csharp:Bool, dataFileMap:StringMap<String>)
		Local wp8:Bool = FileType("NativeGame.cpp") = FILETYPE_NONE
		Local compiledShaders:StringSet = New StringSet()
	
		Local cont:=New StringStack
		For Local kv:=Eachin dataFileMap
			Local p:=kv.Key
			Local r:=kv.Value
			Local t:=("Assets\monkey\"+r).Replace( "/","\" )
			
			If MatchPath ( r,SHADER_FILES )
				Local shader:String = StripExt(r)
				If compiledShaders.Contains(shader) Continue

				t = Shader(t, wp8)
				compiledShaders.Insert(shader)
			End If
		
			If csharp
				cont.Push "    <Content Include=~q"+t+"~q>"
				cont.Push "      <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>"
				cont.Push "    </Content>"
			Else
				cont.Push "    <None Include=~q"+t+"~q>"
				cont.Push "      <DeploymentContent>true</DeploymentContent>"
				cont.Push "    </None>"
			Endif
		Next
		
		Return cont.Join( "~n" )
	End
	
	Method Shader:String(shader:String,  wp8:Bool)	
		Local ext:=ExtractExt( shader )		
		Local p:String = "winrt"
		If wp8 Then p = "wp8"
		
		Local vertexShader:String, fragmentShader:String
		
		If ext = "vert"
			vertexShader = RealPath(shader)
			fragmentShader = RealPath(StripExt(shader) + ".frag")
		Else
			vertexShader = RealPath(StripExt(shader) + ".vert")
			fragmentShader = RealPath(shader)
		End If

		Execute "angle\src\winrtcompiler\bin\WinRTCompiler.exe -o=tmp_shader p="+p+" -a=compiled -v=~q"+vertexShader+"~q -f=~q"+fragmentShader+"~q"		
		Local data:String[] = LoadString("tmp_shader").Replace("unsigned char compiled[] = {", "").Replace("};", "").Trim().Split(",")
		DeleteFile("tmp_shader")
		
		Local compiledShaderName:String = StripExt(shader) + ".glslx"
		Local buffer:DataBuffer = New DataBuffer(data.Length())
		
		For Local i:Int = 0 Until data.Length()
			buffer.PokeByte(i, Int(data[i].Trim()))
		Next
		
		Local fs:FileStream = FileStream.Open(compiledShaderName, "w")
		fs.Write(buffer, 0, buffer.Length)
		fs.Close()
		
		Return compiledShaderName
	End Method
	
	Method IsValid:Bool()
		Select HostOS
		Case "winnt"
			If tcc.MSBUILD_PATH Return true
		End
		Return False
	End
	
	Method Begin:Void()
		ENV_LANG="cpp"
		_trans=New CppTranslator
	End
	
	Method MakeTarget:Void()

		CreateDataDir "Assets/monkey"
		
		Local dataFileMap:StringMap<String> = New StringMap<String>
		CreateDataFileMap "data", dataFileMap

		'proj file
		Local proj:=LoadString( "MonkeyGame.vcxproj" )
		If proj
			proj = ReplaceBlock(proj, "CONTENT", Content(False, dataFileMap), "~n    <!-- ")
			SaveString proj,"MonkeyGame.vcxproj"
		Else
			Local proj:=LoadString( "MonkeyGame.csproj" )
			proj=ReplaceBlock( proj,"CONTENT",Content( True, dataFileMap ),"~n    <!-- " )
			SaveString proj,"MonkeyGame.csproj"
		Endif
		
		'app code
		Local main:=LoadString( "MonkeyGame.cpp" )
		
		main=ReplaceBlock( main,"TRANSCODE",transCode )
		main=ReplaceBlock( main,"CONFIG",Config() )
		
		SaveString main,"MonkeyGame.cpp"

		If tcc.opt_build

			Execute "~q"+tcc.MSBUILD_PATH+"~q /p:Configuration="+casedConfig+" /p:Platform=Win32 MonkeyGame.sln"
			
			If tcc.opt_run
				'Any bright ideas...?
			Endif

		Endif
		
	End
	
End
