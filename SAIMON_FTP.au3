#pragma compile(OriginalFilename, SAIMON_FTP.exe)
#pragma compile(LegalCopyright, 100% free software)
#pragma compile(FileVersion, 1.36)
#pragma compile(ProductVersion, 1.36)
#pragma compile(ProductName, SAIMON_FTP)
#NoTrayIcon
#include <FTPEx.au3>
#include <GuiListBox.au3>
#include <Debug.au3>
#include <SQLite.au3>
#include <GUIConstantsEx.au3>
#Include <GuiListView.au3>
#include <WindowsConstants.au3>
#include <editconstants.au3>
#OnAutoItStartRegister 'singleton'
#OnAutoItStartRegister 'globalVar'
#OnAutoItStartRegister 'versionCheck'
main()
;TODO: check se caricato bene
Func globalVar()
	Global Const $sVersion		= '1.37 alpha'
	Global Const $sTitle			= 'SAIMON FTP V' & $sVersion
	Global Const $sTitleAdv		= 'Advanced View'
	Global Const $sDirIni		= @AppDataCommonDir & '\SaimonFtp'
	Global Const $sFileIni		= $sDirIni & '\config.ini'
	Global Const $sCheckpath   = iniReadW('checkPath', 'W:\CELIA\')
	Global Const $sFullININame	= iniReadW('updatePath', $sCheckpath & '\check.txt')
	Global Const $sdFTPaddress	= '10.210.32.202'
	Global Const $aString		= ["~ Preview module activated, 8.5, 0, 0, 'Courier New'", "~ Preview module deactivated"]
	Global Const $cGiallino    = 0xFFFED8
	Global Const $COLOR_RED    = 0xFF0000
	Global Const $CLR_DEFAULT  = 0xFF000000
	Global $hQuery, $aRow, $hDB, $iCounter = 0, $MAV, $CMAV
	Global $lastClick = -1
EndFunc

Func singleton()
	DllCall('kernel32.dll', 'handle', 'CreateMutexW', 'struct*', 0, 'bool', 1, 'wstr', @ScriptName);Local $aHandle =
	If @error Then Return SetError(@error, @extended, 0);)$sOccurenceName);Local $tSecurityAttributes = 0
	Local $aLastError = DllCall('kernel32.dll', 'dword', 'GetLastError')
	If @error Then Return SetError(@error, @extended, 0)
	If $aLastError[0] = 183 Then Exit -1;Local Const $ERROR_ALREADY_EXISTS = 183;Return $aHandle[0]
EndFunc

Func main()
	Opt('GUIOnEventMode', 1)
	Opt('MustDeclareVars', 1)
	Opt('GUIResizeMode', 802)
	Opt('TrayIconDebug', 1)
	initDB()
	Local $xLoc = iniReadW('xLoc', -1), $yLoc = iniReadW('yLoc', -1)
	If $xLoc < -1 Or $xLoc > @DesktopWidth - 100 Then $xLoc = -1
	If $yLoc < -1 Or $yLoc > @DesktopHeight - 100 Then $yLoc = -1
	Local $x = 727, $y = 749
	If iniReadW('advV', '1') = 0 Then
		$x = 347
		$y = 191
	EndIf
	Global Const $form_main = GUICreate($sTitle, $x, $y, $xLoc, $yLoc);+220;+535;-------341;191
	GUICtrlSetOnEvent(GUICtrlCreateButton('Download', 14, 7, 95, 25), 'btnDownloadClicked')
		GUICtrlSetTip(-1, "Scarica un membro dall'HOST", 'Info', 1, 1)
	Global Const $btnExtensionDwn = GUICtrlCreateButton('', 111, 7, 34, 25)
		GUICtrlSetOnEvent(-1, 'btnExtensionDwnClicked')
		GUICtrlSetTip(-1, "Cambia estensione file", 'Info', 1, 1)
	GUICtrlSetOnEvent(GUICtrlCreateButton('Upload da file', 190, 7, 131, 25), 'btnUpFileClicked')
		GUICtrlSetTip(-1, 'Carica un file su HOST', 'Info', 1, 1)
	GUICtrlSetOnEvent(GUICtrlCreateButton('Apri con Notepad++', 14, 44, 131, 25), 'btnNotepadClicked')
		GUICtrlSetTip(-1, 'Apre un file HOST con Notepad++', 'Info', 1, 1)
	GUICtrlSetOnEvent(GUICtrlCreateButton('Upload da CTRL+C', 190, 44, 131, 25), 'btnUpClipClicked')
		GUICtrlSetTip(-1, 'Carica gli appunti su HOST', 'Info', 1, 1)
	GUICtrlSetOnEvent(GUICtrlCreateButton('Apri con Excel', 14,  81, 131, 25), 'btnExcelClicked')
		GUICtrlSetTip(-1, 'Apre un file HOST con Excel', 'Info', 1, 1)
	Global Const $btn_adv = GUICtrlCreateButton('Advanced', 190, 81, 131, 25)
		GUICtrlSetOnEvent(-1, 'btnAdvClicked')
		GUICtrlSetTip(-1, 'Vista avanzata', 'Info', 1, 1)
	Global Const $sGroup = GUICtrlCreateGroup('', 6, 115, 322, 47, 0x0300)
	Global Const $input_user = GUICtrlCreateInput(iniReadW('FTPuser', 'user'), 17, 134, 126, 21, 137);BitOR($GUI_SS_DEFAULT_INPUT,$ES_CENTER,$ES_UPPERCASE))
		GUICtrlSetTip(-1, 'Nome utente FTP', 'Info', 1, 1)
	Global Const $input_pass = GUICtrlCreateInput(iniReadW('FTPpass', 'password'), 192, 134, 126, 21, 169);BitOR($GUI_SS_DEFAULT_INPUT,$ES_CENTER,$ES_UPPERCASE,$ES_PASSWORD))
		GUICtrlSetTip(-1, 'Password FTP', 'Info', 1, 1)
	GUIRegisterMsg($WM_COMMAND, "ONLOSTFOCUS")
	createMenu()
	createContextMenu()
	If iniReadW('uploadMode', 1) = 1 Then iniWriteW('lRECL', 'auto')
	refreshLabelGroup()
	GUICtrlCreateGroup('Locale - ' & @ComputerName, 6, 173, 265, 545)
	Global $adv_in_path_local = GUICtrlCreateCombo("", 16, 189, 193, 25, BitOR(74, 0x0008))
		GUICtrlSetOnEvent(-1, 'refreshListBoxLocal')
		GUICtrlSetTip(-1, 'Path locale', 'Info', 1, 1)
		refreshCombo("LASTLOCAL", $adv_in_path_local)
		GUICtrlSetState(-1, 128)
	GUICtrlSetOnEvent(GUICtrlCreateButton('...', 216, 189, 43, 25), 'advBtnLocalClicked')
		GUICtrlSetTip(-1, 'Seleziona cartella locale', 'Info', 1, 1)
	Global $adv_listBox_local = GUICtrlCreateListView('', 16, 221, 241, 305, 0);10487819);GUICtrlCreateList
		_GUICtrlListView_AddColumn($adv_listBox_local, "Nome", 135)
		_GUICtrlListView_AddColumn($adv_listBox_local, "Full Path", 200)
		Global $h_listBox_local = GUICtrlGetHandle(-1)
		GUICtrlSetTip(-1, 'Lista file locali', 'Info', 1, 1)
		refreshListBoxLocal()
	Global $btnAddToFav = GUICtrlCreateButton("Aggiungi cartella ai preferiti", 16, 530, 213, 25)
		GUICtrlSetState(-1, 128)
		GUICtrlSetOnEvent(-1, "btnAddToFavClicked")
	Global $btnRmvFrFav = GUICtrlCreateButton("X", 233, 530, 25, 25)
		GUICtrlSetState(-1, 128)
		GUICtrlSetOnEvent(-1, "btnRmvFrFavClicked")
	Global $listFav = GUICtrlCreateListView("", 16, 560, 241, 149, 0)
		Global $h_listBox_listFav = GUICtrlGetHandle(-1)
		_GUICtrlListView_AddColumn($listFav, "Nome", 135)
		_GUICtrlListView_AddColumn($listFav, "Full Path", 200)
		refreshListFav()
	Global $adv_btn_up = GUICtrlCreateButton    (">", 280, 222, 163, 25)
		GUICtrlSetState(-1, 128)
		GUICtrlSetTip(-1, 'Carica file selezionato', 'Info', 1, 1)
		GUICtrlSetOnEvent(-1, 'advBtnUpClicked')
	Global $adv_btn_up_all = GUICtrlCreateButton(">>", 280, 273, 163, 25)
		GUICtrlSetState(-1, 128)
		GUICtrlSetOnEvent(-1, 'advBtnUpAllClicked')
	Global $adv_btn_dw = GUICtrlCreateButton    ('<', 280, 325, 163, 25)
		GUICtrlSetState(-1, 128)
		GUICtrlSetTip(-1, 'Scarica file selezionato', 'Info', 1, 1)
		GUICtrlSetOnEvent(-1, 'advBtnDwClicked')
	Global $adv_btn_dw_all = GUICtrlCreateButton('<<', 280, 376, 163, 25)
		GUICtrlSetState(-1, 128)
		GUICtrlSetOnEvent(-1, 'advBtnDwAllClicked')
	GUICtrlCreateGroup("HOST", 448, 173, 265, 545)
	Global $adv_in_path_host = GUICtrlCreateCombo('', 456, 189, 193, 25, BitOR(74, 0x0008))
		GUICtrlSetOnEvent(-1, 'refreshListBoxHOST')
		GUICtrlSetTip(-1, 'Data set HOST', 'Info', 1, 1)
	GUICtrlSetOnEvent(GUICtrlCreateButton('refresh', 656, 189, 43, 25), 'advBtnRefClicked')
		GUICtrlSetTip(-1, 'Ricarica data set HOST', 'Info', 1, 1)
	Global $adv_listBox_host = GUICtrlCreateListView('', 456, 221, 241, 487, 0);10485771;10488331
		GUICtrlSetTip(-1, 'Lista file HOST', 'Info', 1, 1)
		Global $h_listBox_host = GUICtrlGetHandle(-1)
		_GUICtrlListView_AddColumn($adv_listBox_host, "Nome", 80)
		_GUICtrlListView_AddColumn($adv_listBox_host, "Full Path", 200)
		_GUICtrlListView_AddColumn($adv_listBox_host, "Data Set", 75)
	Global $adv_btn_np = GUICtrlCreateButton    ('N++', 280, 479, 163, 25)
		GUICtrlSetTip(-1, 'Apri file HOST con Notepad++', 'Info', 1, 1)
		GUICtrlSetOnEvent(-1, 'advBtnNpClicked')
		GUICtrlSetState(-1, 128)
	Global $adv_btn_ex = GUICtrlCreateButton    ('CSV', 280, 427, 163, 25)
		GUICtrlSetOnEvent(-1, 'advBtnExClicked')
		GUICtrlSetTip(-1, 'Apri file HOST con Excel', 'Info', 1, 1)
		GUICtrlSetState(-1, 128)
	Global $adv_chk_prev = GUICtrlCreateCheckbox('', 282, 191, 152, 25)
		GUICtrlSetTip(-1, "Attiva/disattiva l'anteprima host", 'Info', 1, 1)
		GUICtrlSetOnEvent(-1, 'advChkPrevClicked')
	Global $adv_edit_preview = GUICtrlCreateEdit('', 346, 8, 367, 163)
		GUICtrlSetFont(-1, 8.5, 0, 0, 'Courier New')
		GUICtrlSetTip(-1, 'Anteprima contenuto file Host', 'Info', 1, 1)
	Global $btnAddMember = GUICtrlCreateButton ("Agg. membro ai favoriti", 280, 530, 133, 25)
		GUICtrlSetOnEvent(-1, "btnAddMemberClicked")
		GUICtrlSetState(-1, 128)
	Global $btnRmvMember = GUICtrlCreateButton ('X', 417, 530, 25, 25)
		GUICtrlSetState(-1, 128)
		GUICtrlSetOnEvent(-1, "btnRmvMemberClicked")
	Global $listFavMembers = GUICtrlCreateListView("", 280, 560, 161, 149, 0)
		_GUICtrlListView_AddColumn($listFavMembers, "Nome", 80)
		_GUICtrlListView_AddColumn($listFavMembers, "Member", 200)
		_GUICtrlListView_AddColumn($listFavMembers, "Path", 200)
		Global $h_listBox_listFavM = GUICtrlGetHandle(-1)
	If iniReadW('preview', 'off') = 'on' Then
		GUICtrlSetState($adv_chk_prev, 1)
		GUICtrlSetData($adv_edit_preview, $aString[0])
		GUICtrlSetData($adv_chk_prev, 'Anteprima abilitato')
	Else
		GUICtrlSetState($adv_chk_prev, 4)
		GUICtrlSetData($adv_edit_preview, $aString[1])
		GUICtrlSetData($adv_chk_prev, 'Anteprima disabilitato')
	EndIf
	If iniReadW('advV', '1') = 0 Then
		GUICtrlSetData($btn_adv, 'Advanced')
		GUICtrlSetTip($btn_adv, 'Vista avanzata', 'Info', 1, 1)
		GUICtrlSetData($CMAV, '&Advanced View')
		GUICtrlSetData($MAV, '&Advanced View')
	Else
		GUICtrlSetData($btn_adv, 'Basic')
		GUICtrlSetTip($btn_adv, 'Vista Basic', 'Info', 1, 1)
		GUICtrlSetData($CMAV, '&Basic View')
		GUICtrlSetData($MAV, '&Basic View')
	EndIf
	GUISetState(@SW_SHOW, $form_main)
	If iniReadW('advV', '1') = 1 Then
		refreshCombo("LASTCATALOG", $adv_in_path_host)
		refreshListBoxHOST()
	EndIf
	refreshListFavMember()
	HotKeySet('^{L}', 'debugSTART')
	GUISetOnEvent(-3, 'closeClicked', $form_main)
	GUIRegisterMsg($WM_NOTIFY, "WM_ListView_DoubleClick")
;~ 	checkUP() fa perdere tempo all'inizio e potrebbe bloccare troppo l'applicazione in caso di mancanza di rete
	While True
		Sleep(9990)
	WEnd
EndFunc

Func btnRmvMemberClicked()
	_DebugOut("btnRmvMemberClicked")
	If _GUICtrlListView_GetSelectedCount($listFavMembers) = 1 Then
		_SQLite_Exec($hDB, "DELETE FROM FAVMEMBER WHERE path='" & readList(2, $listFavMembers) & "';")
		refreshListFavMember()
	EndIf
EndFunc

Func btnAddMemberClicked()
	_DebugOut('btnAddMemberClicked')
	MsgBox(48, 'Alert #btnAddMemberClicked', 'No grant for this operation', 0, $form_main)
	Return

	Local $array = readList(0, $adv_listBox_host)
	;se esiste già non fare inserire
	_SQLite_Query($hDB, 'SELECT * FROM FAVMEMBER WHERE path="' & $array[1] & '"', $hQuery)
	If _SQLite_FetchData($hQuery, $aRow) = $SQLITE_OK Then
		MsgBox(48, 'Attenzione', 'Dataset già associato!', "", $form_main)
	Else
		Local $local_file = FileOpenDialog("Associa a file locale", @HomePath, "All (*.*)", 10, "", $form_main)
		If $local_file <> '' Then
			_SQLite_Exec($hDB, 'INSERT INTO FAVMEMBER (name,path,tms_ult_var,local_file) VALUES ("' & $array[0] & '","' & $array[1] & '",current_timestamp, "' & $local_file & '");')
			refreshListFavMember()
		EndIf
	EndIf
	GUICtrlSetState($adv_btn_up, 128)
	GUICtrlSetState($adv_btn_up_all, 128)
	GUICtrlSetState($adv_btn_dw, 128)
	GUICtrlSetState($adv_btn_dw_all, 128)
	GUICtrlSetState($adv_btn_np, 128)
	GUICtrlSetState($adv_btn_ex, 128)
	GUICtrlSetState($btnAddMember, 128)
EndFunc

Func refreshListFavMember()
	_GUICtrlListView_DeleteAllItems($listFavMembers)
	_SQLite_Query($hDB, "SELECT name, path, local_file FROM FAVMEMBER ORDER BY tms_ult_var desc;", $hQuery)
	While _SQLite_FetchData($hQuery, $aRow) = $SQLITE_OK
		GUICtrlCreateListViewItem($aRow[0] & '|' & $aRow[1] & '|' & $aRow[2], $listFavMembers)
	WEnd
EndFunc

Func createMenu()
	Local $temp = GUICtrlCreateMenu("Fi&le")
		GUICtrlSetOnEvent(GUICtrlCreateMenuItem('&Esegui comando', $temp), 'sendCommand')
		GUICtrlSetOnEvent(GUICtrlCreateMenuItem("E&xit", $temp), 'closeClicked')
	$temp = GUICtrlCreateMenu("&View")
		Global $MenuItem_AOT = GUICtrlCreateMenuItem('&Sempre in primo piano', $temp)
			GUICtrlSetState(-1, iniReadW('alwaysOnTop', 4))
			GUICtrlSetOnEvent(-1, 'menuAoTClicked')
		GUICtrlSetOnEvent(GUICtrlCreateMenuItem('Apri &Log', $temp), 'debugSTART')
		GUICtrlSetOnEvent(GUICtrlCreateMenuItem('&File Status Table', $temp), 'menuOpenFileStatusClicked')
		GUICtrlSetOnEvent(GUICtrlCreateMenuItem('&DB2 Return Code Table', $temp), 'menuOpendb2rctableClicked')
		Global $MAV = GUICtrlCreateMenuItem('&Advanced View', $temp)
		GUICtrlSetOnEvent(-1, 'btnAdvClicked')
	$temp = GUICtrlCreateMenu("&FTP")
		GUICtrlSetOnEvent(GUICtrlCreateMenuItem("&Download", $temp), 'btnDownloadClicked')
		GUICtrlSetOnEvent(GUICtrlCreateMenuItem("&Upload da file", $temp), 'btnUpFileClicked')
		GUICtrlSetOnEvent(GUICtrlCreateMenuItem("&Apri con Notepad++", $temp), 'btnNotepadClicked')
		GUICtrlSetOnEvent(GUICtrlCreateMenuItem("Upload da &CTRL+C", $temp), 'btnUpClipClicked')
		GUICtrlSetOnEvent(GUICtrlCreateMenuItem("Apri con &Excel", $temp), 'btnExcelClicked')
	$temp = GUICtrlCreateMenu("&Settings")
		GUICtrlSetOnEvent(GUICtrlCreateMenuItem('&File impostazioni', $temp), 'menuOpenSettingsClicked')
		GUICtrlSetOnEvent(GUICtrlCreateMenuItem('&Cambia indirizzo FTP', $temp), 'menuSetIpClicked')
		GUICtrlSetOnEvent(GUICtrlCreateMenuItem('Cambia &exe Notepad++', $temp), 'menuSetNoteClicked')
		Global $menuAddSpa = GUICtrlCreateMenuItem("&Download con aggiunta spazi", $temp)
			GUICtrlSetState(-1, iniReadW('addSpa', 4))
			GUICtrlSetOnEvent(-1, 'menuAddSpaCliecked')
		Global $menuLowMem = GUICtrlCreateMenuItem('Upload che usa poca &RAM', $temp)
			GUICtrlSetState(-1, iniReadW('lowMemUp', 4))
			GUICtrlSetOnEvent(-1, 'menuLowMemClicked')
		Global $MenuItem_003 = GUICtrlCreateMenuItem('&Upload Automatico', $temp)
			GUICtrlSetState(-1, iniReadW('uploadMode', 1));$GUI_CHECKED = 1;$GUI_UNCHECKED = 4
			GUICtrlSetOnEvent(-1, 'menuUploadOptionClicked')
		Global $MenuItem_004 = GUICtrlCreateMenuItem('Cambia &LRECL', $temp)
			GUICtrlSetOnEvent(-1, 'menuLRECLClicked')
		Global $MenuItem_005 = GUICtrlCreateMenuItem('Cambia &RECFM', $temp)
			GUICtrlSetOnEvent(-1, 'menuRECFMClicked')
	$temp = GUICtrlCreateMenu("&?")
		GUICtrlSetOnEvent(GUICtrlCreateMenuItem("&Visualizza pseudo sorgente", $temp), 'menuSRCClicked')
		GUICtrlSetOnEvent(GUICtrlCreateMenuItem("&Cerca aggiornamenti", $temp), 'versionCheck')
		GUICtrlCreateMenuItem('', $temp)
		GUICtrlSetOnEvent(GUICtrlCreateMenuItem("&About", $temp), 'menuAboutClicked')
EndFunc

Func createContextMenu()
	Local $idContextmenu = GUICtrlCreateContextMenu()
	Local $temp = GUICtrlCreateMenu('Fi&le', $idContextmenu)
		GUICtrlSetOnEvent(GUICtrlCreateMenuItem('&Esegui comando', $temp), 'sendCommand')
		GUICtrlSetOnEvent(GUICtrlCreateMenuItem('E&xit', $temp), 'closeClicked')
	$temp = GUICtrlCreateMenu('&View', $idContextmenu)
		Global $idMenuAoT = GUICtrlCreateMenuItem('&Sempre in primo piano', $temp)
			GUICtrlSetState(-1, iniReadW('alwaysOnTop', 4))
			GUICtrlSetOnEvent(-1, 'menuAoTClicked')
		GUICtrlSetOnEvent(GUICtrlCreateMenuItem('Apri &Log', $temp), 'debugSTART')
		GUICtrlSetOnEvent(GUICtrlCreateMenuItem('&File Status Table', $temp), 'menuOpenFileStatusClicked')
		GUICtrlSetOnEvent(GUICtrlCreateMenuItem('&DB2 Return Code Table', $temp), 'menuOpendb2rctableClicked')
		Global $CMAV = GUICtrlCreateMenuItem('&Advanced View', $temp)
			GUICtrlSetOnEvent(-1, 'btnAdvClicked')
	$temp = GUICtrlCreateMenu('&FTP', $idContextmenu)
		GUICtrlSetOnEvent(GUICtrlCreateMenuItem("&Download", $temp), 'btnDownloadClicked')
		GUICtrlSetOnEvent(GUICtrlCreateMenuItem("Apri con &Excel", $temp), 'btnExcelClicked')
		GUICtrlSetOnEvent(GUICtrlCreateMenuItem("&Apri con Notepad++", $temp), 'btnNotepadClicked')
		GUICtrlSetOnEvent(GUICtrlCreateMenuItem("&Upload da file", $temp), 'btnUpFileClicked')
		GUICtrlSetOnEvent(GUICtrlCreateMenuItem("Upload da &CTRL+C", $temp), 'btnUpClipClicked')
	$temp = GUICtrlCreateMenu('&Settings', $idContextmenu)
		GUICtrlSetOnEvent(GUICtrlCreateMenuItem('&File impostazioni', $temp), 'menuOpenSettingsClicked')
		GUICtrlSetOnEvent(GUICtrlCreateMenuItem('&Cambia indirizzo FTP', $temp), 'menuSetIpClicked')
		GUICtrlSetOnEvent(GUICtrlCreateMenuItem('Cambia &exe Notepad++', $temp), 'menuSetNoteClicked')
		Global $menuAddSpaC = GUICtrlCreateMenuItem("&Download con aggiunta spazi", $temp)
			GUICtrlSetState(-1, iniReadW('addSpa', 4))
			GUICtrlSetOnEvent(-1, 'menuAddSpaCliecked')
		Global $menuLowMemC = GUICtrlCreateMenuItem('Upload che usa poca &RAM', $temp)
			GUICtrlSetState(-1, iniReadW('lowMemUp', 4))
			GUICtrlSetOnEvent(-1, 'menuLowMemClicked')
		Global $idMenuUploadOption = GUICtrlCreateMenuItem('&Upload Automatico', $temp);, -1, 1)
			GUICtrlSetState(-1, iniReadW('uploadMode', 1));$GUI_CHECKED = 1;$GUI_UNCHECKED = 4
			GUICtrlSetOnEvent(-1, 'menuUploadOptionClicked')
		Global $idMenuLRECL = GUICtrlCreateMenuItem('Cambia &LRECL', $temp)
			GUICtrlSetOnEvent(-1, 'menuLRECLClicked')
		Global $idMenuRECFM = GUICtrlCreateMenuItem('Cambia &RECFM', $temp)
			GUICtrlSetOnEvent(-1, 'menuRECFMClicked')
	$temp = GUICtrlCreateMenu('&?', $idContextmenu)
		GUICtrlSetOnEvent(GUICtrlCreateMenuItem('&Visualizza pseudo sorgente', $temp), 'menuSRCClicked')
		GUICtrlSetOnEvent(GUICtrlCreateMenuItem("&Cerca aggiornamenti", $temp), 'versionCheck')
		GUICtrlCreateMenuItem('', $temp)
		GUICtrlSetOnEvent(GUICtrlCreateMenuItem('&About', $temp), 'menuAboutClicked')
EndFunc

Func menuAddSpaCliecked()
	_DebugOut('menuAddSpaCliecked')
	If iniReadW('addSpa', 4) = 1 Then
		iniWriteW('addSpa', 4)
		GUICtrlSetState($menuAddSpa, 4)
		GUICtrlSetState($menuAddSpaC, 4)
	Else
		iniWriteW('addSpa', 1)
		GUICtrlSetState($menuAddSpa, 1)
		GUICtrlSetState($menuAddSpaC, 1)
	EndIf
EndFunc

Func WM_ListView_DoubleClick($hWnd, $iMsg, $wParam, $lParam)
	#forceref $hWnd, $iMsg, $wParam
	Local $tNMHDR = DllStructCreate("int;int;int", $lParam)
	If @error Then Return
	If DllStructGetData($tNMHDR, 1) = $h_listBox_local Then
		If DllStructGetData($tNMHDR, 3) = $NM_DBLCLK Then doubleClickLocal()
		If DllStructGetData($tNMHDR, 3) = $NM_CLICK Then clickLocal()
		$lastClick = $h_listBox_local
	EndIf
	If DllStructGetData($tNMHDR, 1) = $h_listBox_host Then
		If DllStructGetData($tNMHDR, 3) = $NM_DBLCLK Then doubleClickHost()
		If DllStructGetData($tNMHDR, 3) = $NM_CLICK Then clickHost()
		$lastClick = $h_listBox_host
	EndIf
	If DllStructGetData($tNMHDR, 1) = $h_listBox_listFav Then
		If DllStructGetData($tNMHDR, 3) = $NM_CLICK Then clickFavLocal()
		$lastClick = $h_listBox_listFav
	EndIf
	If DllStructGetData($tNMHDR, 1) = $h_listBox_listFavM Then
		If DllStructGetData($tNMHDR, 3) = $NM_CLICK Then clickFavHost()
		$lastClick = $h_listBox_listFavM
	EndIf
	$tNMHDR = 0
	Return $GUI_RUNDEFMSG
EndFunc

Func clickFavHost()
	_DebugOut("clickFavHost")
	GUICtrlSetState($btnAddMember, 128)
	If _GUICtrlListView_GetSelectedCount($h_listBox_listFavM) = 1 Then
		GUICtrlSetState($btnRmvMember, 64)
		GUICtrlSetState($adv_btn_up, 64)
		GUICtrlSetState($adv_btn_dw, 64)
		GUICtrlSetState($adv_btn_np, 64)
		GUICtrlSetState($adv_btn_ex, 64)
		Return
	EndIf
	GUICtrlSetState($btnRmvMember, 128)
	GUICtrlSetState($adv_btn_up, 128)
	GUICtrlSetState($adv_btn_up_all, 128)
	GUICtrlSetState($adv_btn_dw, 128)
	GUICtrlSetState($adv_btn_dw_all, 128)
	GUICtrlSetState($adv_btn_np, 128)
	GUICtrlSetState($adv_btn_ex, 128)
EndFunc

Func btnRmvFrFavClicked()
	_DebugOut("btnRmvFrFavClicked")
	If _GUICtrlListView_GetSelectedCount($listFav) = 1 Then
		_SQLite_Exec($hDB, "DELETE FROM FAVFOLDER WHERE path='" & readList(2, $listFav) & "';")
		refreshListFav()
	EndIf
EndFunc

Func clickFavLocal()
	_DebugOut("clickFavLocal")
	GUICtrlSetState($btnAddToFav, 128)
	If _GUICtrlListView_GetSelectedCount($h_listBox_listFav) = 1 Then
		GUICtrlSetState($btnRmvFrFav, 64)
		slcInsUpd(readList(2, $listFav), "LASTLOCAL")
		refreshCombo("LASTLOCAL", $adv_in_path_local)
		refreshListBoxLocal()
		Return
	EndIf
	GUICtrlSetState($btnRmvFrFav, 128)
EndFunc

Func doubleClickHost()
	_DebugOut("doubleClickHost")
	If readList(1, $adv_listBox_host) = '..' Then
		Local $string = GUICtrlRead($adv_in_path_host)
		Local $a = StringSplit($string, '.', 2)
		If IsArray($a) Then
			$string = $a[0]
			For $i = 1 To UBound($a) -2
				$string &= '.' & $a[$i]
			Next
			GUICtrlSetData($adv_in_path_host, $string, $string)
			refreshListBoxHost()
		EndIf
		Return
	EndIf
	If readList(3, $adv_listBox_Host) = 'Y' Then
		GUICtrlSetData($adv_in_path_host, readList(2, $adv_listBox_Host), readList(2, $adv_listBox_Host))
		refreshListBoxHost()
		Return
	EndIf
EndFunc

Func clickHost()
	_DebugOut("clickHost")
	GUICtrlSetState($btnAddToFav, 128)
	GUICtrlSetState($btnRmvMember, 128)
	GUICtrlSetState($adv_btn_dw_all, 128)
	If readList(3, $adv_listBox_Host) <> 'Y' And readList(1, $adv_listBox_Host) <> '..' Then
		If iniReadW('preview', 'off') = 'on' Then
			Local $sLocalFile = _TempFile(@TempDir, '', '')
			Local $sRemoteFile = readList(2, $adv_listBox_host)
			If ftp('GET', $sLocalFile, $sRemoteFile) = 0 Then Return
			Local $string = '', $array = FileReadToArray($sLocalFile)
			For $i = 0 To UBound($array) -1
				$string &= $array[$i] & @CRLF
			Next
			GUICtrlSetData($adv_edit_preview, $string)
		Else
			GUICtrlSetData($adv_edit_preview, $aString[1])
		EndIf
	EndIf
	If _GUICtrlListView_GetSelectedCount($adv_listBox_Host) = 1 Then
		If readList(3, $adv_listBox_Host) <> 'Y' And readList(1, $adv_listBox_Host) <> '..' Then
			GUICtrlSetState($btnAddMember, 64)
			GUICtrlSetState($adv_btn_dw, 64)
			GUICtrlSetState($adv_btn_np, 64)
			GUICtrlSetState($adv_btn_ex, 64)
			; se NON esiste readList(2, £adv_listBox_Host) --> cambialo
			Return
		EndIf
	ElseIf _GUICtrlListView_GetSelectedCount($adv_listBox_Host) > 1 Then
;~ 		MsgBox(0,0,0)
		GUICtrlSetState($adv_btn_dw_all, 64)
	EndIf

	GUICtrlSetState($btnAddMember, 128)
	GUICtrlSetState($adv_btn_dw, 128)
	GUICtrlSetState($adv_btn_np, 128)
	GUICtrlSetState($adv_btn_ex, 128)
EndFunc

Func doubleClickLocal()
	If readList(1, $adv_listBox_local) = '..' Then
		Local $string = GUICtrlRead($adv_in_path_local)
		Local $a = StringSplit($string, '\', 2)
		If IsArray($a) Then
			$string = $a[0]
			For $i = 1 To UBound($a) -2
				$string &= '\' & $a[$i]
			Next
			GUICtrlSetData($adv_in_path_local, $string, $string)
			refreshListBoxLocal()
		EndIf
		Return
	EndIf
	If IsDir(readList(2, $adv_listBox_local)) Then
		slcInsUpd(readList(2, $adv_listBox_local), "LASTLOCAL")
		refreshCombo("LASTLOCAL", $adv_in_path_local)
		refreshListBoxLocal()
		Return
	EndIf
EndFunc

Func clickLocal()
	GUICtrlSetState($btnAddMember, 128)
	GUICtrlSetState($adv_btn_dw, 128)
	GUICtrlSetState($adv_btn_np, 128)
	GUICtrlSetState($adv_btn_ex, 128)
	If _GUICtrlListView_GetSelectedCount($adv_listBox_local) = 1 Then
		Local $temp = readList(2, $adv_listBox_local)
		If IsDir($temp) Then
			GUICtrlSetState($btnAddToFav, 64)
		Else
			GUICtrlSetState($btnAddToFav, 128)
			If FileExists($temp) Then
				GUICtrlSetState($adv_btn_up, 64)
				Return 0
			EndIf
		EndIf
	EndIf
	GUICtrlSetState($adv_btn_up, 128)
EndFunc

Func btnAddToFavClicked()
	_DebugOut('btnAddToFavClicked')
	Local $array = readList(0, $adv_listBox_local)
	_SQLite_Exec($hDB, 'INSERT INTO FAVFOLDER (name,path,tms_ult_var) VALUES ("' & $array[0] & '","' & $array[1] & '",current_timestamp);')
	refreshListFav()
EndFunc

Func refreshListFav()
	_GUICtrlListView_DeleteAllItems ( $listFav )
	_SQLite_Query($hDB, "SELECT name, path FROM FAVFOLDER ORDER BY tms_ult_var desc;", $hQuery)
	While _SQLite_FetchData($hQuery, $aRow) = $SQLITE_OK
		Local $h = GUICtrlCreateListViewItem($aRow[0] & '|' & $aRow[1], $listFav)
		GUICtrlSetBkColor($h, $cGiallino)
	WEnd
EndFunc

Func IsDir($sFilePath)
   Return StringInStr(FileGetAttrib($sFilePath), "D") > 0
EndFunc

Func readList($flag, $listBox)
	Local $temp = GUICtrlRead(GUICtrlRead($listBox))
	Local $array = StringSplit($temp, '|', 2)
	If IsArray($array) Then
		Switch $flag
			Case 0
				Return $array
			Case 1
				Return $array[0]
			Case 2
				If UBound($array) > 1 Then Return $array[1]
			Case 3
				If UBound($array) > 2 Then Return $array[2]
		EndSwitch
	EndIf
	Return 0
EndFunc

Func btnAdvClicked()
	_DebugOut('btnAdvClicked')
	Local $loc = WinGetPos($form_main)
	Local Const $x = 727
	Local Const $y = 774
	If iniReadW('advV', '1') = 1 Then
		WinMove($form_main, '', $loc[0], $loc[1], 347, 219)
		GUICtrlSetData($btn_adv, 'Advanced')
		GUICtrlSetTip($btn_adv, 'Vista avanzata', 'Info', 1, 1)
		GUICtrlSetData($CMAV, '&Advanced View')
		GUICtrlSetData($MAV, '&Advanced View')
		iniWriteW('advV', "0")
	Else
		GUICtrlSetData($btn_adv, 'Loading...')
		refreshCombo("LASTCATALOG", $adv_in_path_host)
		refreshListBoxHOST()
		If $loc[0] + $x >= @DesktopWidth Then $loc[0] = @DesktopWidth - $x
		If $loc[1] + $y >= @DesktopHeight Then $loc[1] = @DesktopHeight - $y
		WinMove($form_main, '', $loc[0], $loc[1], $x, $y)
		GUICtrlSetData($btn_adv, 'Basic')
		GUICtrlSetTip($btn_adv, 'Vista Basic', 'Info', 1, 1)
		GUICtrlSetData($CMAV, '&Basic View')
		GUICtrlSetData($MAV, '&Basic View')
		iniWriteW('advV', "1")
	EndIf
EndFunc

Func advChkPrevClicked()
   _DebugOut('advChkPrevClicked')
	Local $loc = WinGetPos($form_main)
	GUICtrlSetData($adv_edit_preview, '')
	If iniReadW('preview', 'off') = 'on' Then
		GUICtrlSetData($adv_edit_preview, $aString[1])
		GUICtrlSetData($adv_chk_prev, 'Anteprima disabilitato')
		iniWriteW('preview', 'off')
	Else
		GUICtrlSetData($adv_edit_preview, $aString[0])
		GUICtrlSetData($adv_chk_prev, 'Anteprima abilitato')
		iniWriteW('preview', 'on')
	EndIf
EndFunc

Func versionCheck()
	Local $temp = IniRead($sFullININame, 'main', 'version', $sVersion)
	ConsoleWrite('prod version: ' & $temp & @CRLF & 'this version: ' & $sVersion & @CRLF)
	If $sVersion < $temp Then MsgBox(48, 'Version Check', 'Nuova versione ' & $temp & ' disponibile!' & @CRLF & 'in ' & $sCheckpath, 0)
EndFunc

Func sendCommand()
	_DebugOut('sendCommand_clicked')
	Local $temp = inputBoxW('Comando:' & @CRLF & @CRLF & '(Apri log per dettagli)', ''), $string = ''
	If StringLeft($temp, 1) = '$' Then
		ShellExecute(StringMid($temp, 2))
	ElseIf StringLeft($temp, 1) = '@' Then
		Call(StringMid($temp, 2))
	Else
		If $temp <> '' Then MsgBox(48, 'Result', 'Return Code: ' & _SQLite_Query($hDB, $temp, $hQuery), 5, $form_main)
		While _SQLite_FetchData($hQuery, $aRow) = $SQLITE_OK
			$string = ''
			For $i = 0 To UBound($aRow) -1
				$string &= $aRow[$i] & @TAB
			Next
			_DebugOut(StringTrimRight($string, 1))
		WEnd
	EndIf
EndFunc

Func inputBoxW($sPrompt, $sDefault, $sForm = $form_main)
	Return InputBox($sTitle, $sPrompt, $sDefault, Default, -1, -1, Default, Default, 0, $sForm)
EndFunc

Func closeClicked()
	_DebugOut('normal close call')
	_SQLite_Close($hDB)
   _SQLite_Shutdown()
	Local $aLocs = WinGetPos($sTitle)
	If IsArray($aLocs) Then
		iniWriteW('xLoc', $aLocs[0])
		iniWriteW('yLoc', $aLocs[1])
	EndIf
	iniWriteW('FTPuser', GUICtrlRead($input_user))
	iniWriteW('FTPpass', GUICtrlRead($input_pass))
	GUIDelete($form_main)
	Exit 0
EndFunc

Func refreshLabelGroup()
	If iniReadW('alwaysOnTop', 4) = 1 Then
		WinSetOnTop($sTitle, '', 1)
	Else
		WinSetOnTop($sTitle, '', 0)
	EndIf
	Local $temp = 64
	If iniReadW('uploadMode', 1) = 1 Then $temp = 128
	GUICtrlSetState($idMenuRECFM, $temp)
	GUICtrlSetState($idMenuLRECL, $temp)
	GUICtrlSetState($MenuItem_004, $temp)
	GUICtrlSetState($MenuItem_005, $temp)
	$temp = iniReadW('rECFM', 'FB')
	If iniReadW('lRECL', 'auto') = 'auto' Then $temp = 'AUTO'
	GUICtrlSetData($sGroup, 'FTP ' & iniReadW('FTPip', $sdFTPaddress) & ' - LRECL=' & iniReadW('lRECL', 'auto') & ' RECFM=' & $temp)
EndFunc

Func debugSTART()
	_DebugSetup($sTitle & ' log window', True)
EndFunc

Func iniReadW($sKey, $sDefault)
	Return StringStripWS(StringUpper(IniRead($sFileIni, 'main', $sKey, $sDefault)), 3)
EndFunc

Func iniWriteW($sKey, $sValue)
	If $sValue = '' Or DirCreate($sDirIni) = 0 Then Return
	If IniWrite($sFileIni, 'main', $sKey, $sValue) <> 1 Then
		_DebugOut('error on write ' & $sFileIni)
	Else
		_DebugOut('1 record written on ' & $sFileIni & ' ' & $sKey & '=' & $sValue)
	EndIf
EndFunc

Func menuAoTClicked()
	_DebugOut('menuAoTClicked')
	If iniReadW('alwaysOnTop', 4) = 1 Then
		WinSetOnTop($sTitle, '', 1)
		iniWriteW('alwaysOnTop', 4)
		GUICtrlSetState($idMenuAoT, 4)
		GUICtrlSetState($MenuItem_AOT, 4)
	Else
		WinSetOnTop($sTitle, '', 0)
		iniWriteW('alwaysOnTop', 1)
		GUICtrlSetState($idMenuAoT, 1)
		GUICtrlSetState($MenuItem_AOT, 1)
	EndIf
	refreshLabelGroup()
EndFunc

Func menuLowMemClicked()
	_DebugOut('menuLowMemClicked')
	If iniReadW('lowMemUp', 4) = 1 Then
		iniWriteW('lowMemUp', 4)
		GUICtrlSetState($menuLowMem, 4)
		GUICtrlSetState($menuLowMemC, 4)
	Else
		iniWriteW('lowMemUp', 1)
		GUICtrlSetState($menuLowMem, 1)
		GUICtrlSetState($menuLowMemC, 1)
	EndIf
EndFunc

Func initDB()
	FileInstall('.\sqlite3.dll', $sDirIni & '\sqlite3.dll', 1)
	_SQLite_Startup($sDirIni & '\sqlite3.dll', True, 1, _DebugOut)
	$hDB = _SQLite_Open($sDirIni & '\database.db')
	_SQLite_Exec($hDB, 'CREATE TABLE LASTNOTE(name,tms_ult_var);')
	_SQLite_Exec($hDB, 'CREATE TABLE LASTCATALOG(name,tms_ult_var);')
	_SQLite_Exec($hDB, 'CREATE TABLE LASTDOWNLOAD(name,tms_ult_var);')
	_SQLite_Exec($hDB, 'CREATE TABLE LASTEXCEL(name,tms_ult_var);')
	_SQLite_Exec($hDB, 'CREATE TABLE LASTUPLOAD(name,tms_ult_var);')
	_SQLite_Exec($hDB, 'CREATE TABLE LASTLOCAL(name,tms_ult_var);')
	_SQLite_Exec($hDB, 'CREATE TABLE FAVFOLDER(name,path,tms_ult_var);')
	_SQLite_Exec($hDB, 'CREATE TABLE FAVMEMBER(name,path,tms_ult_var,local_file);')
EndFunc

Func menuSetNoteClicked()
	_DebugOut('menuSetNoteClicked')
	Local $temp = FileOpenDialog ( "Seleziona l'eseguibile", @CommonFilesDir, "exe files (*.exe)", 3, "", $form_main)
	If $temp <> '' Then iniWriteW('notepad++', $temp)
EndFunc

Func menuSRCClicked()
	_DebugOut('menuSRCClicked')
	FileInstall('.\SAIMON_FTP.au3', @TempDir & '\SAIMON_FTP.au3', 1)
	If ShellExecute(iniReadW('notepad++', 'Notepad++'), @TempDir & '\SAIMON_FTP.au3') = -1 Then ShellExecute(@TempDir & '\SAIMON_FTP.au3')
EndFunc

Func menuAboutClicked()
	_DebugOut('menuAboutClicked')
	MsgBox(64, 'About', $sTitle & ' - 100% free software' & @CRLF & @CRLF & _
	'Programma creato per interfacciarsi al meglio con protocollo FTP tra sistemi operativi Windows© e Host Z-OS© Mainframe.' & _
	@CRLF & @CRLF & 'Created by simon387@hotmail.it' & @CRLF & 'Testers and ideas: Romilda, Medico Alessandri, PRFIGB1', 60, $form_main)
EndFunc

Func menuSetIpClicked()
	_DebugOut('menuSetIpClicked')
	Local $temp = inputBoxW('Indirizzo FTP:', iniReadW('FTPip', $sdFTPaddress))
	If $temp <> '' Then
		iniWriteW('FTPip', $temp)
		refreshLabelGroup()
		checkUP()
	EndIf
EndFunc

Func menuRECFMClicked()
	_DebugOut('menuRECFMClicked')
	Local $temp = StringUpper(inputBoxW('RECFM=' & @CRLF & 'Possibili valori=[FA FB FBA FBM FM U V VA VB VBA VBM FB]', 'FB'))
	Switch $temp
	Case 'FA' Or 'FB' Or 'FBA' Or 'FBM' Or 'FM' Or 'U' Or 'V' Or 'VA' Or 'VB' Or 'VBA' Or 'VBM' Or 'VBS'
		iniWriteW('rECFM', $temp)
	Case Else
		iniWriteW('rECFM', 'FB')
	EndSwitch
	refreshLabelGroup()
EndFunc

Func menuLRECLClicked()
	_DebugOut('menuLRECLClicked')
	Local $temp = inputBoxW('Specifica LRECL (numerico)=', IniReadW('lRECL', 80))
	If $temp <> '' And $temp > 0 And $temp < 32767 And IsNumber(Number($temp)) Then iniWriteW('lRECL', $temp)
	refreshLabelGroup()
EndFunc

Func menuUploadOptionClicked()
	_DebugOut('menuUploadOptionClicked')
	If iniReadW('uploadMode', 1) = 1 Then
		Local $temp = inputBoxW('Specifica LRECL (numerico)=', iniReadW('lRECL', 'auto'))
		If $temp <> '' And $temp > 0 And $temp < 32767 And IsNumber(Number($temp)) Then
			iniWriteW('lRECL', $temp)
			iniWriteW('uploadMode', 4)
			GUICtrlSetState($idMenuUploadOption, 4)
			GUICtrlSetState($MenuItem_003, 4)
		EndIf
	Else
		iniWriteW('uploadMode', 1)
		iniWriteW('lRECL', 'auto')
		iniWriteW('rECFM', 'FB')
		GUICtrlSetState($idMenuUploadOption, 1)
		GUICtrlSetState($MenuItem_003, 1)
	EndIf
	If iniReadW('uploadMode', 1) = 1 And iniReadW('lRECL', 'auto') <> 'auto' Then iniWriteW('lRECL', 'auto')
	refreshLabelGroup()
EndFunc

Func menuOpenFileStatusClicked()
	_DebugOut('menuOpenFileStatusClicked')
	FileInstall('.\FILE_STATUS.txt', @TempDir & '\FILE_STATUS.txt', 1)
	If ShellExecute(iniReadW('notepad++', 'Notepad++'), @TempDir & '\FILE_STATUS.txt') = -1 Then ShellExecute(@TempDir & '\FILE_STATUS.txt')
EndFunc

Func menuOpendb2rctableClicked()
	_DebugOut('menuOpendb2rctableClicked')
	FileInstall('.\db2rctable.html', @TempDir & '\db2rctable.html', 1)
	ShellExecute(@TempDir & '\db2rctable.html')
EndFunc

Func advBtnUpAllClicked()
	_DebugOut('advBtnUpAllClicked')
	MsgBox(48, 'Alert #advBtnUpAllClicked', 'No grant for this operation', 0, $form_main)
EndFunc

Func advBtnDwAllClicked()
	_DebugOut('advBtnDwAllClicked')
;~ 	Local $array = _GUICtrlListBox_GetSelItemsText($adv_listBox_host)
	Local $array = _GUICtrlListView_GetSelectedIndices($adv_listBox_host, True)

;~ 	MsgBox(0,0,$string)
;~ 	_ArrayDisplay($array)
;~ 	For $i = 1 To $array[0]
;~ 		ConsoleWrite(_GUICtrlListView_GetItemText($adv_listBox_host, $array[$i], 1)     & @CRLF)
;~ 	Next

;~ 	Return
;~ zzzzzzzzzz
	If GUICtrlRead($adv_in_path_host) = '' Or GUICtrlRead($adv_listBox_host) = '' Then Return
	If DirGetSize(GUICtrlRead($adv_in_path_local)) = -1 Then Return

	If IsArray($array) Then
		For $i = 1 To $array[0]
			Local $sLocalFile = GUICtrlRead($adv_in_path_local) & '\' & _GUICtrlListView_GetItemText($adv_listBox_host, $array[$i], 0)
			Local $sRemoteFile = _GUICtrlListView_GetItemText($adv_listBox_host, $array[$i], 1)
;~ 			MsgBox(0,0,$sLocalFile&@CRLF&$sRemoteFile)
;~ 			Return
;~ 			Local $sLocalFile = GUICtrlRead($adv_in_path_local) & '\' & $array[$i]
;~ 			Local $sRemoteFile = gUIctrlReadSWW($adv_in_path_host) & '(' & StringStripWS($array[$i], 3) & ')'
			If ftp('GET', $sLocalFile, $sRemoteFile) = 0 Then Return
			refreshListBoxLocal()
		Next
		MsgBox(64, 'OK', 'File salvati correttamente' & @CRLF & 'in ' & GUICtrlRead($adv_in_path_local) & '\' & @CRLF & @CRLF & '(' & $i -1 & ' files)', 0, $form_main)
	EndIf
EndFunc

Func menuOpenSettingsClicked()
	_DebugOut('menuOpenSettingsClicked')
	If ShellExecute(iniReadW('notepad++', 'Notepad++'), $sFileIni) = -1 Then ShellExecute($sFileIni)
EndFunc

Func advBtnUpClicked()
	_DebugOut('advBtnUpClicked')
	If $lastClick = $h_listBox_listFavM Then
		Local $sLocalFile = readList(3, $listFavMembers)
		Local $sRemoteFile = readList(2, $listFavMembers)
		If ftp('PUT', $sLocalFile, $sRemoteFile) = 0 Then Return
		MsgBox(64, 'OK', 'Upload completato con successo' & @CRLF & 'in ' & $sRemoteFIle & @CRLF & @CRLF & '(' & $iCounter & ' righe)', 0, $form_main)
	Else
		If GUICtrlRead($adv_in_path_local) = '' Or GUICtrlRead($adv_listBox_local) = '' Then Return
		uploadW(GUICtrlRead($adv_in_path_local) & '\' & GUICtrlRead($adv_listBox_local), gUIctrlReadSWW($adv_in_path_host) & '(' & gUIctrlReadSWW($adv_listBox_host) & ')', $form_main)
	EndIf
EndFunc

Func advBtnDwClicked()
	_DebugOut('advBtnDwClicked')
	If $lastClick = $h_listBox_listFavM Then
		Local $sRemoteFile = readList(2, $listFavMembers)
		Local $sLocalFile = readList(3, $listFavMembers)
		If ftp('GET', $sLocalFile, $sRemoteFile) = 0 Then Return
		MsgBox(64, 'OK', 'File salvato correttamente' & @CRLF & 'in ' & readList(3, $listFavMembers), 0, $form_main)
	Else
		If DirGetSize(GUICtrlRead($adv_in_path_local)) = -1 Then Return
		Local $sRemoteFile = readList(2, $adv_listBox_host)
		Local $sLocalFile = GUICtrlRead($adv_in_path_local) & '\' & $sRemoteFile
		$sLocalFile = StringReplace($sLocalFile, '\\', '\')
		If ftp('GET', $sLocalFile, $sRemoteFile) = 0 Then Return
		refreshListBoxLocal()
		MsgBox(64, 'OK', 'File salvato correttamente' & @CRLF & 'in ' & GUICtrlRead($adv_in_path_local), 0, $form_main)
	EndIf
EndFunc

Func advBtnExClicked()
	_DebugOut('advBtnExClicked')
	If $lastClick = $h_listBox_listFavM Then
		Local $sRemoteFile = readList(2, $listFavMembers)
		Local $sLocalFile = _TempFile(@TempDir, '' & readList(2, $listFavMembers) & '~', '.CSV')
	Else
		Local $sRemoteFile = readList(2, $adv_listBox_host)
		Local $sLocalFile = _TempFile(@TempDir, '' & readList(2, $adv_listBox_host) & '~', '.CSV')
	EndIf
	If ftp('GET', $sLocalFile, $sRemoteFile) = 0 Then Return
	ShellExecute(iniReadW('Excel', 'Excel'), $sLocalFile)
EndFunc

Func advBtnNpClicked()
	_DebugOut('advBtnNpClicked')
	If $lastClick = $h_listBox_listFavM Then
		Local $sRemoteFile = readList(2, $listFavMembers)
		Local $sLocalFile = _TempFile(@TempDir, '' & readList(2, $listFavMembers) & '~', '')
	Else
		Local $sRemoteFile = readList(2, $adv_listBox_host)
		Local $sLocalFile = _TempFile(@TempDir, '' & readList(2, $adv_listBox_host) & '~', '')
	EndIf
	If ftp('GET', $sLocalFile, $sRemoteFile) = 0 Then Return
	ShellExecute(iniReadW('notepad++', 'Notepad++'), $sLocalFile)
EndFunc

Func advBtnRefClicked()
	_DebugOut('advBtnRefClicked');If StringRegExp(gUIctrlReadSWW($adv_in_path_host), '^[a-z]|\$([a-z]|\d|\$){1,7}(\.[a-z]|\$([a-z]|\d|\$){1,7})+$') = 0 Then Return
	If refreshListBoxHOST() Then
		slcInsUpd(gUIctrlReadSWW($adv_in_path_host), 'LASTCATALOG')
	EndIf
EndFunc

Func refreshListBoxHOST()
	_DebugOut('refreshListBoxHOST')
	_GUICtrlListView_DeleteAllItems($adv_ListBox_host)
	Local $aList = ftp('LIST', '', gUIctrlReadSWW($adv_in_path_host))
	If IsArray($aList) Then
		If UBound($aList) > 1 Then
			If $aList[1][0] = 'Name     VV.MM   Created       Changed      Size  Init   Mod   Id' Then
				GUICtrlCreateListViewItem('..|..|', $adv_ListBox_host)
				For $i = 2 To UBound($aList) -1
					Local $a = StringSplit(StringStripWS($aList[$i][0], 4), ' ', 2)
					If IsArray($a) Then
						Local $string = StringLeft($aList[$i][0], 8) & '|' & StringUpper(gUIctrlReadSWW($adv_in_path_host) & '.' & StringLeft($aList[$i][0], 8))
						If $a[UBound($a) - 2] = 'PO' Then $string &= '|Y'
						Local $h = GUICtrlCreateListViewItem($string, $adv_ListBox_host)
						If $a[UBound($a) - 2] = 'PO' Then GUICtrlSetBkColor($h, $cGiallino)
					EndIf
				Next
			EndIf
			If $aList[1][0] = 'Volume Unit    Referred Ext Used Recfm Lrecl BlkSz Dsorg Dsname' Then
				GUICtrlCreateListViewItem('..|..|', $adv_ListBox_host)
				For $i = 2 To UBound($aList) -1
					Local $a = StringSplit(StringStripWS($aList[$i][0], 4), ' ', 2)
					If IsArray($a) Then
						Local $string = $a[UBound($a) - 1] & '|' & StringUpper(gUIctrlReadSWW($adv_in_path_host) & '.' & $a[UBound($a) - 1])
						If $a[UBound($a) - 2] = 'PO' Then $string &= '|Y'
						Local $h = GUICtrlCreateListViewItem($string, $adv_ListBox_host)
						If $a[UBound($a) - 2] = 'PO' Then GUICtrlSetBkColor($h, $cGiallino)
					EndIf
				Next
			EndIf
		EndIf
	EndIf
	If _GUICtrlListView_GetItemCount($adv_ListBox_host) = 0 Then
		GUICtrlCreateListViewItem('..|..|', $adv_ListBox_host)
		Return False
	Else
		Return True
	EndIf
EndFunc

Func advBtnLocalClicked()
	_DebugOut('advBtnLocalClicked')
	Local $temp = FileSelectFolder('Seleziona la cartella locale', @HomePath, 7, "", $form_main)
	If $temp <> '' Then
		GUICtrlSetData($adv_in_path_local, $temp)
		slcInsUpd($temp, "LASTLOCAL")
		refreshCombo("LASTLOCAL", $adv_in_path_local)
		refreshListBoxLocal()
	EndIf
EndFunc

Func refreshListBoxLocal()
	_DebugOut('refreshListBoxLocal')
	_GUICtrlListView_DeleteAllItems($adv_listBox_local)
	If GUICtrlRead($adv_in_path_local) = "" Then GUICtrlSetData($adv_in_path_local, "c:\", "c:\")
	Local $array = _FileListToArray(GUICtrlRead($adv_in_path_local), '*', 0, False);, $string = '..|'
	Local $brray = _FileListToArray(GUICtrlRead($adv_in_path_local), '*', 0, True)
	GUICtrlCreateListViewItem("..|Cartella superiore", $adv_listBox_local)
	If IsArray($array) Then
		For $i = 1 To $array[0]
			Local $h = GUICtrlCreateListViewItem($array[$i] & '|' & $brray[$i], $adv_listBox_local)
			If isDir($brray[$i]) Then GUICtrlSetBkColor($h, $cGiallino)
		Next
	EndIf
EndFunc

Func btnDownloadClicked()
	_DebugOut('btnDownloadClicked')
	Local $sLocalFile = _TempFile(@TempDir, '', '')
	Local $sRemoteFile = inputBoxWPRO('Membo Host da scaricare in locale', "LASTDOWNLOAD")
	If ftp('GET', $sLocalFile, $sRemoteFile) = 0 Then Return
	Local $filter = 'All (*.*)'
	Switch GUICtrlRead($btnExtensionDwn)
	Case 'csv'
		$filter = 'CSV (*.csv)'
	Case 'txt'
		$filter = 'Text files (*.txt)'
	EndSwitch
	Local $sPath = FileSaveDialog('Salva con nome', @HomePath, $filter, 18, $sRemoteFile, $form_main)
;~ 	Local $sPath = FileSaveDialog('Salva con nome', @HomePath, '', 18, $sRemoteFile, $form_main)
	If $sPath = '' Then Return

;~ 	MsgBox(0,0,$sLocalFile)
	If FileCopy($sLocalFile, $sPath, 9) = 1 Then
		MsgBox(64, 'OK', 'File salvato correttamente' & @CRLF & 'in ' & $sPath, 0, $form_main)
	Else
		MsgBox(16, 'KO', 'Errore nel salvare il file' & @CRLF & 'in ' & $sPath, 0, $form_main)
	EndIf
EndFunc

Func btnNotepadClicked()
	_DebugOut('btnNotepadClicked')
	Local $sRemoteFile = inputBoxWPRO('Membro Host da aprire con notepad++', "LASTNOTE")
	Local $sLocalFile = _TempFile(@TempDir, '' & $sRemoteFile & '~', '')
	If ftp('GET', $sLocalFile, $sRemoteFile) = 0 Then Return
	ShellExecute(iniReadW('notepad++', 'Notepad++'), $sLocalFile)
EndFunc

Func btnExcelClicked()
   _DebugOut('btnExcelClicked')
	Local $sRemoteFile = inputBoxWPRO('Membro Host da aprire con excel', "LASTEXCEL")
	Local $sLocalFile = _TempFile(@TempDir, '' & $sRemoteFile & '~', ".CSV")
	If ftp('GET', $sLocalFile, $sRemoteFile) = 0 Then Return
	ShellExecute(iniReadW('Excel', 'Excel'), $sLocalFile)
EndFunc

Func btnUpFileClicked()
	_DebugOut('btnUpFileClicked')
	Local $sLocalFile = FileOpenDialog('Seleziona il file da caricare su host', iniReadW('lastuploadir', @DesktopDir), 'All (*.*)', 1, '', $form_main)
	If @error <> 0 Then Return
	Local $array = StringSplit($sLocalFile, '\', 2), $dir = ''
	If IsArray($array) Then
		For $i = 0 To UBound($array) -2
			$dir &= $array[$i] & '\'
		Next
	EndIf
	iniWriteW('lastuploadir', $dir)
	uploadW($sLocalFile)
EndFunc

Func btnUpClipClicked()
	_DebugOut('btnUpClipClicked')
	Local $sLocalFile = _TempFile(@TempDir, '', '')
	FileWrite($sLocalFile, ClipGet())
	FileClose($sLocalFile)
	uploadW($sLocalFile)
	FileDelete($sLocalFile)
EndFunc

Func uploadW($sLocalFile, $defaultName = '', $form = $form_main)
	Local $sRemoteFile = inputBoxWPRO('Nome del file da creare/sovrascrivere su host', "LASTUPLOAD", $form)
	If ftp('PUT', $sLocalFile, $sRemoteFile) = 0 Then Return
	slcInsUpd($defaultName, 'LASTUPLOAD')
	MsgBox(64, 'OK', 'Upload completato con successo' & @CRLF & 'in ' & $sRemoteFIle & @CRLF & @CRLF & '(' & $iCounter & ' righe)', 0, $form)
EndFunc

Func gUIctrlReadSWW($ctrlID)
	Return StringStripWS(GUICtrlRead($ctrlID), 8)
EndFunc

Func checkUP()
	If ftp('CHECK', 1, 1) Then
		GUICtrlSetBkColor($sGroup, $CLR_DEFAULT)
	Else
		GUICtrlSetBkColor($sGroup, $COLOR_RED)
	EndIf
EndFunc

Func ONLOSTFOCUS($hWnd, $imsg, $iwParam, $ilParam)
	Local $setHK = False
	Local $nNotifyCode = BitShift($iwParam, 16)
	Local $nID = BitAND($iwParam, 0x0000FFFF)
	Local $hCtrl = $ilParam
;~ 	If $nNotifyCode = $EN_KILLFOCUS Then;$EN_CHANGE Then
;~ 		If $hCtrl = GUICtrlGetHandle($input_user) Or $hCtrl = GUICtrlGetHandle($input_pass) Then checkUP();troppo pericoloso fare questi check
;~ 	EndIf
	Return $GUI_RUNDEFMSG
EndFunc

Func btnExtensionDwnClicked()
	Local $temp = GUICtrlRead($btnExtensionDwn)
	Switch $temp
	Case ''
		$temp = 'txt'
	Case 'txt'
		$temp = 'csv'
	Case 'csv'
		$temp = ''
	EndSwitch
	GUICtrlSetData($btnExtensionDwn, $temp)
EndFunc

Func ftp($verb, $sLF, $sRF, $form = $form_main)
;~ 	MsgBox(0,0,gUIctrlReadSWW($input_pass))
	Local $cf = False
	If $verb = 'CHECK' Then $cf = True
	If $sRF = '' Then Return 0
	If $sLF = '' Then $sLF = @ScriptDir & '\' & $sRF
	$sRF = StringStripWS($sRF, 8)
	If Not $cf Then ToolTip('Connecting...')
	Local $ok = 0, $hOpen = _FTP_Open('FTPD1'), $hConn = 0, $sAddress = iniReadW('FTPip', $sdFTPaddress), $sUser = gUIctrlReadSWW($input_user), $sPass = gUIctrlReadSWW($input_pass), $list = 0
	If $hOpen = 0 Then
		If $cf Then Return 0
		errore("Errore nell'aprire la sessione FTP " & $hOpen)
	Else
		GUICtrlSetBkColor($sGroup, $CLR_DEFAULT);;$INTERNET_SERVICE_FTP
		$hConn = _FTP_Connect($hOpen, $sAddress, $sUser, $sPass, 0, $INTERNET_DEFAULT_FTP_PORT, $INTERNET_SERVICE_FTP, 0, _FTP_SetStatusCallback($hOpen, 'FTPStatusCallbackHandler'))
;~ 		_DebugOut('$hOpen=' & $hOpen & @CRLF & '$sAddress=' & $sAddress & @CRLF & '$sUser=' & $sUser & @CRLF & '$sPass=' & $sPass)
		If $hConn = 0 Then
			If $cf Then Return 0
			errore("Errore nell'autentificazione FTP" & @CRLF & @CRLF & "Nome utente o password errati")
		Else
			If $cf Then Return 1
			_FTP_DirSetCurrent($hConn, '..')
			Switch $verb
			Case 'GET'
				ToolTip('Downloading...')
				$ok = _FTP_FileGet($hConn, $sRF, $sLF, False, 0, $FTP_TRANSFER_TYPE_ASCII)
				If $ok = 0 Then
					$sRF = convMember($sRF)
					$ok = _FTP_FileGet($hConn, $sRF, $sLF, False, 0, $FTP_TRANSFER_TYPE_ASCII)
				EndIf
				If iniReadW('addSpa', 1) = 1 Then
					Local $temp = IniReadW('lRECL', '')
					If $temp <> '' And $temp > 0 And $temp < 32767 And IsNumber(Number($temp)) Then
						$sLf = addSpacesToMember($sLf, $temp)
					Else
						errore('Spazi non aggiunti, LRECL non specificato correttamente')
					EndIf
				EndIf
			Case 'PUT'
				ToolTip('Executing...')
				Local $sLFTmp = _TempFile(@TempDir, '', '')
				FileCopy($sLF, $sLFTmp, 1)
				If IniReadW('lowMemUp', 4) = 4 Then _DebugOut('Replaced LF: ' & _ReplaceStringInFile($sLFTmp , @LF, @CRLF ) & @CRLF & 'Replaced CRCR: ' & _ReplaceStringInFile($sLFTmp , @CR & @CR, @CR))
				ToolTip('Uploading...')
				Local $hFile = FileReadToArray($sLFTmp)
				Local $iLRECL = 0
				For $i = 0 To UBound($hFile) -1
					If StringLen($hFile[$i]) > $iLRECL Then $iLRECL = StringLen($hFile[$i])
				Next
				$iCounter = $i
				If iniReadW('lRECL', 'auto') = 'auto' Then
					If $iLRECL > 251 Then
						_DebugOut('!! upload by FTP.exe, LRECL of local file=' & $iLRECL);~ $iLRECL += 4
						Local $hFile = _TempFile(@TempDir, '', '')
						FileOpen($hFile, 2)
						FileWriteLine($hFile, $sUser & @CRLF & $sPass & @CRLF & 'cd ..' & @CRLF & 'delete ' & $sRF & @CRLF & 'literal site lrecl=' & $iLRECL & @CRLF & 'literal site RECFM=FB' & @CRLF & 'put "' & $sLFTmp & '" "' & $sRF & '"' & @CRLF & 'quit')
						FileClose($hFile)
						RunWait(iniReadW('ftpexe', 'FTP.exe') &  ' -s:' & $hFile & ' ' & $sAddress, @ScriptDir, @SW_HIDE)
						$ok = FileDelete($hFile)
					Else
						$ok = _FTP_FilePut($hConn, $sLFTmp, $sRF, $FTP_TRANSFER_TYPE_ASCII);$FTP_TRANSFER_TYPE_BINARY;$FTP_TRANSFER_TYPE_ASCII
					EndIf
				Else
					_DebugOut('!! upload by FTP.exe, LRECL of local file=' & iniReadW('lRECL', 'auto'))
					If $iLRECL > iniReadW('lRECL', $iLRECL) Then
						$ok = errore('FTP annullato - il file da caricare contiene più dati del RECL specificato')
					Else
						$iLRECL = iniReadW('lRECL', $iLRECL)
						Local $hFile = _TempFile(@TempDir, '', ''), $sTmp = $sUser & @CRLF & $sPass & @CRLF & 'cd ..' & @CRLF & 'delete ' & $sRF & @CRLF & 'literal site lrecl=' & $iLRECL & @CRLF & 'literal site RECFM=' & iniReadW('rECFM', 'FB') & @CRLF & 'put "' & $sLFTmp & '" "' & $sRF & '"' & @CRLF & 'quit'
						FileOpen($hFile, 2)
						FileWriteLine($hFile, $sTmp)
						_DebugOut($sTmp)
						RunWait(iniReadW('ftpexe', 'FTP.exe') &  ' -s:' & $hFile & ' ' & $sAddress, @ScriptDir, @SW_HIDE)
						$ok = FileDelete($hFile)
					EndIf
				EndIf
			Case 'LIST'
				_FTP_DirSetCurrent($hConn, $sRF)
				$list = _FTP_ListToArrayEx($hConn, 2)
;~ 				_ArrayDisplay($list)
			Case 'INFO'
				$list = _FTP_FileGetSize ($hConn, $sRF)
;~ 				MsgBox(0,0, $var)
			EndSwitch
;~ 			Case 'CHECK'
;~ 				$ok = 1
			If $ok = 0 And $list = 0 Then
				errore('Errore nel trasferimento file' & @CRLF & '$verb=' & $verb & @CRLF & '$sLF=' & $sLF & @CRLF & '$sRF=' & $sRF)
			Else
				$ok = 1
			EndIf
		EndIf
	EndIf
	If $verb = 'LIST' Then $ok = $list
	If $verb = 'INFO' Then $ok = $list
	ToolTip('')
	_FTP_Close($hConn)
	_FTP_Close($hOpen)
	Return $ok
EndFunc
;
Func addSpacesToMember($oldName, $n)
	Local $string = ""
	Local $input  = $oldName
	Local $output = $oldName & '_'
	Local $hi = FileOpen($input)
	Local $ho = FileOpen($output, 2)
	Local $ctrl = "%-" & $n & "s"
	While True
		$string = FileReadLine($hi)
		If @error <> 0 Then ExitLoop
;~ 		ConsoleWrite(StringFormat($ctrl, $string) & @CRLF)
		FileWriteLine($ho, StringFormat($ctrl, StringReplace($string, Chr(0), " ", 0)))
	WEnd
	FileClose($hi)
	FileClose($ho)
	FileDelete($input)
	FileCopy($output, $input, 8)
;~ 	MsgBox(0,0,$output)
	Return $output
EndFunc

Func convMember($oldName)
	Local $array = StringSplit($oldName, '.')
	If IsArray($array) Then
		Local $newName = $array[1]
		For $i = 2 To $array[0] - 1
			$newName &= '.' & $array[$i]
		Next
		If $i > UBound($array) -1  Then Return $oldName
		$newName &= '(' & $array[$i] & ')'
		Return $newName
	EndIf
	Return $oldName
EndFunc

Func FTPStatusCallbackHandler($hInternet, $iContext, $iInternetStatus, $pStatusInformation, $iStatusInformationLength)
	#forceref $hInternet, $iContext
	If $iInternetStatus = $INTERNET_STATUS_REQUEST_SENT Or $iInternetStatus = $INTERNET_STATUS_RESPONSE_RECEIVED Then
		Local $iBytesRead, $tSize = DllStructCreate('dword')
		_WinAPI_ReadProcessMemory(_WinAPI_GetCurrentProcess(), $pStatusInformation, DllStructGetPtr($tSize), $iStatusInformationLength, $iBytesRead)
		_DebugOut(_FTP_DecodeInternetStatus($iInternetStatus) & ' | Size = ' & DllStructGetData($tSize, 1) & ' Bytes    Bytes read = ' & $iBytesRead)
	Else
		_DebugOut(_FTP_DecodeInternetStatus($iInternetStatus))
	EndIf
EndFunc

Func errore($string = 'Errore generico', $title = 'Errore', $code = 16, $form = $form_main)
	ToolTip('')
	_DebugOut($string)
	MsgBox($code, $title, $string, Default, $form)
	checkUP()
	Return 0
EndFunc

Func inputBoxWPRO($sPrompt, $sTable, $sParentForm = $form_main)
	_DebugOut('inputBoxWPRO created')
	#cs
		$form_input = GUICreate("sTitle", 337, 195, -1, -1, -1, BitOR($WS_EX_TOPMOST,$WS_EX_WINDOWEDGE))
		$Combo = GUICtrlCreateCombo("", 16, 136, 273, 25)
		GUICtrlCreateLabel("sPrompt", 16, 16, 300, 17)
		$buttonOK = GUICtrlCreateButton("OK", 17, 163, 75, 25)
		$buttonKO = GUICtrlCreateButton("Annulla", 246, 163, 75, 25)
		$buttonDel = GUICtrlCreateButton("X", 296, 135, 25, 23)
		$List1 = GUICtrlCreateList("", 16, 40, 153, 84)
	#ce
	GUISetState(@SW_DISABLE, $sParentForm)
	GUISetState(@SW_HIDE, $sParentForm)
	Global $form_input = GUICreate($sTitle, 336, 179, -1, -1, -1, 8), $bFocusPromptPro = False
	Local $Combo = GUICtrlCreateCombo('', 16, 104, 273, 25, 66), $sDataSet = ''
	GUICtrlCreateLabel($sPrompt, 16, 16, 300, 81)
	Local $buttonOK = GUICtrlCreateButton("&OK", 17, 139, 75, 25)
		HotKeySet("{enter}", "enterPressedPRO")
	Local $buttonKO = GUICtrlCreateButton("&Annulla", 246, 139, 75, 25)
	Local $buttonDel = GUICtrlCreateButton('X', 296, 103, 25, 23)
		GUICtrlSetTip(-1, "Cancella dalla cronologia", 'Info', 1, 1)
	refreshCombo($sTable, $Combo, $buttonDel)
	Opt('GUIOnEventMode', 0)
	GUISetState(@SW_SHOW, $form_input)
	GUISwitch($form_input)
	While $sDataSet = ''
		Switch GUIGetMsg()
			Case -3
				ExitLoop
			Case $buttonOK
				$sDataSet = GUICtrlRead($Combo)
			Case $buttonKO
				ExitLoop
			Case $buttonDel
				_SQLite_Exec($hDB, "DELETE FROM " & $sTable & " WHERE name='" & bonificaQ(GUICtrlRead($Combo)) & "';")
				refreshCombo($sTable, $Combo, $buttonDel)
		EndSwitch
		If $bFocusPromptPro Then $sDataSet = GUICtrlRead($Combo)
	WEnd
	HotKeySet("{enter}")
	Opt('GUIOnEventMode', 1)
	slcInsUpd($sDataSet, $sTable)
	GUISetState(@SW_ENABLE, $sParentForm)
	GUIDelete($form_input)
	GUISwitch($sParentForm)
	GUISetState(@SW_SHOW, $sParentForm)
	Return $sDataSet
EndFunc

Func bonificaQ($string)
	Return StringUpper(StringReplace(StringReplace(StringStripWS(StringStripCR($string), 3), "'", ''), '"', ''))
EndFunc

Func refreshCombo($sTable, $hCombo, $hButton = -1)
	GUICtrlSetData($hCombo, '')
	Local $sMsg = '', $sMsgE = ''
	_SQLite_Query($hDB, "SELECT name FROM " & $sTable & " ORDER BY tms_ult_var desc;", $hQuery)
	While _SQLite_FetchData($hQuery, $aRow) = $SQLITE_OK
		If $sMsg = '' Then $sMsg = $aRow[0]
		$sMsgE &= $aRow[0] & '|'
	WEnd
	GUICtrlSetData($hCombo, StringTrimRight($sMsgE, 1), $sMsg)
	If $hButton > 0 Then
		If GUICtrlRead($hCombo) = '' Then
			GUICtrlSetState($hButton, 128)
		Else
			GUICtrlSetState($hButton, 64)
		EndIf
	EndIf
EndFunc

Func slcInsUpd($sName, $sTable)
	If $sName <> '' Then
		$sName = bonificaQ($sName)
		_SQLite_Query($hDB, "SELECT name FROM " & $sTable & " WHERE name='" & $sName & "';", $hQuery)
		If _SQLite_FetchData($hQuery, $aRow) = $SQLITE_OK Then
			_SQLite_Exec($hDB, "UPDATE " & $sTable & " SET tms_ult_var=current_timestamp WHERE name='" & $sName & "';")
		Else
			_SQLite_Exec($hDB, "INSERT INTO " & $sTable & " (name,tms_ult_var) VALUES ('" & $sName & "',current_timestamp);")
		EndIf
	EndIf
EndFunc

Func enterPressedPRO()
	If ControlGetFocus($form_input) <> '' Then $bFocusPromptPro = True
	HotKeySet("{enter}")
	Send("{enter}")
	HotKeySet("{enter}", "enterPressedPRO")
EndFunc