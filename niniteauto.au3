#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=AutoItv11.ico
#AutoIt3Wrapper_Res_Fileversion=1.0
#AutoIt3Wrapper_Res_Fileversion_AutoIncrement=p
#AutoIt3Wrapper_Res_ProductName=Quite Ninite
#AutoIt3Wrapper_Res_ProductVersion=1.0
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****


While 1

   $text = WinGetText("Ninite", "")
   WinSetTrans($text,"",0);
   If StringInStr($text, "Finished.",1) Then
      WinSetTrans($text,"",0)
	   ExitLoop
   EndIf
   Sleep(1000)
WEnd
Sleep(1000)
ControlClick("Ninite", "", "[ID:2]")

