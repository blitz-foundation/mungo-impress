
Import builder

Class XBoxOneBuilder Extends Builder

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
	
	Method GetApplicationLooseFolderPath:String()
		Return ".\Durango\Layout\Image\Loose"
	End
	
	'***** Vc2012 *****
	Method MakeVc2012:Void()
	
		Local main:= LoadString("main.cpp")
		
		main=ReplaceBlock( main,"TRANSCODE",transCode )
		main=ReplaceBlock( main,"CONFIG",Config() )
		
		SaveString main,"main.cpp"
		
		Local cmdSz:String
		Local buildDataPath:= StripExt(tcc.opt_srcpath) + ".build"

		If tcc.opt_build

			'casedConfig todo before there was the casedConfig instead of Profile !
			
			Print "*********************************************************************************"
			Print " Building generated c++ :"
			Local cmd:= "~q" + tcc.MSBUILD_PATH_2012 + "~q /p:Configuration=" + casedConfig + " /p:Platform=Durango MonkeyGame.sln"
			Print cmd
			Execute cmd
			
			Print "*********************************************************************************"
			Print " XBox One Deployment :"
		
			Print "Stopping previous pull deployment"
			cmdSz = "~q" + tcc.XONE_XDK_PATH + "\xbdeploy.exe ~q stop /x:" + tcc.XONE_IP_ADDRESS + " a20bc1dd-6161-4a2a-8312-37d7773b0034_1.0.0.0_x64__zjr0dfhgjwvde"
			Print cmdSz
			Execute(cmdSz, False)
			
			Print "Deploying in pull mode"
			CreatePullMappingFile buildDataPath + "/xboxone/Assets/monkey"
			cmdSz = "~q" + tcc.XONE_XDK_PATH + "\xbdeploy.exe ~q pull " + GetApplicationLooseFolderPath() + " /x:" + tcc.XONE_IP_ADDRESS + " /temp:deploy_temp /mf:pull_map.xml"
			Print cmdSz
			Execute cmdSz
			
			If tcc.opt_run = False
				CreatePackageMappingFile(buildDataPath + "/xboxone/Assets/monkey")
				
				Print "*********************************************************************************"
				Print " XBox One Building package"
				Print "*********************************************************************************"
				cmdSz = "~q" + tcc.XONE_XDK_PATH + "\makepkg.exe~q" + " pack /f " + buildDataPath + "/xboxone/package_map.xml /d " +  buildDataPath+"/xboxone/Durango/Layout/Image/Loose" + " /pd "+ buildDataPath + "\xboxone"
				Print "Execute : " + cmdSz
				Execute cmdSz
			EndIf
			If tcc.opt_run
						
				Print "*********************************************************************************"
				Print " XBox One Run :"
				
				cmdSz = "~q" + tcc.XONE_XDK_PATH + "\xbapp.exe ~q launch /X:" + tcc.XONE_IP_ADDRESS + " a20bc1dd-6161-4a2a-8312-37d7773b0034_zjr0dfhgjwvde!App"
				Print "Execute : " + cmdSz
				Print "*********************************************************************************"
				Execute cmdSz
				
			Endif
		
		EndIf
	
		'If tcc.opt_update And Not tcc.opt_build
		'	Print "*********************************************************************************"
		'	Print " XBox One Updating files :"
		'	Print "*********************************************************************************"
		'	cmdSz = "~q" + tcc.XONE_XDK_PATH + "\xbdeploy.exe ~q audition " + " /x:" + tcc.XONE_IP_ADDRESS + " a20bc1dd-6161-4a2a-8312-37d7773b0034_1.0.0.0_x64__zjr0dfhgjwvde"
		'	Print "Execute : " + cmdSz
		'	Execute cmdSz				
		'EndIf
		
	
	End

	'***** Builder *****	
	Method IsValid:Bool()
		Select HostOS
		Case "winnt"
			If tcc.MSBUILD_PATH_2012 Return True
		Default
			Return True
		End
		Return False
	End
	
	Method Begin:Void()
		ENV_LANG="cpp"
		_trans=New CppTranslator
	End
	
	Method CompileShaders:Void(dataPath:String, boutputErrorFile:Bool)
		
		Local cmdSz:String
		
		'Copy data from monkey project to target project
		If dataPath
			For Local f:= EachIn LoadDir(dataPath)
			
				Local fIn:= dataPath + "\" + f
				Local fOut:= dataPath + "\" + f + "o"
				Local fErr:= dataPath + "\" + f + "err"
			
				If FileType(fIn) <> FILETYPE_FILE
						CompileShaders(fIn, boutputErrorFile)
				Else
					If f.EndsWith("verthlsl")
						If boutputErrorFile
							cmdSz = "~q" + tcc.XONE_XDK_PATH + "\..\bin\pixsc\fxc.exe" + "~q" + " /D__XBOX_FULL_PRECOMPILE_PROMISE /Gis /sourcecode /O3 /T vs_5_0 /E main /Fo " + fOut + " /Fe " + fErr + " " + fIn '+ " /Fd " + fOut + ".pdb"						
						Else
							cmdSz = "~q" + tcc.XONE_XDK_PATH + "\..\bin\pixsc\fxc.exe" + "~q" + " /D__XBOX_FULL_PRECOMPILE_PROMISE /Gis /sourcecode /O3 /T vs_5_0 /E main /Fo" + fOut + " " + fIn '+ " /Fd " + fOut + ".pdb"
						EndIf

						Print "*********************************************************************************"
						Print "Compiling vertex shader : " + cmdSz
						Print "*********************************************************************************"
						
						Execute cmdSz

					ElseIf f.EndsWith("fraghlsl")
						
					' Debug flag : /Od /Zi /O0
						If boutputErrorFile
							cmdSz = "~q" + tcc.XONE_XDK_PATH + "\..\bin\pixsc\fxc.exe" + "~q" + "/Zi /D__XBOX_FULL_PRECOMPILE_PROMISE /Gis /sourcecode  /O3 /T ps_5_0 /E main /Fo " + fOut + " /Fe " + fErr + " " + fIn '+ " /Fd " + fOut + ".pdb"
						Else
							cmdSz = "~q" + tcc.XONE_XDK_PATH + "\..\bin\pixsc\fxc.exe" + "~q" + "/Zi /D__XBOX_FULL_PRECOMPILE_PROMISE /Gis /sourcecode  /O3 /T ps_5_0  /E main /Fo " + fOut + " " + fIn' + " /Fd " + fOut + ".pdb"
						EndIf
						
						Print "*********************************************************************************"
						Print "Compiling pixel shader : " + cmdSz
						Print "*********************************************************************************"
						
						Execute cmdSz
					EndIf
				EndIf
			End
		EndIf
	End
	
	Method RecurseFolderAndAddPackageDirectory2:String(rootDataPath:String)
		' First add the entry and then recurse
		rootDataPath = rootDataPath.Replace("/", "\")
	
		
		Local xml_data:String
		Local local_xml_data:String
		
		Local i:Int = rootDataPath.Find("Assets")
		Local j:Int = i + 14 'skipping \monkey\

		Local str:String  = rootDataPath[i..]
		Local str2:String = rootDataPath[j..]
				
		'	If parent.Length
		If (FileType(rootDataPath) = FILETYPE_DIR)
			If str2.Length()
				local_xml_data = "<FileGroup SourcePath=~q.\..\..\..\..\" + str + "~q DestinationPath=~q\data\" + str2 + "\" + "~q Include=~q*.*~q />~n"
			EndIf
		Else
			local_xml_data = "<FileGroup SourcePath=~q.\..\..\..\..\" + str + "~q DestinationPath=~q\data\" + "~q Include=~q*.*~q />~n"
		Endif
		
		Local hasFile:= False
		For Local child:= EachIn LoadDir(rootDataPath)
			Local childPath:= rootDataPath + "\" + child
			If (FileType(childPath) = FILETYPE_FILE)
				hasFile = True
			End
			xml_data += RecurseFolderAndAddPackageDirectory2(childPath)
		End
		
		If hasFile
			xml_data += local_xml_data
		EndIf
		
		Return xml_data;
	End
	
	Method RecurseFolderAndAddPackageDirectory:String(rootDataPath:String, f:String, parent:String)
		Print "RecurseFolderAndAddPackageDirectory  "
		' First add the entry and then recurse
		rootDataPath = rootDataPath.Replace("/", "\")
	'	f = f.Replace("/", "\")
		
		local xml_data : String
		
		Local i:Int = rootDataPath.Find("Assets")
		Local j:Int = i + 14 'skipping \monkey\

		Local str:String  = rootDataPath[i..]
		Local str2:String = rootDataPath[j..]
				
'		If parent.Length
'			xml_data= "<FileGroup SourcePath=~q.\..\..\..\..\Assets\monkey\" + parent + "\" + f + "~q DestinationPath=~q\data\" + parent + "\" + f +"~q Include=~q*.*~q />~n"
'		Else
'			xml_data= "<FileGroup SourcePath=~q.\..\..\..\..\Assets\monkey\" + f + "~q DestinationPath=~q\data\" + f +"~q Include=~q*.*~q />~n"	
'		Endif

		

	'	If parent.Length
		If (FileType(rootDataPath) = FILETYPE_DIR)
				If str2.Length() xml_data = "<FileGroup SourcePath=~q.\..\..\..\..\" + str + "~q DestinationPath=~q\data\" + str2 + "\" + "~q Include=~q*.*~q />~n"
				Else  xml_data = "<FileGroup SourcePath=~q.\..\..\..\..\" + str + "~q DestinationPath=~q\data\" + "~q Include=~q*.*~q />~n"
		Endif
	'	Else
	'		xml_data= "<FileGroup SourcePath=~q.\..\..\..\..\Assets\monkey\" + f + "~q DestinationPath=~q\data\" + "~q Include=~q*.*~q />~n"
	'	Endif

		
	'	For Local child:= EachIn LoadDir(rootDataPath + "\" + f)		
		For Local child:= EachIn LoadDir(rootDataPath)

	'		If (FileType(rootDataPath+"\" +f + "\" +child) = FILETYPE_DIR)
			If (FileType(rootDataPath + "\" + child) = FILETYPE_DIR)
				Print "[RecurseFolderAndAddPackageDirectory] Entering folder : " +  rootDataPath +"\"+ child
				'xml_data += RecurseFolderAndAddPackageDirectory(rootDataPath +"\"+ f + "\" + child, child, f)
				Local additionalPath:= RecurseFolderAndAddPackageDirectory(rootDataPath + "\" + child, child, f)
				Print "Checking  " + additionalPath
				If (DirHasFiles(additionalPath))
					xml_data += additionalPath
					Print "Adding " + additionalPath
				EndIf
			End
		End
		
		Return xml_data;
	End
	
	Method DirHasFiles:Bool(rootDataPath:String)
		For Local child:= EachIn LoadDir(rootDataPath)
			If (FileType(rootDataPath + "\" + child) = FILETYPE_FILE)
				Return True
			EndIf
		End
		Return False
	End
	
	Method RecurseFolderAndAdd:String(rootPath:String, currPath:String, f:String)
		
		' First add the entry and then recurse
		rootPath = rootPath.Replace("/", "\")
		currPath = currPath.Replace("/", "\")
		
		Local xml_data:= "<path source=~q" + rootPath + "\" + currPath + "~q" + " target=~q\data" + currPath + "~q/>~n"

		For Local child:= EachIn LoadDir(f)
		
			If (FileType(child) = FILETYPE_DIR)
				xml_data += RecurseFolderAndAdd(rootPath, currPath + child, child)
			End
		End
		
		Return xml_data;
		
	End
	
	Method CreatePullMappingFile(rootDataPath:String)
		Local pull_map_xml:String
		pull_map_xml = "<?xml version=~q1.0~q?>~n"
		pull_map_xml += "<mappings>~n"
		
		rootDataPath = rootDataPath.Replace("/", "\")

		pull_map_xml += "<path source=~q" + rootDataPath + "~q" + " target=~q" + "\data~q />~n"
		
		Local fOut:= StripExt(tcc.opt_srcpath) + ".build\xboxone\pull_map.xml"
	
		
	'	For Local f:= EachIn LoadDir(rootDataPath)
	'		If (FileType(rootDataPath + "\" + f) = FILETYPE_DIR)
	'			pull_map_xml += RecurseFolderAndAdd(rootDataPath, f, f)
	'		EndIf
	'	End

		'End of file
		pull_map_xml += "</mappings>"
	

		Print "*********************************************************************************"
		Print "Saving pull mapping file : " + fOut
		Print "*********************************************************************************"
				
		SaveString pull_map_xml, fOut
	End
	

	'This will only create one big chunk for 2 dark, ideally we would design a small tool to produce chunk split scheme	
	'or maybe you should satisfy about file granularity of xone updates.

	Method CreatePackageMappingFile(rootDataPath:String)

		Local pull_map_xml:String
	
		pull_map_xml = "<Package>~n<Chunk Id=~q1000~q Marker=~qLaunch~q>~n"
		pull_map_xml += "<FileGroup DestinationPath=~q\~q SourcePath=~q.\~q Include=~q*.bin~q />~n"
		pull_map_xml += "<FileGroup DestinationPath=~q\~q SourcePath=~q.\~q Include=~q*.png~q />~n"
		pull_map_xml += "<FileGroup DestinationPath=~q\~q SourcePath=~q.\~q Include=~q*.xml~q />~n"
		pull_map_xml += "<FileGroup DestinationPath=~q\~q SourcePath=~q.\~q Include=~q*.pri~q />~n"
		pull_map_xml += "<FileGroup DestinationPath=~q\~q SourcePath=~q.\~q Include=~q*.exe~q />~n"
		
			

		rootDataPath = rootDataPath.Replace("/", "\")

		Print "[AddRootFolder content] "
		pull_map_xml += "<FileGroup DestinationPath=~q\data\~q SourcePath=~q.\..\..\..\..\Assets\monkey\~q Include=~q*.*~q />~n"
	
		pull_map_xml += "</Chunk>~n"

		
		Print "*********************************************************************************"
		Print "Scanning package mapping directories in : " + rootDataPath
		Print "*********************************************************************************"
	
		pull_map_xml += "<Chunk Id=~q1001~q>~n"
	
		For Local f:= EachIn LoadDir(rootDataPath)	
			If (FileType(rootDataPath + "\" + f) = FILETYPE_DIR)
				Print "[AddFolder] " + f
	'			pull_map_xml += "<FileGroup DestinationPath=~q\data\" + f + "~q SourcePath=~q.\..\..\..\..\Assets\monkey\" + f + "~q Include=~q*.*~q />~n"
				'pull_map_xml += RecurseFolderAndAddPackageDirectory(rootDataPath, f, "")
				pull_map_xml += RecurseFolderAndAddPackageDirectory2(rootDataPath)
			EndIf
		End

	'	pull_map_xml += "<FileGroup DestinationPath=~q\data" + "~q SourcePath=~q.\..\..\..\..\" + "~q Include=~q*.*~q />~n"
		pull_map_xml += "</Chunk>~n"
		
		Local fOut:= StripExt(tcc.opt_srcpath) + ".build\xboxone\package_map.xml"
	
		pull_map_xml += "<Chunk Id=~q1073741823~q>~n"
		pull_map_xml += "<FileGroup DestinationPath=~q\xonesys~q SourcePath=~q.\..\..\..\..\xonesys~q Include=~qUpdate.AlignmentChunk~q/>~n"
		pull_map_xml += "</Chunk>~n"
		pull_map_xml += "</Package>~n"
	

		Print "*********************************************************************************"
		Print "Saving package mapping file : " + fOut
		Print "*********************************************************************************"
				
		SaveString pull_map_xml, fOut
	End
	
	Method Make:Void()
		If tcc.opt_clean
			Print "Killing XBox related processes"			
			Local ret:Int = Execute("taskkill /F /IM xbrdevicesrv.exe", False)
			ret = Execute("taskkill /F /IM Microsoft.Durango.TransportProxy.exe", False)
			ret = Execute("taskkill /F /FI ~qIMAGENAME eq Microsoft.Durango *~q", False)
		EndIf
		Super.Make
	End
	
	Method ExecCommand(cmdString:String)
		'Local cmdSz:String = "xcopy " + buildDataPath + "/xboxone/Assets/monkey/*.fraghlslo " + rootDataPath + "/"
		
		cmdString = cmdString.Replace("/", "\")
		cmdString = cmdString + " /Y"
		Print(cmdString)
		Execute cmdString
	End
		
	Method MakeTarget:Void()
	
		'Compile shader only if outdated...
		Local rootDataPath:= StripExt(tcc.opt_srcpath) + ".data"
		Local buildDataPath:= StripExt(tcc.opt_srcpath) + ".build"
		
		'Print "Deploying mojo shader sources"
		'ExecCommand("xcopy " + buildDataPath + "/xboxone/Assets/monkey/*.fraghlslo " + rootDataPath + "/")
		'ExecCommand("xcopy " + buildDataPath + "/xboxone/Assets/monkey/*.verthlslo " + rootDataPath + "/")
		ExecCommand("xcopy " + buildDataPath + "/xboxone/Shaders/*.fraghlsl " + rootDataPath + "/")
		ExecCommand("xcopy " + buildDataPath + "/xboxone/Shaders/*.verthlsl " + rootDataPath + "/")
		ExecCommand("xcopy " + buildDataPath + "/xboxone/Shaders/glsl_typedefs.h " + rootDataPath + "/")
		
		CompileShaders rootDataPath, False
	
		CreateDataDir "Assets/monkey"
	
	
		Select HostOS
		Case "winnt"
			MakeVc2012
		End
		
	

	End
	
	
	
End

Class ReturnRecurse
	Field xml_data:String
	Field has
End