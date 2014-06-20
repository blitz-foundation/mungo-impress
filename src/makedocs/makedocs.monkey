#If TARGET<>"stdcpp"
#Error "Invalid target"
#Endif

Import os
Import brl.markdown
Import brl.pagemaker
Import brl.json

Import toker
Import apidoccer
Import docsdoccer

Global additional_path:String
Const LANGUAGE_PREFIX:String="lang-"

Class George Implements ILinkResolver,IPrettifier

	Field errinfo:String

	Field styledir:String

	Field pages:=New StringMap<String>					'maps docpath to url
	Field content:=New StringMap<String>				'maps url to html
	Field indexcats:=New StringMap<StringMap<String>>	'maps index categories to indexes
	Field globalDecls:= New StringMap<apidoccer.Decl>

	Field srcdir:String
	Field docbase:String
	
	Field ptoker:=New Toker
	
	Global MonkeyKeywords:=(";Void;Strict;Public;Private;Property;"+
		"Bool;Int;Float;String;Array;Object;Mod;Continue;Exit;"+
		"Include;Import;Module;Extern;"+
		"New;Self;Super;Eachin;True;False;Null;Not;"+
		"Extends;Abstract;Final;Native;Select;Case;Default;"+
		"Const;Local;Global;Field;Method;Function;Class;Interface;Implements;"+
		"And;Or;Shl;Shr;End;If;Then;Else;Elseif;Endif;While;Wend;Repeat;Until;Forever;For;To;Step;Next;Return;Inline;"+
		"Try;Catch;Throw;Throwable;"+
		"Print;Error;Alias;").ToLower()
	
	Method New( styledir:String )
		Self.styledir=styledir
	End
	
	Method SetSrcDir:Void( srcdir:String )
		If Not srcdir.EndsWith( "/" ) srcdir+="/"
		Self.srcdir=srcdir
	End
	
	Method SetDocBase:Void( docbase:String )
		Self.docbase=docbase
	End
	
	Method AddFile:String( path:String )
	
		Local src:=srcdir+path
		Local dst:="docs/html/data/"+StripDir( path )
		
		Local udst:=dst,n:=1
		While FileType( dst )<>FILETYPE_NONE
			n+=1
			udst=dst+"("+n+")"
		Wend
		
		Return "data/"+StripDir( udst )+".html"
	End
	
	Method MakeLink:String( url:String,text:String )
		If Not text text=url
		If url Return "<a href=~q"+url+"~q>"+text+"</a>"
		Return text
	End
	
	Method ResolveLink:String( link:String,text:String )
		
		If link.StartsWith( "#" ) Or link.StartsWith( "http:" ) Or link.StartsWith( "https:" ) Return MakeLink( link,text )
		
		Local url:=""
		Local path:=link,hash:=""
			
		Local i=path.Find( "#" )
		If i<>-1
			hash=path[i..]
			path=path[..i]
		Endif
		
		url=pages.Get( path )
		
		If Not url 
			path=GetIndex( "Index" ).Get( path )
			If path url=pages.Get( path )
		Endif
		
		If url url+=hash
		
		If Not text
			text=StripDir( link )
			Local i:=text.Find( "#" )
			If i<>-1 text=text[i+1..]
		Endif
		
		If Not url Err "Can't find link:"+link
		
		Return MakeLink( url,text )
	End
	
	Method SetErrInfo:Void( errinfo:String )
		Self.errinfo=errinfo
	End
	
	Method Err:Void( msg:String )
		Print errinfo+"  :  "+msg
	End
	
	Method MakeUrl:String( path:String )
		Local url:=path.Replace( "/","_" )
		Local i:=url.Find( "#" )
		If i=-1 Return url+".html"
		Return url[..i]+".html"+url[i..]
	End
	
	Method GetPageUrl:String( path:String )
		Return pages.Get( path )
	End
	
	Method GetIndex:StringMap<String>( cat:String )
		Local index:=indexcats.Get( cat )
		If Not index
			index=New StringMap<String>
			indexcats.Set cat,index
		Endif
		Return index
	End
	
	Method AddPage:Void( path:String,additional:Bool=False )
		If (additional) path = path.Replace("/" + additional_path, "")
	
		If Not additional And pages.Contains( path ) Print "Overwriting page:"+path

		Local url:=MakeUrl( path )
'		Print "Adding page:"+path+" url:"+url

		pages.Set path,url

		Local id:=StripDir( path )
		Local i:=id.Find( "#" )
		
		If i=-1
			Local i:=path.Find( "/" )
			If i<>-1 And path.Find( "/",i+1 )=-1
				AddToIndex path[..i],id,path
			Endif
		Else
			id=id[i+1..]
		Endif
		
		AddToIndex( "Index",id,path )
	End
	
	Method AddToIndex:Void( cat:String,ident:String,path:String )
	
		Local i:=ident.Find( "(" )
		If i<>-1 ident=ident[..i]
		
		Local index:=GetIndex( cat )
		
		Local uident:=ident,n:=1
		While index.Contains( uident )
			n+=1
			uident=ident+"("+n+")"
		Wend
		index.Set uident,path
	End
	
	Method AddGlobalDecl(name:String, decl:apidoccer.Decl)
		globalDecls.Set(name, decl)
	End Method
	
	Method SetPageContent:Void( page:String,html:String )
		content.Set page,html
	End
	
	Method MakeIndices:Void()
	
		Local maker:=New PageMaker( LoadString( styledir+"/index_template.html" ) )
		
		For Local it:=Eachin indexcats
		
			Local cat:=it.Key
			If pages.Contains( cat ) Continue
			
			Local index:=it.Value
			Local url:=cat+".html"
			
			maker.Clear
			maker.SetString "INDEX",cat
			maker.BeginList "ITEMS"
			
			For Local it:=Eachin index
				maker.AddItem
				maker.SetString "IDENT",it.Key
				maker.SetString "URL",pages.Get( it.Value )
			Next

			maker.EndList
			
			Local page:=maker.MakePage()
			
			pages.Set cat,url
			SetPageContent cat,page
		Next
		
	End
	
	Method MakeDocs:Void()
	
		For Local f:=Eachin LoadDir( styledir,True )
			If f.EndsWith( "_template.html" ) Continue
			
			Local dir:=ExtractDir( f )
			If dir CreateDir "docs/html/"+dir
			CopyFile styledir+"/"+f,"docs/html/"+f
		Next
		
		Local maker:=New PageMaker( LoadString( styledir+"/page_template.html" ) )
		
		For Local it:=Eachin pages
		
			Local path:=it.Key
			Local url:=it.Value
			
			Local page:=content.Get( path )
			If Not page Continue
			
			maker.Clear
			maker.SetString "CONTENT",page
		
			If path<>"Home" And path<>"Home2"
				maker.BeginList "NAVLINKS"
				Local tpath:=""
				For Local bit:=Eachin path.Split( "/" )
					maker.AddItem
					maker.SetString "IDENT",bit
					If tpath tpath+="/"
					tpath+=bit
					maker.SetString "URL",pages.Get( tpath )
				Next
				maker.EndList
			Endif
			
			page=maker.MakePage()
			
			SaveString page,"docs/html/"+url
			
		Next
		
		Local out:=New StringStack
		For Local it:=Eachin GetIndex( "Index" )
			Local url:=pages.Get( it.Value )
			If url out.Push it.Key+":"+url
		Next
		SaveString out.Join( "~n" ),"docs/html/index.txt"
		
		CopyDir styledir+"/data","docs/html/data"
		
	End
	
	Method MakeSearchIndex:Void(name:String, data:Stack<ScopeDecl>)
		Local index:JsonArray = New JsonArray(data.Length)
		Local markdown:Markdown = New Markdown(Self, Self)
		
		Local i:Int
		For Local s:ScopeDecl = EachIn data
			SetErrInfo s.path
			SetSearchIndexData(index, i, s.ident, markdown.ToHtml(s.docs.Get("summary")), GetPageUrl(s.PagePath()))
			i += 1
		Next

		WriteSearchIndex(index, name)
	End Method
	
	Method MakeSearchIndex:Void(name:String, data:Stack<apidoccer.Decl>)
		Local index:JsonArray = New JsonArray(data.Length)
		Local markdown:Markdown = New Markdown(Self, Self)
		
		Local i:Int
		For Local s:apidoccer.Decl = EachIn data
			SetErrInfo s.path			
			Local desc:String[] = s.docs.Get("description").Split("~n")
			Local summary:String = markdown.ToHtml(desc[0].Replace("@", ""))
			SetSearchIndexData(index, i, s.ident, summary, GetPageUrl(s.PagePath()))
			i += 1
		Next
		
		WriteSearchIndex(index, name)
	End Method
	
	Method SetSearchIndexData(database:JsonArray, index:Int, ident:String, summary:String, url:String)
		Local item:JsonObject = New JsonObject()
		
		item.SetString("ident", ident)
		item.SetString("summary", summary)
		item.SetString("url", url)
		
		database.Set(index, item)		
	End Method
	
	Method WriteSearchIndex(database:JsonArray, name:String)
		SaveString(database.ToJson(), "docs/html/search/" + name + ".json")
	End Method
	
	Method HtmlEsc:String( str:String )
		Return str.Replace("&", "&amp;").Replace("<", "&lt;").Replace(">", "&gt;")
	End
	
	Field inrem:=0
	
	Method BeginPrettyBlock:String()
		Return "<div class=pretty>" 
		inrem=0
	End
	
	Method EndPrettyBlock:String()
		Return "</div>"
	End
	
	Method PrettifyLine:String( text:String )
	
		If text="</pre >" text="</pre>"
		
		'VERY simple #Rem handling...
		If inrem
			If text.StartsWith( "#End" ) inrem-=1
			Return "<code class=r>"+HtmlEsc( text )+"</code><br>"
		Else If text.StartsWith( "#Rem" )
			inrem+=1
			Return "<code class=r>"+HtmlEsc( text )+"</code><br>"
		Endif

		ptoker.SetText text
		Local str:String,out:String,ccls:String
		Repeat
		
			If Not ptoker.Bump() Exit
			
			Local cls:="d",toke:=ptoker.Toke,esc:=toke
			
			Select ptoker.TokeType
			Case Toker.Eol
				If Not toke Exit
				cls="r"
				esc=HtmlEsc( esc )
			Case Toker.Whitespace
				toke=""
				For Local c:=Eachin esc
					If c=9
						toke+="    "[..4-(str+toke).Length Mod 4]
					Else
						toke+=" "
					Endif
				Next
				esc=toke.Replace( " ","&nbsp;" )
			Case Toker.Identifier
				cls="i"
				If MonkeyKeywords.Contains( ";"+toke.ToLower()+";" ) cls="k"
			Case Toker.IntLiteral,Toker.FloatLiteral,Toker.StringLiteral
				cls="l"
				esc=HtmlEsc( esc ).Replace( " ","&nbsp;" )
			Case Toker.Symbol
				esc=HtmlEsc( esc )
			End
			If cls<>ccls
				If out out+="</code>"
				If cls out+="<code class="+cls+">" Else out+="<code>"
				ccls=cls
			Endif
			str+=toke
			out+=esc
		Forever
		If out out+="</code>"
		Return out+"<br>"
	End
	
End

Function Main:Int()

	While FileType( "docs" )<>FILETYPE_DIR Or FileType( "modules" )<>FILETYPE_DIR
		ChangeDir ".."
	Wend
	
	Local search:Bool=False
	
	Local i:=1
	While i<AppArgs.Length
		Local arg:=AppArgs[i]
		i+=1
		Select arg
		Case "-ignore"
			If i<AppArgs.Length
				ignore_mods.Insert AppArgs[i]
				i+=1
			Endif
			
		Case "-language", "-lang"
			If i<AppArgs.Length
				additional_path = LANGUAGE_PREFIX + AppArgs[i]
				i+=1
			Endif
			
		Case "-search"
			search=True
		End
	Wend
	
	DeleteDir "docs/html",True
	CreateDir "docs/html"
	CreateDir "docs/html/data"
	CreateDir "docs/html/database/"
	CreateDir "docs/html/examples"
	CopyDir   "docs/htmldoc","docs/html",True
	
	Local style:=LoadString( "bin/docstyle.txt" ).Trim()
	If Not style Or FileType( "docs/templates/"+style )<>FILETYPE_DIR style="devolonter"
	
	Local george:=New George( "docs/templates/"+style )
	
	Local apidoccer:=New ApiDoccer( george )
	Local docsdoccer:=New DocsDoccer( george )
	
	Print "Parsing apis..."
	apidoccer.ParseDocs
	
	Print "Parsing docs..."
	docsdoccer.ParseDocs
	
	Print "Making indices..."
	george.MakeIndices
	
	Print "Making apis..."
	apidoccer.MakeDocs
	
	Print "Making docs..."
	docsdoccer.MakeDocs
		
	george.MakeDocs
	
	If search
		Print "Making search index..."
		Local modules:Stack<ScopeDecl> = New Stack<ScopeDecl>()
		Local classes:Stack<ScopeDecl> = New Stack<ScopeDecl>()
		Local interfaces:Stack<ScopeDecl> = New Stack<ScopeDecl>()
		Local functions:Stack<apidoccer.Decl > = New Stack<apidoccer.Decl > ()
		'note: TODO monkey keywords database
		
		For Local decl:ScopeDecl = EachIn apidoccer.scopes.Values()
			If (ModuleDecl(decl)) Then
				modules.Push(decl)
			ElseIf(ClassDecl(decl)) Then
				If (decl.kind = "class") Then
					classes.Push(decl)
				Else
					interfaces.Push(decl)
				End If
			End If
		Next
		
		For Local decl:apidoccer.Decl = EachIn george.globalDecls.Values()
			functions.Push(decl)
		Next
		
		george.MakeSearchIndex("modules", modules)
		george.MakeSearchIndex("classes", classes)
		george.MakeSearchIndex("interfaces", interfaces)
		george.MakeSearchIndex("functions", functions)
	End
	
	Print "Makedocs finished!"
	Return 0
End
