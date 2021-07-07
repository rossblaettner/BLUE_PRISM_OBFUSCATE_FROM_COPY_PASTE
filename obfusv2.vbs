' Comment: Randomize Placement (X, Y) of Stages
' Randomize 1
' rndMax = 120
' rndMin = -120
' rndHgt = 60
' rndWdt = 60

' Comment:  Make obfuscated names unique (with salt)
salt = "one"

If WScript.Arguments.Count <> 2 Then
Wscript.Echo( "USAGE: " & WScript.ScriptName & " " & _
Chr(34) & "SourceFile.EXT" & Chr(34) & " " & _
Chr(34) & "CreateFile.EXT" & Chr(34) )
WScript.Quit()
End If

' Comment: StrFileName (.XML path & file name) to obfuscate, result (XML), and types (Blue Prism stages)
StrFileName = WScript.Arguments(0)
result = ""
types = "|LoopStart|LoopEnd|WaitEnd|Read|Write|Navigate|Block|Data|Collection|Action|WaitStart|ChoiceStart|ChoiceEnd|Decision|Recover|Exception|Resume|Calculation|Anchor|SubSheet|Note|Read|Write|Navigate|"

Set ObjFso = CreateObject("Scripting.FileSystemObject")
Set ObjFile = ObjFso.OpenTextFile(StrFileName)
MyVar = ObjFile.ReadAll
ObjFile.Close

Set xmlDoc = CreateObject("Microsoft.XMLDOM")
xmlDoc.setProperty "SelectionLanguage", "XPath"
xmlDoc.async="false"
xmlDoc.load( StrFileName )

set xmlDoc2 = CreateObject("Microsoft.XMLDOM")

result = "<process " & xmlDoc.selectSingleNode("process/@*").xml & ">"
Set stages = xmlDoc.selectNodes("/process/stage")

For Each stage in stages

xmlDoc2.loadXML( stage.xml )

' Comment: Type of Blue Prism Stage
If InStr( types, ( "|" & stage.getAttribute("type") & "|" )) > 0 Then
  
' xmlDoc2.selectSingleNode("stage/displayx").Text = Int((rndMax-rndMin+1)*Rnd+rndMin)
' xmlDoc2.selectSingleNode("stage/displayy").Text = Int((rndMax-rndMin+1)*Rnd+rndMin)
' xmlDoc2.selectSingleNode("stage/displayheight").Text = rndHgt
' xmlDoc2.selectSingleNode("stage/displaywidth").Text = rndWdt
  
  nameAttribVal = stage.getAttribute("name")
  Set narrative = xmlDoc2.selectSingleNode("stage/narrative")
  Set exposure = xmlDoc2.selectSingleNode("stage/exposure")
  exposureValue = ""
  
  If Not narrative Is Nothing Then
   xmlDoc2.selectSingleNode("stage/narrative").Text = ""
  End If
  
  If Not exposure Is Nothing Then
   exposureValue = xmlDoc2.selectSingleNode("stage/exposure").Text
  End If
  
  If ( Not exposureValue = "Environment" ) Then
   xmlDoc2.selectSingleNode("stage").setAttribute  "name", toNameCharFormat(hashString(nameAttribVal))
  End If
  
' Comment: Type of Blue Prism Stage
ElseIf Not InStr( "|Start|End|", ( "|" & stage.getAttribute("type") & "|" )) > 0  Then
  
  result = result & stage.xml
  
End If

If stage.getAttribute("type") = "Collection" Then
  
  prepend = "*/"
  resultCount = 1
  source = xmlDoc2.xml
  target = xmlDoc2.xml
  
  While resultCount > 0
   Set fields = stage.selectNodes(prepend & "field[@name]")
   resultCount = fields.Length
  
   For Each field in fields
    temp = Replace( field.xml, Chr(34) & field.getAttribute("name") & Chr(34), Chr(34) & toNameCharFormat(hashString(field.getAttribute("name")))  & Chr(34))
    target = Replace( target, field.xml, temp)
   Next
   prepend = "*/" & prepend
  
  WEnd
  
  xmlDoc2.loadXML( target )
  
End If


' Comment: Type of Blue Prism Stage
If stage.getAttribute("type") = "Calculation" Then
  
  name = xmlDoc2.selectSingleNode("stage/calculation").getAttribute("stage")
  xmlDoc2.selectSingleNode("stage/calculation").setAttribute "stage", toNameCharFormat(hashString(name))
  expression = xmlDoc2.selectSingleNode("stage/calculation").getAttribute("expression")
  xmlDoc2.selectSingleNode("stage/calculation").setAttribute "expression", hashDataNames(expression)
  
End If

If stage.getAttribute("type") = "Decision" Then
  
  expression = xmlDoc2.selectSingleNode("stage/decision").getAttribute("expression")
  xmlDoc2.selectSingleNode("stage/decision").setAttribute "expression", hashDataNames(expression)
  
End If

If stage.getAttribute("type") = "LoopStart" Then
  
  loopData = xmlDoc2.selectSingleNode("stage/loopdata").Text
  xmlDoc2.selectSingleNode("stage/loopdata").Text = toNameCharFormat(hashString(loopData))
  
End If

If InStr( "|ChoiceStart|WaitStart|", ( "|" & stage.getAttribute("type") & "|" )) > 0  Then
  
  Set choices = xmlDoc2.selectNodes("stage/choices/choice")
  
  For Each choice in choices
  
   name = choice.selectSingleNode("name").Text
   choice.selectSingleNode("name").Text = toNameCharFormat(hashString(name))
  
   If stage.getAttribute("type") = "ChoiceStart" Then
    
    expr = choice.getAttribute("expression")
    choice.setAttribute "expression", hashDataNames(expr)
    
   ElseIf stage.getAttribute("type") = "WaitStart" Then
    
    Set params = choice.selectNodes("element/elementparameter")
    
    For Each param in params
    
     paramName = param.selectSingleNode("name").Text
     param.selectSingleNode("name").Text = toNameCharFormat(hashString(paramName))
    
     paramExpr = param.selectSingleNode("expression").Text
     param.selectSingleNode("expression").Text = hashDataNames(paramExpr)
    
    Next
    
   End If
  
  Next
  
End If

If InStr( "|Navigate|Read|Write|", ( "|" & stage.getAttribute("type") & "|" )) > 0  Then
  
  Set params = xmlDoc2.selectNodes("stage/step/element/elementparameter")
  
  For Each param in params
   expression = param.selectSingleNode("expression").Text
   param.selectSingleNode("expression").Text = hashDataNames(expression)
  Next
  
  Set args = xmlDoc2.selectNodes("stage/step/action/arguments/argument")
  
  For Each arg in args
   value = arg.selectSingleNode("value").Text
   arg.selectSingleNode("value").Text = hashDataNames(value)
  Next
  
End If

If InStr( "|Start|Action|", ( "|" & stage.getAttribute("type") & "|" )) > 0  Then
  
  Set inputs = xmlDoc2.selectNodes("stage/inputs/input")
  
  For Each input in inputs
  
   If stage.getAttribute("type") = "Start" Then
    
    stageName = input.getAttribute("stage")
    input.setAttribute "stage", toNameCharFormat( hashString( stageName ) )
    
   End If
  
   If stage.getAttribute("type") = "Action" Then
    
    expr = input.getAttribute("expr")
    input.setAttribute "expr", hashDataNames( expr )
    input.setAttribute "narrative", ""
    
   End If
  
  Next
  
End If

If InStr( "|End|Action|", ( "|" & stage.getAttribute("type") & "|" )) > 0  Then
  
  Set outputs = xmlDoc2.selectNodes("stage/outputs/output")
  
  For Each output in outputs
  
  
   stageName = output.getAttribute("stage")
   output.setAttribute "stage", toNameCharFormat( hashString( stageName ) )
  
' If stage.getAttribute("type") = "Action" Then
  
' expr = output.getAttribute("expr")
' output.setAttribute "expr", hashDataNames( expr )
' output.setAttribute "narrative", ""
' End If
  
  Next
  
End If

If stage.getAttribute("type") = "Exception" Then
  
  Set exception = xmlDoc2.selectSingleNode("stage/exception")
  detail = exception.getAttribute("detail")
  exception.setAttribute "detail", hashDataNames( detail )
  
End If

result = result & xmlDoc2.xml

Next

result = result & "</process>"
Const ForReading = 1
Const ForWriting = 2
Const ForAppending = 8

Set objTextFile = objFSO.OpenTextFile(WScript.Arguments(1), ForWriting, True)

' Writes strText every time you run this VBScript
objTextFile.Write(result)
objTextFile.Close
Set ObjFso = Nothing

function toAlphaOnly( string )

alphaChars = ""

Set re = New RegExp
With re
  .Pattern    = "[A-z]"
  .IgnoreCase = False
  .Global     = True
End With

Set chars = re.Execute( string )

For Each char in chars
  alphaChars = alphaChars & char.Value
Next

toAlphaOnly = alphaChars
end function

function toNameCharFormat( string )

format = ""
Set re = New RegExp
With re
  .Pattern    = "[A-z][A-z0-9]*"
  .IgnoreCase = False
  .Global     = True
End With

Set matches = re.Execute( string )

For Each match in matches
  format = format & match.Value
Next

toNameCharFormat = format

end function

function hashDataNames( string )

Set re = New RegExp
With re
  .Pattern    = "[\.\[]?([A-z][A-z0-9\s\-]*[A-z0-9])[\.\]]"
  .IgnoreCase = False
  .Global     = True
End With
Set matches = re.Execute( string )

For Each match in matches
  
  matchText = match.value
  
  For Each subMatch in match.Submatches
  
   matchText = Replace( matchText, subMatch, toNameCharFormat( hashString( subMatch ) ) )
  
  Next    
  string = Replace( string, match.value, matchText)
  
Next

hashDataNames = string


end function

function hashString( string )

hashString = BytesToBase64(md5hashBytes(stringToUTFBytes(salt & string)))

end function

function md5hashBytes(aBytes)

Dim MD5
set MD5 = CreateObject("System.Security.Cryptography.MD5CryptoServiceProvider")

MD5.Initialize()
'Note you MUST use computehash_2 to get the correct version of this method, and the bytes MUST be double wrapped in brackets to ensure they get passed in correctly.
md5hashBytes = MD5.ComputeHash_2( (aBytes) )

end function

function sha1hashBytes(aBytes)

Dim sha1
set sha1 = CreateObject("System.Security.Cryptography.SHA1Managed")

sha1.Initialize()
'Note you MUST use computehash_2 to get the correct version of this method, and the bytes MUST be double wrapped in brackets to ensure they get passed in correctly.
sha1hashBytes = sha1.ComputeHash_2( (aBytes) )

end function

function sha256hashBytes(aBytes)

Dim sha256
set sha256 = CreateObject("System.Security.Cryptography.SHA256Managed")

sha256.Initialize()
'Note you MUST use computehash_2 to get the correct version of this method, and the bytes MUST be double wrapped in brackets to ensure they get passed in correctly.
sha256hashBytes = sha256.ComputeHash_2( (aBytes) )

end function

function stringToUTFBytes(aString)

Dim UTF8
Set UTF8 = CreateObject("System.Text.UTF8Encoding")
stringToUTFBytes = UTF8.GetBytes_4(aString)

end function

function bytesToHex(aBytes)

dim hexStr, x
for x=1 to lenb(aBytes)
  hexStr= hex(ascb(midb( (aBytes),x,1)))
  if len(hexStr)=1 then hexStr="0" & hexStr
  bytesToHex=bytesToHex & hexStr
next

end function

Function BytesToBase64(varBytes)

With CreateObject("MSXML2.DomDocument").CreateElement("b64")
  .dataType = "bin.base64"
  .nodeTypedValue = varBytes
  BytesToBase64 = .Text
End With

End Function

Function GetBytes(sPath)

With CreateObject("Adodb.Stream")
  .Type = 1 ' adTypeBinary
  .Open
  .LoadFromFile sPath
  .Position = 0
  GetBytes = .Read
  .Close
End With

End Function
'' SIG '' Begin signature block
'' SIG '' MIIP6QYJKoZIhvcNAQcCoIIP2jCCD9YCAQExCzAJBgUr
'' SIG '' DgMCGgUAMGcGCisGAQQBgjcCAQSgWTBXMDIGCisGAQQB
'' SIG '' gjcCAR4wJAIBAQQQTvApFpkntU2P5azhDxfrqwIBAAIB
'' SIG '' AAIBAAIBAAIBADAhMAkGBSsOAwIaBQAEFCFJFY0jKiGl
'' SIG '' OMQe+At8wI2HPDSzoIINRDCCBh8wggUHoAMCAQICCmqx
'' SIG '' yMsAAAAAAAgwDQYJKoZIhvcNAQELBQAwIjEgMB4GA1UE
'' SIG '' AxMXQUhOQVQtQUhXQ0VSQUhOQVQwMDEtQ0EwHhcNMTkw
'' SIG '' NDAzMDAwODIyWhcNMjkwNDAzMDAxODIyWjBhMRMwEQYK
'' SIG '' CZImiZPyLGQBGRYDY29tMRQwEgYKCZImiZPyLGQBGRYE
'' SIG '' U0pIUzESMBAGCgmSJomT8ixkARkWAkRTMSAwHgYDVQQD
'' SIG '' ExdBSE5BVC1BSFdDRVJBSE5BVDAwMy1DQTCCASIwDQYJ
'' SIG '' KoZIhvcNAQEBBQADggEPADCCAQoCggEBAMJvhpolpqbP
'' SIG '' 9Z7v91e6PoO6nDf33BTJ7PSvyIe2egfezjhIUxWcsi9Y
'' SIG '' fzURXR6CCL+fq2UnnqHdEhy/BdlgfFE/1SAUQaz3erUm
'' SIG '' Cg1c9Mwy8qS1zPvQthPSfRWQBTOgKnAv472klmkHD7zD
'' SIG '' 7q3XQJuqR0KzntswFiA8MqV2eccOeUiweuHJEQFpIcE7
'' SIG '' pcrZFFAKe/jCArE85IsTxOjx9JYEFQj8JSQXX7nBV9uK
'' SIG '' YijZjwJINkItr8L2tIJ3r4G6c8ignVbRuhV1FtPeoUFi
'' SIG '' 9Ki8f0mhDAiDZnrrAN0a778uIwRrzSRtf31Fbh/gveex
'' SIG '' kFLc6082CSrZvoKXmpAMhjECAwEAAaOCAxYwggMSMBAG
'' SIG '' CSsGAQQBgjcVAQQDAgEBMCMGCSsGAQQBgjcVAgQWBBSK
'' SIG '' pRpcPBkhGKnN8sV1zQ4xIRONYjAdBgNVHQ4EFgQUBSN/
'' SIG '' dFFoLhGzPoNOw4eSW4kG3iMwGQYJKwYBBAGCNxQCBAwe
'' SIG '' CgBTAHUAYgBDAEEwCwYDVR0PBAQDAgGGMBIGA1UdEwEB
'' SIG '' /wQIMAYBAf8CAQEwHwYDVR0jBBgwFoAUt+eC4m7F98iQ
'' SIG '' xR3LYf/TGttV00cwggEpBgNVHR8EggEgMIIBHDCCARig
'' SIG '' ggEUoIIBEIaByGxkYXA6Ly8vQ049QUhOQVQtQUhXQ0VS
'' SIG '' QUhOQVQwMDEtQ0EsQ049QUhXQ0VSQUhOQVQwMDEsQ049
'' SIG '' Q0RQLENOPVB1YmxpYyUyMEtleSUyMFNlcnZpY2VzLENO
'' SIG '' PVNlcnZpY2VzLENOPUNvbmZpZ3VyYXRpb24sREM9ZHMs
'' SIG '' REM9c2pocyxkYz1jb20/Y2VydGlmaWNhdGVSZXZvY2F0
'' SIG '' aW9uTGlzdD9iYXNlP29iamVjdENsYXNzPWNSTERpc3Ry
'' SIG '' aWJ1dGlvblBvaW50hkNodHRwOi8vcGtpLmFzY2Vuc2lv
'' SIG '' bmhlYWx0aC5vcmcvQ2VydERhdGEvQUhOQVQtQUhXQ0VS
'' SIG '' QUhOQVQwMDEtQ0EuY3JsMIIBLgYIKwYBBQUHAQEEggEg
'' SIG '' MIIBHDCBuQYIKwYBBQUHMAKGgaxsZGFwOi8vL0NOPUFI
'' SIG '' TkFULUFIV0NFUkFITkFUMDAxLUNBLENOPUFJQSxDTj1Q
'' SIG '' dWJsaWMlMjBLZXklMjBTZXJ2aWNlcyxDTj1TZXJ2aWNl
'' SIG '' cyxDTj1Db25maWd1cmF0aW9uLERDPWRzLERDPXNqaHMs
'' SIG '' ZGM9Y29tP2NBQ2VydGlmaWNhdGU/YmFzZT9vYmplY3RD
'' SIG '' bGFzcz1jZXJ0aWZpY2F0aW9uQXV0aG9yaXR5MF4GCCsG
'' SIG '' AQUFBzAChlJodHRwOi8vcGtpLmFzY2Vuc2lvbmhlYWx0
'' SIG '' aC5vcmcvQ2VydERhdGEvQUhXQ0VSQUhOQVQwMDFfQUhO
'' SIG '' QVQtQUhXQ0VSQUhOQVQwMDEtQ0EuY3J0MA0GCSqGSIb3
'' SIG '' DQEBCwUAA4IBAQAKhVbb9YcUeioLvZQkMySHPAtBm8XN
'' SIG '' rgHDEKGPavQSspf4iAdAhdLxJISsuKqIuOFooiCRJ7i9
'' SIG '' zeE4HUAjMPvXMtfxlMLMmpPB+e7fVoU9bGHL6BgKcw0/
'' SIG '' 2OGztwi0L/mVyb5gOZUaN0EfpNpUrAx24nLcaDhEaOVj
'' SIG '' KhoBoi20hHnc09o9Jl50vuYbPxIVkmX/1mNj5NDyf++D
'' SIG '' Md6rUomxOnxbncqrckucZ2H1UsNXKMGFz80cAL8WHRAR
'' SIG '' QlaugTpokFqhKtkJf1i/OiHnyYMwv41/YGngbat5oNi4
'' SIG '' wZzU7dvnEFPK6nDZ3lx9lEEMV7A4DGfA1wU0T+7OXmFc
'' SIG '' ZWKrMIIHHTCCBgWgAwIBAgITFgABKRtKvyttLIoWXAAB
'' SIG '' AAEpGzANBgkqhkiG9w0BAQsFADBhMRMwEQYKCZImiZPy
'' SIG '' LGQBGRYDY29tMRQwEgYKCZImiZPyLGQBGRYEU0pIUzES
'' SIG '' MBAGCgmSJomT8ixkARkWAkRTMSAwHgYDVQQDExdBSE5B
'' SIG '' VC1BSFdDRVJBSE5BVDAwMy1DQTAeFw0xOTA4MjAxNzMz
'' SIG '' NDBaFw0yMjA4MTkxNzMzNDBaMIGLMRMwEQYKCZImiZPy
'' SIG '' LGQBGRYDY29tMRQwEgYKCZImiZPyLGQBGRYEU0pIUzES
'' SIG '' MBAGCgmSJomT8ixkARkWAkRTMRUwEwYKCZImiZPyLGQB
'' SIG '' GRYFaW5tc2MxEDAOBgNVBAsTB01hbmFnZWQxDjAMBgNV
'' SIG '' BAsTBVVzZXJzMREwDwYDVQQDEwhtYWxib3VnaDCCASIw
'' SIG '' DQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBALSsf4rH
'' SIG '' eOXwTCbQTfRz2cZDreDklXn5mLq1nUFUGUlk/QlEQS5I
'' SIG '' LXsG8JdiLhX3yApocXb7jT8d+Oa9BczYOfBA1H+hZWBk
'' SIG '' VhRejjTX9w2/cn7f2HSNeHb4KV6ctP2gVnAQ7wxwL77T
'' SIG '' grGqCswfPP8SRHsJdcYk3hmgzOCjcz+u68AkxhAj8iOg
'' SIG '' 1X5CWc3z2q+59syfiVVxYohjhgBureiLyOz6vh9HwCdC
'' SIG '' +sSfbNhLDT/hzOpKwXJQWolgOFSEa2Je1nGP/R7hcoA/
'' SIG '' FbTV/wQZY+DXBbgIKI7ASO560aZAv5feX8+RsIXBoFbF
'' SIG '' 24YCACi2rlC9GDT2KEA7Iv/4dAECAwEAAaOCA6EwggOd
'' SIG '' MDsGCSsGAQQBgjcVBwQuMCwGJCsGAQQBgjcVCIvKF8zw
'' SIG '' DofthTGC88ZTgbDbZYE1gcHmTPucHAIBZAIBAjATBgNV
'' SIG '' HSUEDDAKBggrBgEFBQcDAzALBgNVHQ8EBAMCB4AwGwYJ
'' SIG '' KwYBBAGCNxUKBA4wDDAKBggrBgEFBQcDAzAdBgNVHQ4E
'' SIG '' FgQUmuqSBEh1i/LunCp8CrR5oAgJPFcwHwYDVR0jBBgw
'' SIG '' FoAUBSN/dFFoLhGzPoNOw4eSW4kG3iMwggEpBgNVHR8E
'' SIG '' ggEgMIIBHDCCARigggEUoIIBEIaByGxkYXA6Ly8vQ049
'' SIG '' QUhOQVQtQUhXQ0VSQUhOQVQwMDMtQ0EsQ049QUhXQ0VS
'' SIG '' QUhOQVQwMDMsQ049Q0RQLENOPVB1YmxpYyUyMEtleSUy
'' SIG '' MFNlcnZpY2VzLENOPVNlcnZpY2VzLENOPUNvbmZpZ3Vy
'' SIG '' YXRpb24sREM9RFMsREM9U0pIUyxEQz1jb20/Y2VydGlm
'' SIG '' aWNhdGVSZXZvY2F0aW9uTGlzdD9iYXNlP29iamVjdENs
'' SIG '' YXNzPWNSTERpc3RyaWJ1dGlvblBvaW50hkNodHRwOi8v
'' SIG '' cGtpLmFzY2Vuc2lvbmhlYWx0aC5vcmcvQ2VydERhdGEv
'' SIG '' QUhOQVQtQUhXQ0VSQUhOQVQwMDMtQ0EuY3JsMIIBbgYI
'' SIG '' KwYBBQUHAQEEggFgMIIBXDCBuQYIKwYBBQUHMAKGgaxs
'' SIG '' ZGFwOi8vL0NOPUFITkFULUFIV0NFUkFITkFUMDAzLUNB
'' SIG '' LENOPUFJQSxDTj1QdWJsaWMlMjBLZXklMjBTZXJ2aWNl
'' SIG '' cyxDTj1TZXJ2aWNlcyxDTj1Db25maWd1cmF0aW9uLERD
'' SIG '' PURTLERDPVNKSFMsREM9Y29tP2NBQ2VydGlmaWNhdGU/
'' SIG '' YmFzZT9vYmplY3RDbGFzcz1jZXJ0aWZpY2F0aW9uQXV0
'' SIG '' aG9yaXR5MG0GCCsGAQUFBzAChmFodHRwOi8vcGtpLmFz
'' SIG '' Y2Vuc2lvbmhlYWx0aC5vcmcvQ2VydERhdGEvQUhXQ0VS
'' SIG '' QUhOQVQwMDMuRFMuU0pIUy5jb21fQUhOQVQtQUhXQ0VS
'' SIG '' QUhOQVQwMDMtQ0EoMSkuY3J0MC8GCCsGAQUFBzABhiNo
'' SIG '' dHRwOi8vcGtpLmFzY2Vuc2lvbmhlYWx0aC5vcmcvb2Nz
'' SIG '' cDBABgNVHREEOTA3oDUGCisGAQQBgjcUAgOgJwwlUmVk
'' SIG '' d2FuLkFsYm91Z2hhQGFnaWxpZnlhdXRvbWF0aW9uLmNv
'' SIG '' bTANBgkqhkiG9w0BAQsFAAOCAQEAob61nYQMxjknhVAw
'' SIG '' fHMVDChnWEdhXny2ovpdf1+7ciVuaGqX5cpeP2qvESK5
'' SIG '' RlA7a48aLX22t3b6udAhoRoXYtv5LR6q/QSd6klpEQQr
'' SIG '' hwIaw9evpPMDfVwJlQXOSX8b3qM8KTmp3fH3JwM/+A1o
'' SIG '' Hc5TOaHsdiE/oyBuM955eKYPE6pX28c+tqWpReAwcIrZ
'' SIG '' x4Ph0wuyITzSkmaqUNQ1NUhba39lQ5At3nQI1nEBEEY6
'' SIG '' Vy+QI1e7wis7zvCu0gr9zvR5uJbeUifePFWWgtF5/JJS
'' SIG '' dSLDz6x5qIuDyeVPHYHn8Oyj1Um7PMeSjpclRzlk2p5P
'' SIG '' fYPwT4gBUkFbJFIOmzGCAhEwggINAgEBMHgwYTETMBEG
'' SIG '' CgmSJomT8ixkARkWA2NvbTEUMBIGCgmSJomT8ixkARkW
'' SIG '' BFNKSFMxEjAQBgoJkiaJk/IsZAEZFgJEUzEgMB4GA1UE
'' SIG '' AxMXQUhOQVQtQUhXQ0VSQUhOQVQwMDMtQ0ECExYAASkb
'' SIG '' Sr8rbSyKFlwAAQABKRswCQYFKw4DAhoFAKBwMBAGCisG
'' SIG '' AQQBgjcCAQwxAjAAMBkGCSqGSIb3DQEJAzEMBgorBgEE
'' SIG '' AYI3AgEEMBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3
'' SIG '' AgEVMCMGCSqGSIb3DQEJBDEWBBRudzxv9lcvTjrF0qpY
'' SIG '' uPKNhHB1+jANBgkqhkiG9w0BAQEFAASCAQAZLYaVQ0MJ
'' SIG '' UQVZck9Hw4ZzYsSHu5rCbNeEfAolpO9wjMYgSXZ8yTZN
'' SIG '' cHqIlCI6l1bYq3lV+EyE7KVF9vGi+DUfNb8O1LTW+HYv
'' SIG '' ATsxixK3SmfKqL45H4qCCjUBME4P+xU0sJzogqRjUoDE
'' SIG '' 4qSk489Qjgr8MoD1BVyC5VcwAF/5ojTU2GAFCUcLgWQB
'' SIG '' pwSVqt6hFXNTuVdP2Cp9WwgapBFGuTKnqgRWEk0X5pY2
'' SIG '' 3cr4+Lw5V3iiBw0JWAZ/3KBbHJmxIkAKubETwhgYCJx8
'' SIG '' Vhh04RDJL17hj5pRA3px6xceFfj8F+RW8D/gX4AG11sf
'' SIG '' NjEfXhDlxUpv6YZ2UfI4fDQF
'' SIG '' End signature block
