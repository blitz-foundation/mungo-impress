
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
	
	Method MakeTarget:Void()
		'Compile shader only if outdated...
		Local rootDataPath:= StripExt(tcc.opt_srcpath) + ".data"
		'Local buildDataPath:= StripExt(tcc.opt_srcpath) + ".build"
	
		'Print "Deploying mojo shader sources"
		'Local cmdSz:String = "xcopy " + buildDataPath + "/ps4/Assets/monkey/*ps4.frag " + rootDataPath + "/"
		'cmdSz = cmdSz.Replace("/", "\")
		'cmdSz = cmdSz + " /Y"
		'Print(cmdSz)
		'Execute cmdSz
		
		'cmdSz = "xcopy " + buildDataPath + "/ps4/Assets/monkey/*ps4.vert " + rootDataPath + "/"
		'cmdSz = cmdSz.Replace("/", "\")
		'cmdSz = cmdSz + " /Y"
		'Print(cmdSz)
		'Execute cmdSz
		
		CompileShaders rootDataPath, False
		
		CreateDataDir "data"
		
		Select HostOS
		Case "winnt"
			MakeVc2012
		End
	End
	
	Method CompileShaders:Void(dataPath:String, boutputErrorFile:Bool)
		
		Local cmdSz:String
		
		'Copy data from monkey project to target project
		If dataPath
			For Local f:= EachIn LoadDir(dataPath)
			
				Local compilerPath:= "piglet\tools\esslc\orbis-esslc.exe"
				Local fIn:= dataPath + "\" + f
				Local fOut:= dataPath + "\" + f + ".sb"
				'Local fErr:= dataPath + "\" + f + "err"
			
				If FileType(fIn) <> FILETYPE_FILE
					CompileShaders(fIn, boutputErrorFile)
				Else
					If f.EndsWith("vert")
						cmdSz = compilerPath + " --cache -profile sce_vs_vs_orbis -o " + fOut + " " + fIn
						If boutputErrorFile
							'cmdSz = "~q" + tcc.XONE_XDK_PATH + "\..\bin\pixsc\fxc.exe" + "~q" + "/Zi /D__XBOX_FULL_PRECOMPILE_PROMISE /Gis /sourcecode /O3 /T vs_5_0 /E main /Fo " + fOut + " /Fe " + fErr + " " + fIn '+ " /Fd " + fOut + ".pdb"
						Else
							
							'cmdSz = "~q" + tcc.XONE_XDK_PATH + "\..\bin\pixsc\fxc.exe" + "~q" + "/Zi /D__XBOX_FULL_PRECOMPILE_PROMISE /Gis /sourcecode /O3 /T vs_5_0 /E main /Fo" + fOut + " " + fIn '+ " /Fd " + fOut + ".pdb"
						EndIf

						Print "*********************************************************************************"
						Print "Compiling vertex shader : " + f
						Print cmdSz
						Print "*********************************************************************************"
						
						Execute cmdSz

					ElseIf f.EndsWith("frag")
						cmdSz = compilerPath + " --cache -profile sce_ps_orbis -o " + fOut + " " + fIn
					
						' Debug flag : /Od /Zi /O0
						'If boutputErrorFile
						'	cmdSz = "~q" + tcc.XONE_XDK_PATH + "\..\bin\pixsc\fxc.exe" + "~q" + "/Zi /D__XBOX_FULL_PRECOMPILE_PROMISE /Gis /sourcecode  /O3 /T ps_5_0 /E main /Fo " + fOut + " /Fe " + fErr + " " + fIn '+ " /Fd " + fOut + ".pdb"
						'Else
						'	cmdSz = "~q" + tcc.XONE_XDK_PATH + "\..\bin\pixsc\fxc.exe" + "~q" + "/Zi /D__XBOX_FULL_PRECOMPILE_PROMISE /Gis /sourcecode  /O3 /T ps_5_0  /E main /Fo " + fOut + " " + fIn' + " /Fd " + fOut + ".pdb"
						'EndIf
						
						Print "*********************************************************************************"
						Print "Compiling pixel shader : " + f
						Print cmdSz
						Print "*********************************************************************************"
						
						Execute cmdSz
					EndIf
				EndIf
			End
		EndIf
	End
End
