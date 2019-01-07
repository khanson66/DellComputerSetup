
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_icon=AutoItv11.ico
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****source from http://cramaboule.com/index.php/silent-ninite








While 1

   $text = WinGetText("Ninite", "")
   If StringInStr($text, "Finished.",1) Then
	  ExitLoop
   EndIf
   Sleep(500)
WEnd

Sleep(1000)
ControlClick("Ninite", "", "[ID:2]")

