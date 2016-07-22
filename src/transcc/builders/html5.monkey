
Import builder

Import brl.filestream

Private

Global Info_Width:Int
Global Info_Height:Int

Function GetInfo_PNG:Int( path:String )
	Local f:=FileStream.Open( path,"r" )
	If f
		Local data:=New DataBuffer( 32 )
		Local n:=f.Read( data,0,24 )
		f.Close
		If n=24 And data.PeekByte(1)="P"[0] And data.PeekByte(2)="N"[0] And data.PeekByte(3)="G"[0]
			Info_Width=(data.PeekByte(16)&255) Shl 24 | (data.PeekByte(17)&255) Shl 16 | (data.PeekByte(18)&255) Shl 8 | (data.PeekByte(19)&255)
			Info_Height=(data.PeekByte(20)&255) Shl 24 | (data.PeekByte(21)&255) Shl 16 | (data.PeekByte(22)&255) Shl 8 | (data.PeekByte(23)&255)
			Return 0
		Endif
	Endif
	Return -1
End

Function GetInfo_GIF:Int( path:String )
	Local f:=FileStream.Open( path,"r" )
	If f
		Local data:=New DataBuffer( 32 )
		Local n:=f.Read( data,0,10 )
		f.Close
		If n=10 And data.PeekByte(0)="G"[0] And data.PeekByte(1)="I"[0] And data.PeekByte(2)="F"[0]
			Info_Width=(data.PeekByte(7)&255) Shl 8 | (data.PeekByte(6)&255)
			Info_Height=(data.PeekByte(9)&255) Shl 8 | (data.PeekByte(8)&255)
			Return 0
		Endif
	Endif
	Return -1
End

Function GetInfo_JPG:Int( path:String )
	Local f:=FileStream.Open( path,"r" )
	If f
		Local buf:=New DataBuffer( 32 )
		
		If f.Read( buf,0,2 )=2 And (buf.PeekByte(0)&255)=$ff And (buf.PeekByte(1)&255)=$d8
			Repeat

				While f.Read( buf,0,1 )=1  And (buf.PeekByte(0)&255)<>$ff
				Wend
				If f.Eof() Exit
				
				While f.Read( buf,0,1 )=1  And (buf.PeekByte(0)&255)=$ff
				Wend
				If f.Eof() Exit

				Local marker:=buf.PeekByte(0)&255
				Select marker
				Case $d0,$d1,$d2,$d3,$d4,$d5,$d6,$d7,$d8,$d9,$00,$ff
					Continue
				End

				If f.Read( buf,0,2 )<>2 Exit
				Local datalen:=((buf.PeekByte(0)&255) Shl 8 | (buf.PeekByte(1)&255))-2
				
				Select marker
				Case $c0,$c1,$c2,$c3
					If datalen And f.Read( buf,0,5 )=5
						Local bpp:=buf.PeekByte(0)&255
						Info_Width=(buf.PeekByte(3)&255) Shl 8 | (buf.PeekByte(4)&255)
						Info_Height=(buf.PeekByte(1)&255) Shl 8 | (buf.PeekByte(2)&255)
						f.Close
						Return 0
					Endif
				End
				
				Local pos:=f.Position+datalen
				If f.Seek( pos )<>pos Exit
				
			Forever
		Endif
		f.Close
	Endif
	Return -1
End

Public

Class Html5Builder Extends Builder

	Method New( tcc:TransCC )
		Super.New( tcc )
	End
	
	Method Config:String()
		Local config:=New StringStack
		For Local kv:=Eachin GetConfigVars()
			config.Push "var CFG_"+kv.Key+"="+Enquote( kv.Value,"js" )+";"
		Next
		Return config.Join( "~n" )
	End
	
	Method Exports:String()
		Local exports:=New StringStack
		
		'two empty lines just for pretty
		exports.Push ""
		exports.Push ""
		
		exports.Push "window['bbMain']=bbMain;"
		exports.Push "window['bbInit']=bbInit;"
		
		exports.Push "window['BBMonkeyGame']=BBMonkeyGame;"
		exports.Push "BBMonkeyGame['Main']=BBMonkeyGame.Main;"
		
		exports.Push "window['CFG_HTML5_WEBAUDIO_ENABLED']=CFG_HTML5_WEBAUDIO_ENABLED;"
		
		If GetConfigVar("HTML5_PRELOADER_ENABLED") = "1"	
			exports.Push "window['CFG_HTML5_PRELOADER_ENABLED']=CFG_HTML5_PRELOADER_ENABLED;"
		End If			
		
		If GetConfigVar("HTML5_SOUND_PRELOADING_ORDER")
			exports.Push "window['CFG_HTML5_SOUND_PRELOADING_ORDER']=CFG_HTML5_SOUND_PRELOADING_ORDER;"
		End If
		
		Return exports.Join( "~n" )
	End Method
	
	Method MetaData:String(dataFileMap:StringMap<String>)
		Local meta:=New StringStack
		For Local kv:= EachIn dataFileMap
			Local src:=kv.Key
			Local ext:=ExtractExt( src ).ToLower()
			Select ext
			Case "png","jpg","gif"
				Info_Width=0
				Info_Height=0
				Select ext
				Case "png"
					If GetInfo_PNG(src) < 0
						If GetInfo_GIF(src) < 0
							GetInfo_JPG(src)
						End
					End
					
				Case "jpg"
					If GetInfo_JPG(src) < 0
						If GetInfo_PNG(src) < 0
							GetInfo_GIF(src)
						End
					End
					
				Case "gif"
					If GetInfo_GIF(src) < 0
						If GetInfo_PNG(src) < 0
							GetInfo_JPG(src)
						End
					End
				End
				If Info_Width=0 Or Info_Height=0 Die "Unable to load image file '"+src+"'."
				meta.Push "["+kv.Value+"];type=image/"+ext+";"
				meta.Push "width="+Info_Width+";"
				meta.Push "height="+Info_Height+";"
				meta.Push "size=" + FileSize(src) + ";"
				meta.Push "\n"

			Case "wav","ogg","mp3","m4a"
				If ext="mp3" ext="mpeg"
				If ext="m4a" ext="x-m4a"
			
				meta.Push "[" + kv.Value + "];type=audio/" + ext + ";"
				meta.Push "size=" + FileSize(src) + ";"
				meta.Push "\n"

			End
		Next
		Return meta.Join("")
	End

	Method IsValid:Bool()
		Return True
	End
	
	Method Begin:Void()
		ENV_LANG="js"
		_trans=New JsTranslator
	End
	
	Method Make:Void()
		If tcc.opt_clean
			Print "Killing HTML5 related processes"
			Execute("taskkill /F /IM mserver_winnt.exe", False)
		EndIf
		Super.Make
	End
	

	
	
	
	Method MakeTarget:Void()

		CreateDataDir "data"
		
		CopyShaders "data"
		
		Local dataFileMap:StringMap<String> = New StringMap<String>
		CreateDataFileMap "data", dataFileMap
	
		If tcc.opt_update = False
			Local meta:= "window['META_DATA']=~q" + MetaData(dataFileMap) + "~q;~n"
			
			If ENV_CONFIG = "release" And GetConfigVar("HTML5_OPTIMIZE_OUTPUT") = "1" And ExtractExt(tcc.CLOSURE_COMPILER)[ .. - 1] = "jar"
				Local main:= LoadString("main.uncompressed.js")
				
				If Not main
					main = LoadString("main.js")
				End If
				
				main = ReplaceBlock(main, "TRANSCODE", transCode + Exports())
				main = ReplaceBlock(main, "METADATA", meta)
				main = ReplaceBlock(main, "CONFIG", Config())
				
				SaveString main, "main.uncompressed.js"
				
				Local closureFlags:=""
				Local optimizationLevel:=GetConfigVar("HTML5_OPTIMIZATION_LEVEL")
				
				If Not optimizationLevel
					optimizationLevel = "simple"
				End If
				
				If optimizationLevel = "advanced"
					Local externs:=LoadDir("closure/externs")
					
					For Local extrn:= EachIn externs
						closureFlags += " --externs closure/externs/"+StripDir(extrn)
					Next
				End If
				
				If (GetConfigVar("HTML5_OPTIMIZATION_FLAGS")) Then
					closureFlags += " " + GetConfigVar("HTML5_OPTIMIZATION_FLAGS")
				End If
			
				Print "Optimize output..."
				Execute "java -jar ~q" + tcc.CLOSURE_COMPILER + "~q --compilation_level " + optimizationLevel.ToUpper() + "_OPTIMIZATIONS --language_in=ECMASCRIPT5 --language_out=ECMASCRIPT5_STRICT --warning_level QUIET " + closureFlags + " --js main.uncompressed.js --js_output_file main.js", False
			Else
				Local main:String
			
				If FileType("main.uncompressed.js") <> FILETYPE_NONE
					main = LoadString("main.uncompressed.js")
					DeleteFile("main.uncompressed.js")
				Else
					main = LoadString("main.js")
				EndIf
			
				main=ReplaceBlock( main,"TRANSCODE",transCode )
				main=ReplaceBlock( main,"METADATA",meta )
				main=ReplaceBlock( main,"CONFIG",Config() )
				
				SaveString main, "main.js"
			EndIf
			
			Local template:String = LoadString("templates/default.html")
			
			If GetConfigVar("HTML5_PRELOADER_ENABLED") = "1"
				Local preloader:String = LoadString("preloader.js")
				
				Local preloaderMeta:StringStack = New StringStack()
				preloaderMeta.Push("MAINJS_FILESIZE:" + FileSize("main.js"))
				
				preloader = ReplaceBlock(preloader, "METADATA", "var PRELOADER_METADATA={" + preloaderMeta.Join(",") + "};")
				
				SaveString(preloader, "preloader.js")
				
				template = ReplaceBlock(template, "BOOTSTRAP", "<script src=~qpreloader.js~q></script>", "~n<!--")
			Else
				template = ReplaceBlock(template, "BOOTSTRAP", "<script src=~qmain.js~q></script>", "~n<!--")
			EndIf
			template = ReplaceEnv(template)
			SaveString(template, "MonkeyGame.html")
		EndIf
		
	
		
		If tcc.opt_run
			Local p:=RealPath( "MonkeyGame.html" )
			Local t:= tcc.HTML_PLAYER + " ~q" + p + "~q"
			Print "Executing..."
			Execute t,False
		Endif
	End
	
End