
Import builder
Import os

Class WinrtBuilder Extends Builder

	Field shaders:StringStack

	Method New( tcc:TransCC )
		Super.New( tcc )
		shaders = New StringStack()
	End

	Method Config:String()
		Local config:=New StringStack
		For Local kv:=Eachin GetConfigVars()
			config.Push "#define CFG_"+kv.Key+" "+kv.Value
		Next
		Return config.Join( "~n" )
	End
	
	Method Content:String( csharp:Bool )
		Local wp8:Bool = FileType("NativeGame.cpp") = FILETYPE_NONE
		Local compiledShaders:StringSet = New StringSet()
	
		Local cont:=New StringStack
		For Local kv:=Eachin dataFiles
			Local p:=kv.Key
			Local r:=kv.Value
			Local t:=("Assets\monkey\"+r).Replace( "/","\" )
			
			If MatchPath ( r,SHADER_FILES )
				Local shader:String = StripExt(r)
				If compiledShaders.Contains(shader) Continue
				
				If compiledShaders.IsEmpty()
					'shaders.Push("struct SHADERS {")
					'shaders.Push("static std::map<std::string, const void*> compile() {")
					'shaders.Push("std::map<std::string, const void*> shaders;")
				End If
			
				Shader(r, t, wp8)
				compiledShaders.Insert(shader)
				
				Continue
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
		
		If Not compiledShaders.IsEmpty()
			'shaders.Push("return shaders;")
			'shaders.Push("}")
			'shaders.Push("static const std::map<std::string, const void*> COMPILED;")
			'shaders.Push("};")
			'shaders.Push("const std::map<std::string, const void*> SHADERS::COMPILED = SHADERS::compile();")
		End If
		
		Return cont.Join( "~n" )
	End
	
	Method Shader:Void(shader:String, shaderAsset:String,  wp8:Bool)	
		Local ext:=ExtractExt( shader )		
			
		Local munged:="shader"
		For Local q:=Eachin StripExt( shader ).Split( "/" )
			For Local i=0 Until q.Length
				If IsAlpha( q[i] ) Or IsDigit( q[i] ) Or q[i]=95 Continue
			Next
			munged+="_" + q
		Next
		
		Local p:String = "winrt"
		If wp8 Then p = "wp8"
		
		Local vertexShader:String, fragmentShader:String
		
		If ext = "vert"
			vertexShader = RealPath(shaderAsset)
			fragmentShader = RealPath(StripExt(shaderAsset) + ".frag")
		Else
			vertexShader = RealPath(StripExt(shaderAsset) + ".vert")
			fragmentShader = RealPath(shaderAsset)
		End If

		Execute "angle\src\winrtcompiler\bin\WinRTCompiler.exe -o=tmp_shader p="+p+" -a="+munged+" -v=~q"+vertexShader+"~q -f=~q"+fragmentShader+"~q"
		
		shaders.Push(LoadString("tmp_shader"))
		DeleteFile("tmp_shader")
		
		'shaders.Push("shaders[~q"+StripExt(shader)+"~q]="+munged+";")
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

		'proj file
		Local proj:=LoadString( "MonkeyGame.vcxproj" )
		If proj
			proj=ReplaceBlock( proj,"CONTENT",Content( False ),"~n    <!-- " )
			SaveString proj,"MonkeyGame.vcxproj"
		Else
			Local proj:=LoadString( "MonkeyGame.csproj" )
			proj=ReplaceBlock( proj,"CONTENT",Content( True ),"~n    <!-- " )
			SaveString proj,"MonkeyGame.csproj"
		Endif
		
		'app code
		Local main:=LoadString( "MonkeyGame.cpp" )
		
		main=ReplaceBlock( main,"TRANSCODE",transCode )
		main=ReplaceBlock( main,"CONFIG",Config() )
		main=ReplaceBlock( main,"SHADERS",shaders.Join("~n"))
		
		SaveString main,"MonkeyGame.cpp"

		If tcc.opt_build

			Execute tcc.MSBUILD_PATH+" /p:Configuration="+casedConfig+" /p:Platform=Win32 MonkeyGame.sln"
			
			If tcc.opt_run
				'Any bright ideas...?
			Endif

		Endif
		
	End
	
End
