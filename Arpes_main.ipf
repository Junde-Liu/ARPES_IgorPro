#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

//	ARPES_IgorPro V1.0 [2021.04.04]      
//	Written by Junde Liu         
//	Function: ARPES data loading, plotting, processing and fitting.             

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

Function Load_data()
	Variable data_format
	String data_folder
	Prompt data_format, "Please choose the data format:", popup ".pxt;.bin"
	Prompt data_folder, "Create a data folder:"
	DoPrompt "Load Data", data_format, data_folder
	If(V_flag==0)
		//输入的文件夹名字不能为空，不能以数字开头
		If(StrLen(data_folder)!=0 && NumType(Str2Num(data_folder[0]))!=0 )
			NewDataFolder root:$data_folder
			String variable_folder="root:"+data_folder+":VariableFolder"
			NewDataFolder $variable_folder
			SetDataFolder root:$data_folder
			Switch(data_format)
				Case 1:
					Load_pxt()
					Print "Data loading complete. File format: .pxt"
					Break
				Case 2:
					Load_bin()
					Print "Data loading complete. File format: .bin"
					Break
			EndSwitch
		Else
			Print "Invalid name for the data folder."
		EndIf
	Else
		Print "Operation cancelled"
	EndIf		
End

Function Load_pxt()
	//储存文件夹中cut的数量
	Variable/G :VariableFolder:cutNum
	Nvar cutNum=:VariableFolder:cutNum
	
	NewPath/O tempPath
	cutNum=ItemsInList(IndexedFile(tempPath, -1, ".pxt"))
	If(cutNum==0)
		DoAlert/T="Caution", 0, "Warning: No file found."
		String subfolder_name=GetDataFolder(1)
		KillDataFolder subfolder_name
	EndIf
	
	String filename_list
	String file_name
	String wave_path
	Variable n
	filename_list=IndexedFile(tempPath, -1, ".pxt")
	filename_list=Sortlist(filename_list, ";", 16)
	Make/O/N=(cutNum, 4) cutScale
	For(n=0;n<cutNum;n+=1)
		file_name=StringFromList(n, filename_list, ";")
		LoadData/T/O/L=1/P=tempPath/Q file_name
		//若文件以数字开头或者含有特殊字符，路径表达方式增加一个单引号
		If(NumType(Str2Num(file_name[0]))==0)
			wave_path=":"+"'"+GetIndexedObjName(":",4,1)+"'"
		ElseIf( StringMatch(file_name,"*#*")==1 )
	       	wave_path=":"+"'"+GetIndexedObjName(":",4,1)+"'"
	       ElseIf( StringMatch(file_name,"*.*")==1 )
	       	wave_path=":"+"'"+GetIndexedObjName(":",4,1)+"'"
	       Else
	       	wave_path=":"+GetIndexedObjName(":",4,1)
	       EndIf
		String Str_folder=wave_path
		wave_path=wave_path+":"+GetIndexedObjName(wave_path, 1, 0)
		String new_wave="data"+Num2Str(n)
		Duplicate/O $wave_path, $new_wave
		cutScale[n][0]=DimOffset($wave_path,0)
		cutScale[n][1]=DimDelta($wave_path, 0)
		cutScale[n][2]=DimSize($wave_path, 0)
		cutScale[n][3]=DimSize($wave_path, 1)
		KillDataFolder/Z $Str_folder
	EndFor
End

Function Load_bin()	
	Variable refNum=0	//用于标记打开的文件，可以传递给其他需要索引该文件的函数
	NewPath /O DA30_path
	open /R /Z=1 /P=DA30_path refNum as "viewer.ini"
	//逐行读取viewer.ini文件的数据，以list的格式存储于stringlist_viewer
	String/G stringlist_viewer
	String string_viewer
	Variable stringlenth=1
	Do
		FReadLine refNum,string_viewer
		stringlenth=StrLen(string_viewer)
		stringlist_viewer=stringlist_viewer+string_viewer+";"
	While(stringlenth!=0)
	Close refNum	
	//建立相关的wave来存储信息
	Make/O/N=9 DA30_viewerInfo//width是平行于slit方向，depth是mapping方向，height是能量方向
	DA30_viewerInfo[0]=Str2Num(ReplaceString("depth_offset=",StringFromList(21,stringlist_viewer),""))
	DA30_viewerInfo[1]=Str2Num(ReplaceString("depth_delta=",StringFromList(22,stringlist_viewer),""))
	DA30_viewerInfo[2]=Str2Num(ReplaceString("width_offset=",StringFromList(15,stringlist_viewer),""))
	DA30_viewerInfo[3]=Str2Num(ReplaceString("width_delta=",StringFromList(16,stringlist_viewer),""))
	DA30_viewerInfo[4]=Str2Num(ReplaceString("height_offset=",StringFromList(18,stringlist_viewer),""))
	DA30_viewerInfo[5]=Str2Num(ReplaceString("height_delta=",StringFromList(19,stringlist_viewer),""))
	DA30_viewerInfo[6]=Str2Num(ReplaceString("depth=",StringFromList(12,stringlist_viewer),""))
	DA30_viewerInfo[7]=Str2Num(ReplaceString("width=",StringFromList(10,stringlist_viewer),""))
	DA30_viewerInfo[8]=Str2Num(ReplaceString("height=",StringFromList(11,stringlist_viewer),""))	
	//打开数据文件，导入数据
	Variable binRef
	String datafile=ReplaceString("\r",ReplaceString("path=",StringFromList(14,stringlist_viewer),""),"")
	open /R /Z=1 /P=DA30_path binRef as datafile	
	Variable depth=DA30_viewerInfo[6],width=DA30_viewerInfo[7],height=DA30_viewerInfo[8]
	Make/O/N=(width,height,depth) data_3D	
	Variable i=0,j=0,k=0,ii=0,jj=0,kk=0
	Make/Free/O/N=(width,height) currentPlane
	For (k=0;k<depth;k+=1)//以下过程为DA30的数据编码和解码过程
		FBinRead binRef,currentPlane 
		data_3D[][][k]=currentPlane[p][q]
	Endfor	
	Close binRef	
	//对导入的数据进行scale
	SetScale/P x,DA30_viewerInfo[2],DA30_viewerInfo[3],"Kinetic Energy[eV]",data_3D
	SetScale/P y,DA30_viewerInfo[4],DA30_viewerInfo[5],"theta",data_3D
	SetScale/P z,DA30_viewerInfo[0],DA30_viewerInfo[1],"phi",data_3D	
	//建立全局变量储存cut的数目
	Variable/G :VariableFolder:cutNum=depth
	//配合统一kz的数据格式，此处无意义
	Make/O/N=(depth,4) cutScale
	cutScale[][0]=DimOffset(data_3D,0)
	cutScale[][1]=DimDelta(data_3D,0)
	cutScale[][2]=DimSize(data_3D,0)
	cutScale[][3]=DimSize(data_3D,1)
	
	Variable n
	For(n=0;n<DimSize(data_3D,2);n+=1)
		String Str_waveindex="data"+num2Str(n)
		Duplicate/O/RMD=[][][n] data_3D, $Str_waveindex
		Redimension/N=(-1,-1) $Str_waveindex
   EndFor
End



	
	