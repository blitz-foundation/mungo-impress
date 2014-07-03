
Import transcc
Import reflection.reflector
Import brl.json

Class Builder

	Method New( tcc:TransCC )
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
		
		If Not tcc.opt_check
			tcc.opt_check=True
			tcc.opt_update=True
			tcc.opt_build=True
		Endif
		
		ENV_HOST=HostOS
		ENV_CONFIG=tcc.opt_config
		ENV_SAFEMODE=tcc.opt_safe
		ENV_MODPATH=tcc.opt_modpath
		ENV_TARGET=tcc.target.system
			
		Self.Begin

		'***** TRANSLATE *****
		If Not tcc.opt_check Return

		Print "Parsing..."
		
		SetConfigVar "HOST",ENV_HOST
		SetConfigVar "LANG",ENV_LANG
		SetConfigVar "TARGET",ENV_TARGET
		SetConfigVar "CONFIG",ENV_CONFIG
		SetConfigVar "SAFEMODE",ENV_SAFEMODE
		
		Local buildPath:String
		
		If tcc.opt_builddir
			buildPath=ExtractDir( tcc.opt_srcpath )+"/"+tcc.opt_builddir
		Else
			buildPath = StripExt( tcc.opt_srcpath )+".build"
		Endif
		
		Local targetPath:= buildPath + "/" + tcc.target.dir	'ENV_TARGET
		
		If Not tcc.opt_builddir
			Local buildMetaPath:String = buildPath + "/build.meta.json"
			Local buildMetaData:JsonObject = Null
			
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
			If FileType( buildPath ) = FILETYPE_NONE CreateDir buildPath
			SaveString(buildMetaData.ToJson(), buildPath + "/build.meta.json")
		End
				
		Local cfgPath:= targetPath + "/CONFIG.MONKEY"
		
		If FileType(cfgPath) = FILETYPE_FILE
			PreProcess cfgPath, "", True
			
		ElseIf FileType(targetPath) <> FILETYPE_DIR 'first build
			cfgPath = tcc.target.abspath + "/template/CONFIG.MONKEY"
			If FileType(cfgPath) = FILETYPE_FILE PreProcess cfgPath, "", True
		End
		
		app=ParseApp( tcc.opt_srcpath )

		Print "Semanting..."
		If GetConfigVar("REFLECTION_FILTER")
			Local r:=New Reflector
			r.Semant app
		Else
			app.Semant
		Endif
		
		Print "Translating..."
		Local transbuf:=New StringStack
		For Local file:String = Eachin app.fileImports
			If ExtractExt( file ).ToLower()=ENV_LANG
				transbuf.Push LoadString( file )
				transbuf.Push "~n"
			Endif
		Next
		transbuf.Push _trans.TransApp( app )
		
		'***** UPDATE *****
		If Not tcc.opt_update Return
		
		Print "Building..."

		transCode=transbuf.Join()

		If tcc.opt_clean
			DeleteDir targetPath,True
			If FileType( targetPath )<>FILETYPE_NONE Die "Failed to clean target dir"
		Endif

		If FileType( targetPath ) = FILETYPE_NONE
			If FileType( buildPath ) = FILETYPE_NONE CreateDir buildPath
			If FileType( buildPath )<>FILETYPE_DIR Die "Failed to create build dir: "+buildPath
			If Not CopyDir(tcc.target.abspath + "/template", targetPath, True, False) Die "Failed to copy target dir"
		Endif
		If FileType( targetPath )<>FILETYPE_DIR Die "Failed to create target dir: "+targetPath
		
		TEXT_FILES=GetConfigVar( "TEXT_FILES" )
		IMAGE_FILES=GetConfigVar( "IMAGE_FILES" )
		SOUND_FILES=GetConfigVar( "SOUND_FILES" )
		MUSIC_FILES=GetConfigVar( "MUSIC_FILES" )
		BINARY_FILES=GetConfigVar( "BINARY_FILES" )
		
		DATA_FILES=TEXT_FILES
		If IMAGE_FILES DATA_FILES+="|"+IMAGE_FILES
		If SOUND_FILES DATA_FILES+="|"+SOUND_FILES
		If MUSIC_FILES DATA_FILES+="|"+MUSIC_FILES
		If BINARY_FILES DATA_FILES+="|"+BINARY_FILES
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
	Field dataFiles:=New StringMap<String>	'maps real src path to virtual target path
	Field syncData:Bool
	Field DATA_FILES$
	Field TEXT_FILES$
	Field IMAGE_FILES$
	Field SOUND_FILES$
	Field MUSIC_FILES$
	Field BINARY_FILES$
	
	Method Execute:Bool( cmd:String,failHard:Bool=True )
		Return tcc.Execute( cmd,failHard )
	End
	
	Method CCopyFile:Void( src:String,dst:String )
		If FileTime( src )>FileTime( dst ) Or FileSize( src )<>FileSize( dst )
			DeleteFile dst
			CopyFile src,dst
		Endif
	End
	
	Method CreateDataDir:Void( dir:String )
	
		dir=RealPath( dir )
	
		If Not syncData DeleteDir dir,True
		CreateDir dir
		
		If FileType( dir )<>FILETYPE_DIR Die "Failed to create target project data dir: "+dir
		
		Local dataPath:=StripExt( tcc.opt_srcpath )+".data"
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
						If MatchPath( r,DATA_FILES )
							CCopyFile p,t
							udata.Insert t
							dataFiles.Set p,r
						Endif
					Case FILETYPE_DIR
						CreateDir t
						srcs.Push p
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
				dataFiles.Set p,r
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
	
End
