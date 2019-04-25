#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=AutoItv11.ico
#AutoIt3Wrapper_Res_Fileversion=1.0
#AutoIt3Wrapper_Res_ProductVersion=1.0
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****



While 1

   WinSetTrans ( "Preparing", "", 0 )
	WinSetTrans ( "Ninite", "", 0 )
   $text = WinGetText("Ninite", "")
   If StringInStr($text, "Finished.",1) Then
      WinSetTrans("Finished", "",1)
	   ExitLoop
   EndIf
   Sleep(200)
WEnd

Sleep(1000)
ControlClick("Ninite", "", "[ID:2]")

