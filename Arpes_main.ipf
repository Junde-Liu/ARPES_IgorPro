#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

//	Arpes_main Version1.0  
//	Written by Junde Liu    [2021.04.05]             
//	Function: The main control of the program which set the menu          

Menu "ARPES", dynamic
	"Initialize", Initialize()
	"Load data", Load_data()
	"Plot data", Plot_data()
	"Mapping", Mapping()
	"hv mapping", hv_mapping()
	"Mapping helper", mapping_helper()
	"Discrete EMDC", Dis_EMDC()
	"Symmetrical EDC", Sym_EDC()
	"BZ simplified", BZ_simplified()
	"Color Scale", Color_scale()
End

Function Initialize()
	DoAlert/T="Caution", 2, "Warning: Are you sure you want to initialize? This operation will clear all the data."
	If(V_flag==1)
		KillDatafolder root:
		Print "Successfully initialized"
	Else
		Print "Operation cancelled"
	EndIf
End







	
	