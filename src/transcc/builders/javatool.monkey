Strict

Import builder

Class JavaToolJavaTranslator Extends JavaTranslator
	' UGLY!!!
	Global _osExterns := New StringStack(["HostOS", "AppPath", "AppArgs", "RealPath", "FileType", "FileSize", "FileTime", "CopyFile", "DeleteFile", "LoadString", "SaveString", "LoadDir", "CreateDir", "DeleteDir", "ChangeDir", "CurrentDir", "SetEnv", "GetEnv", "Execute", "ExitApp"])

	Method TransStatic$(decl:Decl)
		Local r := Super.TransStatic(decl)
		If decl.IsExtern() And ModuleDecl(decl.scope)
			If _osExterns.Find(r) > -1 Then
				Return "JavaToolOS."+r
			Else
				Return r
			End If
		Else
			Return r
		End If
	End Method
End Class

Class ParseStringJavaTranslator Extends JavaToolJavaTranslator
	Method TransCastExpr$(expr:CastExpr)
		Local result:=Super.TransCastExpr(expr)

		If result.Find("Integer.parseInt(") = 0 Then
			result = "JavaToolHelper.ParseInt("+result[17..]
		Else If result.Find("Float.parseFloat(") = 0 Then
			result = "JavaToolHelper.ParseFloat("+result[17..]
		End If

		Return result
	End Method
End Class

Class JavaToolBuilder Extends Builder

	Method New(tcc:TransCC)
		Super.New(tcc)
	End Method

	Method Config:String()
		Local config := New StringStack
		For Local kv := Eachin GetConfigVars()
			config.Push("static final String " + kv.Key + "=" + Enquote(kv.Value, "java") + ";")
		Next
		Return config.Join("~n")
	End Method

	Method IsValid:Bool()
		Return True 'tcc.JDK_PATH<>""
	End Method

	Method Begin:Void()
		ENV_LANG = "java"

		If GetConfigVar("JAVATOOL_STRING_PARSE_STYLE") = "cpp" Then
			_trans = New ParseStringJavaTranslator
		Else
			_trans = New JavaToolJavaTranslator
		End If
	End Method

	Method AddBinToPath:Void()
		Local path := GetEnv("PATH")
		
		If tcc.JDK_PATH <> "" Then
			path = tcc.JDK_PATH + "/bin:" + path
		End If
		
		SetEnv("PATH",path)
	End Method
	
	Method MakeTarget:Void()
		If GetConfigVar("JAVATOOL_BRL_GAMETARGET") Then
			CreateDataDir("assets")
		End If

		AddBinToPath()

		Select ENV_CONFIG
		Case "debug" 
			SetConfigVar("DEBUG", "1")

		Case "release" 
			SetConfigVar("RELEASE", "1")

		End Select

		Local package := GetConfigVar("JAVATOOL_PACKAGE")

		Local srcMainClass := package + ".Main"
		SetConfigVar("JAVATOOL_MAIN_CLASS", srcMainClass)

		'output dir
		Local outPath := "out"
		DeleteDir(outPath, True)
		CreateDir(outPath)

		'create package
		Local srcMainPath := "src"
		DeleteDir(srcMainPath, True)
		CreateDir(srcMainPath)
		For Local t := EachIn package.Split(".")
			srcMainPath += "/"+t
			DeleteDir(srcMainPath, True)
			CreateDir(srcMainPath)
		Next
		srcMainPath += "/Main.java"

		'template files
		For Local file := EachIn LoadDir("templates", True)

			'Recursive CreateDir...	
			Local i := 0
			Repeat
				i=file.Find("/", i)

				If i=-1 Then
					Exit
				End If

				CreateDir(file[..i])

				If FileType(file[..i]) <> FILETYPE_DIR Then
					file=""
					Exit
				End If

				i+=1
			Forever

			If Not file Then
				Continue
			End If

			Select ExtractExt(file).ToLower()
			Case "xml", "properties", "java", "mf"
				Local str := LoadString("templates/" + file)
				str = ReplaceEnv(str)
				SaveString(str, file)

			Default
				CopyFile("templates/" + file, file)

			End Select
		Next

		'create main source file
		Local main := LoadString("Main.java")
		main=ReplaceBlock(main, "TRANSCODE", transCode)
		main=ReplaceBlock(main, "CONFIG", Config())

		'extract all imports
		Local imps := New StringStack()
		Local done := New StringSet()
		Local out := New StringStack()
		For Local line := Eachin main.Split("~n")
			If line.StartsWith("import ") Then
				Local i := line.Find(";", 7)
				If i<>-1 Then
					Local id := line[7..i+1]
					If Not done.Contains(id) Then
						done.Insert(id)
						imps.Push("import " + id)
					End If
				End If
			Else
				out.Push(line)
			End If
		End
		main = out.Join("~n")

		main = ReplaceBlock(main, "IMPORTS", imps.Join("~n"))
		main = ReplaceBlock(main, "PACKAGE", "package " + package + ";")

		SaveString(main, srcMainPath)

		If tcc.opt_build Then

			Local out := "main.jar"
			DeleteFile out

			Local compilerOpts := ""

			Select ENV_CONFIG
			Case "debug"
				compilerOpts += " -g"
			End Select

			Local javac_opts := GetConfigVar("JAVAC_OPTS")
			If javac_opts Then
				compilerOpts += " " + javac_opts.Replace(";", " ")
			End If

			If Not Execute("javac " + compilerOpts + " -sourcepath ./src -d " + outPath + " " + srcMainPath) Then
				Die("Java build failed.")
			End If

			If Not Execute("jar cfm " + out + " manifest.mf -C "+outPath+" .") Then
				Die("Can't create JAR archive.")
			End If

			If tcc.opt_run Then
				Execute("java -jar ~q" + RealPath(out) + "~q")
			End If
		End If
	End Method

End Class

