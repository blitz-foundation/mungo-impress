
Import transcc
Import reflection.reflector
Import brl.json

Class Builder

	'deprecated
	Method New( tcc:TransCC )
		Self.tcc=tcc
	End
	
	Method Load:Void( tcc:TransCC )
		Self.tcc=tcc
	End
	
	Method IsValid:Bool() Abstract
	
	Method Begin:Void() Abstract
	
	Method MakeTarget:Void() Abstract
	
	
	Method Make:Void()
	
		Select tcc.opt_config
		Case "","debug"
			tcc.opt_config="debug"
			casedConfig="Debug"
		Case "release" 
			casedConfig="Release"
		Default
			Die "Invalid config"
		End
	
		If FileType( tcc.opt_srcpath )<>FILETYPE_FILE Die "Invalid source file"
		tcc.opt_srcpath=RealPath( tcc.opt_srcpath )

		If Not tcc.opt_modpath tcc.opt_modpath=tcc.monkeydir+"/modules"

		tcc.opt_modpath=".;"+ExtractDir( tcc.opt_srcpath )+";"+tcc.opt_modpath+";"+tcc.target.abspath+"/modules"
		
		ENV_HOST=HostOS
		ENV_CONFIG=tcc.opt_config
		ENV_SAFEMODE = tcc.opt_safe
		ENV_MODPATH=tcc.opt_modpath
		ENV_TARGET=tcc.target.system
			
		Self.Begin

		'***** TRANSLATE *****

		Print "Parsing..."
		
		SetConfigVar "HOST",ENV_HOST
		SetConfigVar "LANG",ENV_LANG
		SetConfigVar "TARGET",ENV_TARGET
		SetConfigVar "CONFIG",ENV_CONFIG
		SetConfigVar "SAFEMODE",ENV_SAFEMODE
		SetConfigVar "MUNGO","1"
		
		Local buildPath:String
		
		If tcc.opt_builddir
			buildPath=ExtractDir( tcc.opt_srcpath )+"/"+tcc.opt_builddir
		Else
			buildPath = StripExt( tcc.opt_srcpath )+".build"
		Endif
		
		Local targetPath:= buildPath + "/" + tcc.target.dir	'ENV_TARGET
		
		Local buildMetaPath:String
		Local buildMetaData:JsonObject = Null
		
		If Not tcc.opt_builddir
			buildMetaPath = buildPath + "/build.meta.json"
			
			If FileType(buildMetaPath) = FILETYPE_FILE
				buildMetaData = New JsonObject(LoadString(buildMetaPath))
			End
			
			If FileType(targetPath) = FILETYPE_DIR
				If buildMetaData
					Local targets:=JsonObject(buildMetaData.Get("targets"))
					
					If targets And targets.GetString(tcc.target.name) <> tcc.target.version
						CopyDir(targetPath,targetPath + ".old-v" + targets.GetString(tcc.target.name), True, True)
						DeleteDir(targetPath, True)						
					End						
				Else
					Local oldTargetPath:=targetPath + ".old"
					
					If FileType(oldTargetPath) <> FILETYPE_NONE
						Local i:Int = 1
						
						While FileType(oldTargetPath + i) <> FILETYPE_NONE
							i += 1
						Wend
						
						oldTargetPath += i
					End	
					
					CopyDir(targetPath,oldTargetPath, True, True)
					DeleteDir(targetPath, True)				
				End
			End
			
			If Not buildMetaData 
				buildMetaData = New JsonObject()
			End
			
			Local targets := JsonObject(buildMetaData.Get("targets"))
			
			If Not targets
				targets = New JsonObject()
				buildMetaData.Set("targets", targets)
			End
			
			targets.SetString(tcc.target.name, tcc.target.version)
		End
				
		Local cfgPath:= targetPath + "/CONFIG.MONKEY"
		
		If FileType(cfgPath) = FILETYPE_FILE
			PreProcess cfgPath, Null, True
			
		ElseIf FileType(targetPath) <> FILETYPE_DIR 'first build
			cfgPath = tcc.target.abspath + "/template/CONFIG.MONKEY"
			If FileType(cfgPath) = FILETYPE_FILE PreProcess cfgPath, Null, True
		End
		
		app=ParseApp( tcc.opt_srcpath )

		If tcc.opt_run = True Or tcc.opt_build = True
			Print "Semanting..."
			If GetConfigVar("REFLECTION_FILTER")
				Local r:=New Reflector
				r.Semant app
			Else
				app.Semant
			EndIf
		
			Print "Translating..."
			Local transbuf:=New StringStack
			For Local file:String = Eachin app.fileImports
				If ExtractExt( file ).ToLower()=ENV_LANG
					transbuf.Push LoadString( file )
					transbuf.Push "~n"
				Endif
			Next
			transbuf.Push _trans.TransApp(app)
			
			'***** UPDATE *****
			'If Not tcc.opt_update Return
		
			Print "Building..."

			transCode = transbuf.Join()
			
		EndIf
		
	

		If tcc.opt_clean
			Print "Deleting: " + targetPath
			DeleteDir targetPath, True
			If FileType( targetPath )<>FILETYPE_NONE Die "Failed to clean target dir"
		EndIf

		If FileType(targetPath) = FILETYPE_NONE
			If FileType( buildPath ) = FILETYPE_NONE CreateDir buildPath			
			If FileType( buildPath )<>FILETYPE_DIR Die "Failed to create build dir: "+buildPath
			
			Print "Copying template folder"
			If Not CopyDir(tcc.target.abspath + "/template", targetPath, True, False)
				Die "Failed to copy template folder"
			End
			
			' Adding project specific files that needs to be added to template folder
			Local projectSpecificTargetFiles_Path:= StripExt(tcc.opt_srcpath) + ".data" + "/target_" + tcc.target.system + "/template"
		
			If FileType(projectSpecificTargetFiles_Path) <> FILETYPE_NONE
				Print "Copying project specific files to template folder, from path:"
				Print projectSpecificTargetFiles_Path
				Print "To path: " + targetPath
				
				If Not CopyDir(projectSpecificTargetFiles_Path, targetPath, True, False)
					Die "Failed to copy target dir"
				End
			Else
				Print "No project specific template folder: " + projectSpecificTargetFiles_Path
			End
		Endif
		
		If FileType( targetPath )<>FILETYPE_DIR Die "Failed to create target dir: "+targetPath
		If buildMetaData Then SaveString(buildMetaData.ToJson(), buildPath + "/build.meta.json")
		
		TEXT_FILES=GetConfigVar( "TEXT_FILES" )
		IMAGE_FILES=GetConfigVar( "IMAGE_FILES" )
		SOUND_FILES=GetConfigVar( "SOUND_FILES" )
		MUSIC_FILES=GetConfigVar( "MUSIC_FILES" )
		BINARY_FILES=GetConfigVar( "BINARY_FILES" )
		SHADER_FILES=GetConfigVar( "SHADER_FILES" )
		
		DATA_FILES=TEXT_FILES
		If IMAGE_FILES DATA_FILES+="|"+IMAGE_FILES
		If SOUND_FILES DATA_FILES+="|"+SOUND_FILES
		If MUSIC_FILES DATA_FILES+="|"+MUSIC_FILES
		If BINARY_FILES DATA_FILES+="|"+BINARY_FILES
		If SHADER_FILES DATA_FILES+="|"+SHADER_FILES
		DATA_FILES=DATA_FILES.Replace( ";","|" )
	
		syncData=GetConfigVar( "FAST_SYNC_PROJECT_DATA" )="1"
		
		Local cd:=CurrentDir

		ChangeDir targetPath		
		Self.MakeTarget
		ChangeDir cd
	End
	
	Field tcc:TransCC
	Field app:AppDecl
	Field transCode:String
	Field casedConfig:String
	Field syncData:Bool
	Field DATA_FILES$
	Field TEXT_FILES$
	Field IMAGE_FILES$
	Field SOUND_FILES$
	Field MUSIC_FILES$
	Field BINARY_FILES$
	Field SHADER_FILES$
	
	Method Execute:Bool( cmd:String,failHard:Bool=True )
		Return tcc.Execute( cmd,failHard )
	End
	
	Method CCopyFile:Void(src:String, dst:String)
		If FileType(dst) <> FILETYPE_NONE
			If FileTime(src) > FileTime(dst) Or FileSize(src) <> FileSize(dst)
				'RemoveReadOnly dst 
				If DeleteFile(dst) = False
					RemoveReadOnly dst ' some files might be locked down (read only) by source control
					DeleteFile(dst)
				EndIf
				CopyFile src, dst
			EndIf
		Else
			CopyFile src, dst
		EndIf
	End
	
	Method CopyShaders:Void(dir:String)
		'Only do that if Run
		If tcc.opt_run = False
			Return
		EndIf
		
		Print "***********************"
		Print "* Refreshing shaders"
		
		Local dataPath:= StripExt(tcc.opt_srcpath) + ".data"
		Local buildDataPath:= StripExt(tcc.opt_srcpath) + ".build/" + tcc.target.dir + "/" + dir
		Print buildDataPath
		If dataPath
		
			Local srcs:=New StringStack
			srcs.Push dataPath
			
			While Not srcs.IsEmpty()
			
				Local src:=srcs.Pop()
				
				For Local f:= EachIn LoadDir(src)
					Local path:= src + "/" + f
				
					Select FileType(path)
						Case FILETYPE_FILE
							If f.EndsWith(".vert") Or f.EndsWith(".frag")
								'Print path
								Local shortPath:= path[dataPath.Length() ..]
								'	Print shortPath
								Local targetPath:= buildDataPath + shortPath
								'Print targetPath
								
								If FileType(targetPath) = FILETYPE_NONE Or FileTime(path) > FileTime(targetPath)
									
									Print "  > Refreshing: " + f
									CCopyFile path, targetPath
								EndIf
							Endif
						Case FILETYPE_DIR
							srcs.Push path
					End
				Next
			
			Wend
		
		Endif
	End
	
	Method CreateDataFileMap:Void(dir:String, dataFileMap:StringMap<String>)
	
		Print "***********************"
		Print "* Creating DataFileMap"
		
		dir = RealPath(dir)
		Local dataPath:= StripExt(tcc.opt_srcpath) + ".data"
		
		If dataPath
		
			Local srcs:=New StringStack
			srcs.Push dataPath
			
			While Not srcs.IsEmpty()
			
				Local src:=srcs.Pop()
				
				For Local f:=Eachin LoadDir( src )
					If f.StartsWith( "." ) Continue

					Local p:=src+"/"+f
					Local r:=p[dataPath.Length+1..]
					Local t:= dir + "/" + r
					
					Select FileType( p )
						Case FILETYPE_FILE
							If MatchPath(r, DATA_FILES)
								dataFileMap.Set p, r
							Endif
						Case FILETYPE_DIR
							Local res:= IsTargetDir(f, t)
							' If Not a target dir or a target dir corresponding to the current target
							If res = 1 Or res = 0
								srcs.Push p
							End
					End
				Next
			
			Wend
		
		Endif
		
		For Local p:= EachIn app.fileImports
			Local r:=StripDir( p )
			If MatchPath(r, DATA_FILES)
				dataFileMap.Set p, r
			Endif
		Next
	End
	
	Method CreateDataDir:Void(dir:String)
	
		dir = RealPath(dir)
		
		Local dirExists:= FileType(dir) = FILETYPE_DIR
		
		'Build data Dir only If Run or if no data dir
		If (tcc.opt_run)
			If (dirExists = True) And (tcc.FORCE_UPDATE_DATA_DIR <> "True")
				Return
			EndIf
		EndIf
		
		If dirExists = False
			Print "Creating data dir in " + dir
		Else
			Print "Updating data dir in " + dir
		EndIf
		
		If Not syncData DeleteDir dir, True
		CreateDir dir
		
		If FileType( dir )<>FILETYPE_DIR Die "Failed to create target project data dir: "+dir
		
		Local dataPath:= StripExt(tcc.opt_srcpath) + ".data"
		If FileType( dataPath )<>FILETYPE_DIR dataPath=""
		
		'all used data...
		Local udata:=New StringSet
		
		'Copy data from monkey project to target project
		If dataPath
		
			Local srcs:=New StringStack
			srcs.Push dataPath
			
			While Not srcs.IsEmpty()
			
				Local src:=srcs.Pop()
				
				For Local f:=Eachin LoadDir( src )
					If f.StartsWith( "." ) Continue

					Local p:=src+"/"+f
					Local r:=p[dataPath.Length+1..]
					Local t:=dir+"/"+r
					
					Select FileType( p )
					Case FILETYPE_FILE
						If MatchPath(r, DATA_FILES)
							'Print "Copying " + p + " to " + t
							CCopyFile p,t
							udata.Insert t
						
						Endif
					Case FILETYPE_DIR
						Local res:= IsTargetDir(f, t)
						' If Not a target dir or a target dir corresponding to the current target
						If res = 1 Or res = 0
							CreateDir t
							srcs.Push p
						End
					End
				Next
			
			Wend
		
		Endif
		
		'Copy dodgy module data imports...
		For Local p:=Eachin app.fileImports
			Local r:=StripDir( p )
			Local t:=dir+"/"+r
			If MatchPath( r,DATA_FILES )
				CCopyFile p,t
				udata.Insert t
				
			Endif
		Next
		
		'Clean up...delete data in target project not in monkey project.
		If dataPath
		
			Local dsts:=New StringStack
			dsts.Push dir
			
			While Not dsts.IsEmpty()
				
				Local dst:=dsts.Pop()
				
				For Local f:=Eachin LoadDir( dst )
					If f.StartsWith( "." ) Continue
	
					Local p:=dst+"/"+f
					Local r:=p[dir.Length+1..]
					Local t:=dataPath+"/"+r
					
					Select FileType( p )
					Case FILETYPE_FILE
						If Not udata.Contains( p )
							DeleteFile p
						Endif
					Case FILETYPE_DIR
						If FileType( t )=FILETYPE_DIR
							dsts.Push p
						Else
							DeleteDir p,True
						Endif
					End
				Next
				
			Wend
		End
	End
	
	Method IsTargetDir:int(dirName:String, path:String)
		Local targetDirName:= "target_" + tcc.target.system
		If dirName = targetDirName
			Return 1
		ElseIf dirName.StartsWith("target_")
			Return 2
		ElseIf path.EndsWith(targetDirName + "/template")
			Return 3
		End
		Return 0
	End
	
End

Class BuilderRequirement
	
	Const PATH:Int = 0
	Const TOOL:Int = 1

	Field key:String
	Field value:String
	Field type:Int
	
	Method New(key:String, type:Int = PATH)
		Self.key = key
		Self.type = type
	End Method
	
	Method ToString:String()
		Return value
	End Method

End Class
