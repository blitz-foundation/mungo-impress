
Import builder

Class PS4Builder Extends Builder

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
	
	'***** Visual studio 2012 *****
	Method MakeVc2012:Void()
	
		Local dst:="gcc_"+HostOS
		
		CreateDir dst+"/"+casedConfig
		CreateDir dst+"/"+casedConfig+"/internal"
		CreateDir dst+"/"+casedConfig+"/external"
		
		CreateDataDir dst+"/"+casedConfig+"/data"
		
		Local main:=LoadString( "main.cpp" )
		
		main=ReplaceBlock( main,"TRANSCODE",transCode )
		main=ReplaceBlock( main,"CONFIG",Config() )
		
		SaveString main,"main.cpp"
		
		Local icon:=GetConfigVar("GLFW_APP_ICON")
		If icon
			If HostOS="winnt"
				Local resource:=LoadString( "resource.rc" )
				resource=ReplaceBlock( resource,"RESOURCE","APP_ICON ICON ~q" + icon + "~q")
				SaveString resource,"resource.rc"
			End
		End
		
		If tcc.opt_build

			ChangeDir dst
			CreateDir "build"
			CreateDir "build/"+casedConfig
			Local buildDataPath:= StripExt(tcc.opt_srcpath) + ".build"
			
			Local ccopts:=""
			Select ENV_CONFIG
				Case "debug"
					ccopts+=" -O0"
				Case "release"
					ccopts+=" -O3 -DNDEBUG"
			End
			
			Local ccobjs:=""
			
			If HostOS="winnt" And icon Then
				If Execute("windres ../resource.rc -O coff -o ../resource.res", False) ccobjs += "../resource.res"
			End

			Print "*********************************************************************************"
			Print " Building generated c++ :"
			Local cmd:= "~q" + tcc.MSBUILD_PATH_2012 + "~q /p:Configuration=" + casedConfig + " /p:Platform=ORBIS " + buildDataPath + "/ps4/msvc/MonkeyGame.sln"
			Print cmd
			Execute cmd
			
			Print "*********************************************************************************"
			Print " Running on devkit"
			cmd = "orbis-run /workingDirectory:" + buildDataPath + "/ps4/ /elf " + buildDataPath + "/ps4/msvc/ORBIS_Release/MonkeyGame.elf"
			Print cmd
			Execute cmd
		EndIf
			
	End
	
	'***** Builder *****
	Method IsValid:Bool()
		Select HostOS
			Case "winnt"
				If tcc.MINGW_PATH Or tcc.MSBUILD_PATH Return True
			Default
				Return True
		End
		Return False
	End
	
	Method Begin:Void()
		ENV_LANG="cpp"
		_trans=New CppTranslator
	End
	
	Method MakeShaders:Void()
		Local rootDataPath:= StripExt(tcc.opt_srcpath) + ".data"
	
		CompileShaders rootDataPath, False
	End
	
	Method MakeTarget:Void()
		'Compile shader only if outdated...
		
		CreateDataDir "data"
		
		Select HostOS
		Case "winnt"
			MakeVc2012
		End
	End
	
	Method Filter:String(filePath:String)
		If filePath.EndsWith("vert") Or filePath.EndsWith("frag")
			Return filePath
		ElseIf filePath.EndsWith("pssl")
			filePath = filePath.Replace(".pssl", "")
			Return filePath
		EndIf
		Return ""
	End
	
	Method CompileShaders:String(dataPath:String, boutputErrorFile:Bool)
		
		Local cmdSz:String
		
		'Copy data from monkey project to target project
		If dataPath
			Local dictionnary := New StringMap<Int>
			For Local f:= EachIn LoadDir(dataPath)
				Local path:= dataPath + "\" + f
				If FileType(path) = FILETYPE_DIR
					CompileShaders(path, boutputErrorFile)
				Else
					'Print "treating: " + f
					Local newName := Filter(f)
					If newName <> ""
						'Print "adding: " + f + " as " + newName
						dictionnary.Add(newName, 1)
					EndIf
				EndIf
			End
			
			Local pigletCompilerPath:= "piglet\tools\esslc\orbis-esslc.exe"
			For Local f:= EachIn dictionnary.Keys()
				'Print f
				Local fOut:= dataPath + "\" + f + ".sb"
				Local psslName:= f + ".pssl"
				Local fIn:= dataPath + "\" + psslName
				If FileType(fOut) = FILETYPE_NONE Or FileTime(fIn) > FileTime(fOut)
					If FileType(fIn) <> FILETYPE_NONE
						If f.EndsWith("vert")
							cmdSz = "orbis-wave-psslc -O3 -profile sce_vs_vs_orbis -o " + fOut + " " + fIn + " -cachedir " + dataPath + " -sdb " + f + ".sdb"
		
							Print "Compiling pssl vertex shader : " + psslName + " file: " + fIn + " to: " + fOut
							'Print cmdSz
							
							Execute cmdSz
						Else 'f.EndsWith("frag")
							cmdSz = "orbis-wave-psslc -O3 -profile sce_ps_orbis -o " + fOut + " " + fIn + " -cachedir " + dataPath + " -sdb " + f + ".sdb"
		
							Print "Compiling pssl fragment shader : " + psslName + " file: " + fIn + " to: " + fOut
						'	Print cmdSz
								
							Execute cmdSz
						EndIf
					Else
						fIn = dataPath + "\" + f
						If f.EndsWith("vert")
							cmdSz = pigletCompilerPath + " --cache -profile sce_vs_vs_orbis -D__PIGLET_ORBIS__ -o " + fOut + " " + fIn
							'If boutputErrorFile
							'cmdSz = "~q" + tcc.XONE_XDK_PATH + "\..\bin\pixsc\fxc.exe" + "~q" + "/Zi /D__XBOX_FULL_PRECOMPILE_PROMISE /Gis /sourcecode /O3 /T vs_5_0 /E main /Fo " + fOut + " /Fe " + fErr + " " + fIn '+ " /Fd " + fOut + ".pdb"
							'Else
								
							'cmdSz = "~q" + tcc.XONE_XDK_PATH + "\..\bin\pixsc\fxc.exe" + "~q" + "/Zi /D__XBOX_FULL_PRECOMPILE_PROMISE /Gis /sourcecode /O3 /T vs_5_0 /E main /Fo" + fOut + " " + fIn '+ " /Fd " + fOut + ".pdb"
							'EndIf
	
							Print "Compiling gl vertex shader : " + f + " file: " + fIn + " to: " + fOut
							'Print cmdSz
							
							Execute cmdSz
	
						ElseIf f.EndsWith("frag")
							cmdSz = pigletCompilerPath + " --cache -profile sce_ps_orbis -D__PIGLET_ORBIS__ -o " + fOut + " " + fIn
						
							' Debug flag : /Od /Zi /O0
							'If boutputErrorFile
							'	cmdSz = "~q" + tcc.XONE_XDK_PATH + "\..\bin\pixsc\fxc.exe" + "~q" + "/Zi /D__XBOX_FULL_PRECOMPILE_PROMISE /Gis /sourcecode  /O3 /T ps_5_0 /E main /Fo " + fOut + " /Fe " + fErr + " " + fIn '+ " /Fd " + fOut + ".pdb"
							'Else
							'	cmdSz = "~q" + tcc.XONE_XDK_PATH + "\..\bin\pixsc\fxc.exe" + "~q" + "/Zi /D__XBOX_FULL_PRECOMPILE_PROMISE /Gis /sourcecode  /O3 /T ps_5_0  /E main /Fo " + fOut + " " + fIn' + " /Fd " + fOut + ".pdb"
							'EndIf
							
							Print "Compiling gl pixel shader : " + f + " file: " + fIn + " to: " + fOut
							'Print cmdSz
							
							Execute cmdSz
						
						EndIf
					EndIf
				EndIf
			End
		EndIf
	End
End
