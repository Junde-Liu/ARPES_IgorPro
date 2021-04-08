#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

//	Plot_data Version1.0  
//	Written by Junde Liu    [2021.04.05]             
//	Function: data visualization, including data, EDC, MDC and DOS

Function/S Choose_subfolder()
	String subfolder_list=ReplaceString("\r",ReplaceString(",",ReplaceString(";",ReplaceString("FOLDERS:",dataFolderDir(1,root:),""),""),";"),"")
	Variable index=0
	Variable subfolder_index
	Prompt subfolder_index, "Please choose the data subfolder:", popup subfolder_list
	DoPrompt "Parameter", subfolder_index
	Return stringfromlist(subfolder_index-1, subfolder_list)
End

Function Plot_data()
	String plot_subfolder=Choose_subfolder()
	String absolute_path="root:"+plot_subfolder+":"
	String variable_path=absolute_path+"VariableFolder"+":"
	
	//在变量文件夹中创建Plot所需的全局变量
	Variable/G $(variable_path+"Dataindex")=0
	Variable/G $(variable_path+"EDCindex")=0
	Variable/G $(variable_path+"MDCindex")=0
	Variable/G $(variable_path+"EDCvalue")
	Variable/G $(variable_path+"MDCvalue")
	Variable/G $(variable_path+"LineNum")=1
	Variable/G $(variable_path+"SmoothNum")=0
	String/G $(variable_path+"subfolderpath")="Data @ "+plot_subfolder
	
	Wave data0=$(absolute_path+"data0")
	//产生DOS数据
	Make/O/N=(DimSize(data0,1)), $(absolute_path+"DOS")
	Wave DOS=$(absolute_path+"DOS")
	SumDimension/D=0/DEST=DOS data0
	SetScale/P x,DimOffset(data0,1),DimDelta(data0,1),"Kinetic Energy [eV]",DOS
	//产生EDC数据
	Make/O/N=(DimSize(data0,1)), $(absolute_path+"EDC")
	Wave EDC=$(absolute_path+"EDC")
	SetScale/P x,DimOffset(data0,1),DimDelta(data0,1),"Kinetic Energy [eV]",EDC
	EDC=data0[0][p]
	//产生MDC数据
	Make/O/N=(DimSize(data0,0)), $(absolute_path+"MDC")
	Wave MDC=$(absolute_path+"MDC")
	SetScale/P x,DimOffset(data0,0),DimDelta(data0,0),"Y-Scale [deg]",MDC
	MDC=data0[p][0]
	
	LJD_window(plot_subfolder)
End

Function LJD_window(plot_subfolder)
	String plot_subfolder
	String absolute_path="root:"+plot_subfolder+":"
	String variable_path=absolute_path+"VariableFolder"+":"
	
	//建立基于子文件夹绝对路径的变量引用
	Wave DOS=$(absolute_path+"DOS")
	Wave data0=$(absolute_path+"data0")
	Wave EDC=$(absolute_path+"EDC")
	Wave MDC=$(absolute_path+"MDC")
	Nvar cutNUm=$(variable_path+"cutNum")
	
	//创建window界面及其参数
	String win=plot_subfolder+"Window"
	Display/N=$win/W=(300,0,1210,725)/L=dosleft/B=dosbottom DOS
	AppendImage/L=dataleft/B=databottom data0
	AppendToGraph/L=edcleft/B=edcbottom EDC
	AppendToGraph/L=mdcleft/B=mdcbottom MDC
	
	ModifyImage data0 ctab={*,*,Terrain,0}
	ModifyGraph margin(left)=0,margin(bottom)=0,margin(top)=0,margin(right)=0
	
	//设置坐标轴标签相对坐标轴的相对位置
	ModifyGraph lblPosMode=4 //以坐标轴为参考
	ModifyGraph lblPos(dataleft)=70,lblPos(databottom)=53
	ModifyGraph lblPos(dosleft)=60,lblPos(dosbottom)=53
	ModifyGraph lblPos(edcleft)=60,lblPos(edcbottom)=53
	ModifyGraph lblPos(mdcleft)=60,lblPos(mdcbottom)=53
	
	//设置坐标轴在Graph中的位置
	ModifyGraph freePos(mdcleft)={0.17,kwFraction}
	ModifyGraph freePos(mdcbottom)={0,mdcleft}
	ModifyGraph freePos(dataleft)={0.17,kwFraction}
	ModifyGraph freePos(databottom)={0,dataleft} 
	ModifyGraph freePos(edcleft)={0.62,kwFraction}
	ModifyGraph freePos(edcbottom)={0,edcleft}
	ModifyGraph freePos(dosleft)={0.62,kwFraction}
	ModifyGraph freePos(dosbottom)={0,dosleft}
	
	//设置图像在Graph中的位置
	ModifyGraph axisEnab(mdcleft)={0.7,0.97}
	ModifyGraph axisEnab(mdcbottom)={0.17,0.45}
	ModifyGraph axisEnab(dataleft)={0.25,0.57}
	ModifyGraph axisEnab(databottom)={0.17,0.45}
	ModifyGraph axisEnab(edcleft)={0.69,0.97}
	ModifyGraph axisEnab(edcbottom)={0.62,0.9}
	ModifyGraph axisEnab(dosleft)={0.25,0.57}
	ModifyGraph axisEnab(dosbottom)={0.62,0.9}
	 
	//调整坐标轴字体大小
	ModifyGraph fSize(dosbottom)=13
	ModifyGraph fSize(edcbottom)=13
	ModifyGraph fSize(mdcbottom)=13 
	ModifyGraph fSize(databottom)=13
	ModifyGraph fSize(dosleft)=13
	ModifyGraph fSize(edcleft)=13
	ModifyGraph fSize(mdcleft)=13 
	ModifyGraph fSize(dataleft)=13  
	 
	//标签
	Label dosleft"COUNT"
	Label edcleft"COUNT"
	Label mdcleft"COUNT"
	
	//调用变量文件夹里的全局变量
	Nvar dataindex=$(variable_path+"Dataindex")
	Nvar edcindex=$(variable_path+"EDCindex")
	Nvar mdcindex=$(variable_path+"MDCindex")
	Nvar edcvalue=$(variable_path+"EDCvalue")
	Nvar mdcvalue=$(variable_path+"MDCvalue")
	Nvar linenum=$(variable_path+"LineNum")
	Nvar smoothnum=$(variable_path+"SmoothNum")
	Svar subfolderpath=$(variable_path+"subfolderpath")
	Wave currentdata=$(absolute_path+"data"+Num2Str(dataindex))
	
	//设置各种控件的显示 
	String currentsubfolder=plot_subfolder+"currentsubfolder"
	TitleBox $currentsubfolder,pos={12,12},size={116.40,10.20},font="系统字体",frame=0,fSize=15
	TitleBox $currentsubfolder,fStyle=1,variable=subfolderpath
	
	String group_display=plot_subfolder+"group_display"
	GroupBox $group_display,pos={74,624},size={760,70},title=""
	GroupBox $group_display,font="系统字体",fSize=13,fStyle=1,labelBack=(61166,61166,61166)
	
	String data=plot_subfolder+"dataindex"
	SetVariable $data,pos={102,636},size={100,20},proc=Dataindex_update,title="data: "
	SetVariable $data,font="系统字体",fStyle=0,fSize=13
	SetVariable $data,limits={0,cutNum-1,1},value=dataindex
	
	String dataplot_slider=plot_subfolder+"dataindex_slider"
	Slider $dataplot_slider,pos={101,667},size={100,16}
	Slider $dataplot_slider,limits={0,cutNum-1,1},variable=dataindex,vert=0,side=0
	
	String EDC_index=plot_subfolder+"EDC_index"
	edcvalue=DimOffset(currentdata,0)+DimDelta(currentdata,0)*edcindex
	SetVariable $EDC_index,pos={242,636},size={155,20},proc=EMDCindex_update,title="EDC: "
	SetVariable $EDC_index,font="系统字体",fStyle=0,fSize=13,format="%.4f Deg"
	SetVariable $EDC_index,limits={DimOffset(currentdata,0),DimOffset(currentdata,0)+DimDelta(currentdata,0)*DimSize(currentdata,0),DimDelta(currentdata,0)},value=edcvalue
	 
	String EDCindex_slider=plot_subfolder+"EDCindex_slider"
	Slider $EDCindex_slider,pos={167,295},size={250,16}
	Slider $EDCindex_slider,limits={DimOffset(currentdata,0),DimOffset(currentdata,0)+DimDelta(currentdata,0)*DimSize(currentdata,0),DimDelta(currentdata,0)}
	Slider $EDCindex_slider,variable=edcvalue,vert=0,side=0
	 
	String MDC_index=plot_subfolder+"MDC_index"
	mdcvalue=DimOffset(currentdata,1)+DimDelta(currentdata,1)*mdcindex
	SetVariable $MDC_index,pos={242,665},size={155,20},proc=EMDCindex_update,title="MDC: "
	SetVariable $MDC_index,font="系统字体",fStyle=0,fSize=13,format="%.4f   eV"
	SetVariable $MDC_index,limits={DimOffset(currentdata,1),DimOffset(currentdata,1)+DimDelta(currentdata,1)*DimSize(currentdata,1),DimDelta(currentdata,1)},value=mdcvalue
	 
	String MDCindex_slider=plot_subfolder+"MDCindex_slider"
	Slider $MDCindex_slider,pos={415,307},size={17,234}
	Slider $MDCindex_slider,limits={DimOffset(currentdata,1),DimOffset(currentdata,1)+DimDelta(currentdata,1)*DimSize(currentdata,1),DimDelta(currentdata,1)}
	Slider $MDCindex_slider,variable=mdcvalue,vert=1,side=0
	 
	String Str_linenum=plot_subfolder+"linenum"
	SetVariable $Str_linenum,pos={434,636},size={85,20},proc=Numpack_update,title="LINE: "
	SetVariable $Str_linenum,font="系统字体",fStyle=0,fSize=13
	SetVariable $Str_linenum,limits={1,300,2},value=linenum
	 
	String Str_smoothnum=plot_subfolder+"smoothnum"
	SetVariable $Str_smoothnum,pos={434,665},size={85,20},proc=Numpack_update,title="SMT: "
	SetVariable $Str_smoothnum,font="系统字体",fStyle=0,fSize=13
	SetVariable $Str_smoothnum,limits={0,300,2},value=smoothnum
	 
	TextBox/C/N=EDC/F=2/B=1/A=MT/Z=1/X=36.81/Y=3.15 "\\Zr070EDC\\s(EDC)"
	TextBox/C/N=MDC/F=2/B=1/A=MT/Z=1/X=-8.09/Y=3.15 "\\Zr070MDC\\s(MDC)"
	TextBox/C/N=DOS/F=2/B=1/A=MT/Z=1/X=36.81/Y=43.55 "\\Zr070DOS\\s(DOS)"
	 
	SetWindow $win,hook(move_cursor)=Move_cursor
	SetDrawlayer UserFront
		
End

Function Dataindex_update(sva) : SetVariableControl //根据data的变化更新数据
	StrUCT WMSetVariableAction &sva
	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
		case 6: // Value changed by dependency update
			Variable dval = sva.dval
			String win=sva.win
			String absolute_path="root:"+ReplaceString("Window",win,"")+":"
			String variable_path=absolute_path+"VariableFolder"+":"
			
			//替换当前的wave
			Wave currentdata=$(absolute_path+"data"+Num2Str(dval))
			ReplaceWave/W=$win image=$StringFromList(0,ImageNameList(win,";")),currentdata 
			
			//更新DOS曲线
			Make/O/N=(DimSize(currentdata,1)),$(absolute_path+"DOS")
			Wave DOS=$(absolute_path+"DOS")
			SetScale/P x,DimOffset(currentdata,1),DimDelta(currentdata,1),"Kinetic Energy [eV]",DOS 
			SumDimension/D=0/DEST=DOS currentdata
			ReplaceWave/W=$win trace=$StringFromList(0,TraceNameList(win,";",0)),DOS
			
			//更新edcvalue和mdcvalue
			Nvar edcindex=$(variable_path+"EDCindex")
			Nvar mdcindex=$(variable_path+"MDCindex")
			Nvar edcvalue=$(variable_path+"EDCvalue")
			Nvar mdcvalue=$(variable_path+"MDCvalue")
			edcvalue=DimOffset(currentdata,0)+DimDelta(currentdata,0)*edcindex
			mdcvalue=DimOffset(currentdata,1)+DimDelta(currentdata,1)*mdcindex
			
			UpdateEMDC(win)
			
			break
		case -1: // control being killed
			break
	endswitch
	return 0
End

Function EMDCindex_update(sva) : SetVariableControl
	StrUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
		case 6: // Value changed by dependency update
			Variable dval = sva.dval
			String win=sva.win
			String absolute_path="root:"+ReplaceString("window",win,"")+":"
			String variable_path=absolute_path+"VariableFolder"+":"
			
			Nvar dataindex=$(variable_path+"Dataindex")
			Nvar edcvalue=$(variable_path+"EDCvalue")
			Nvar mdcvalue=$(variable_path+"MDCvalue")
			Nvar edcindex=$(variable_path+"EDCindex")
			Nvar mdcindex=$(variable_path+"MDCindex")
			
			Wave currentdata=$(absolute_path+"data"+Num2Str(dataindex))
			mdcindex=(dval-DimOffset(currentdata,1))/DimDelta(currentdata,1)
			edcindex=round((dval-DimOffset(currentdata,0))/DimDelta(currentdata,0))
			 
			If(StringMatch(StringFromList(0,CsrInfo(A,win)),"*data*")==1)	
				Cursor/I/S=2/C=(0,0,0) A $CsrWave(A) edcvalue, mdcvalue//此处不是Image_Name的String，而是Image_Name的调用(Reference)
			EndIf
			
			UpdateEMDC(win)
			break
		case -1: // control being killed
			break
	endswitch
	return 0
End

Function Numpack_update(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
		case 6: // Value changed by dependency update
			Variable dval = sva.dval
			String win=sva.win
			
			UpdateEMDC(win)
			break
		case -1: // control being killed
			break
	endswitch
	return 0
End	

Function Move_cursor(s)
	Struct WMWinHookStruct &s
	Switch(s.eventCode)
		case 7://cursormoved
			Variable free=s.isFree
			If(free==0&&StringMatch(s.traceName,"data*")==1)
				String win=s.winName
				String absolute_path="root:"+ReplaceString("window",win,"")+":"
				String variable_path=absolute_path+"VariableFolder"+":"
				
				Nvar dataindex=$(variable_path+"Dataindex")
				Nvar edcindex=$(variable_path+"EDCindex")
				Nvar mdcindex=$(variable_path+"MDCindex")
				Nvar edcvalue=$(variable_path+"EDCvalue")
				Nvar mdcvalue=$(variable_path+"MDCvalue")
				Wave currentdata=$(absolute_path+"data"+Num2Str(dataindex))
						
				edcindex=s.pointNumber
				mdcindex=s.yPointNumber				
				
				edcvalue=DimOffset(currentdata,0)+DimDelta(currentdata,0)*edcindex
				mdcvalue=DimOffset(currentdata,1)+DimDelta(currentdata,1)*mdcindex
				
				UpdateEMDC(win)
			EndIf
			Break
	EndSwitch
End

Function UpdateEMDC(win) //更新EDC和MDC曲线
	String win
	String absolute_path="root:"+ReplaceString("Window",win,"")+":"
	String variable_path=absolute_path+"VariableFolder"+":"
	String plot_subfolder=ReplaceString("Window",win,"")
   
	Nvar dataindex=$(variable_path+"Dataindex")
	Nvar edcindex=$(variable_path+"EDCindex")
	Nvar mdcindex=$(variable_path+"MDCindex")
	Nvar linenum=$(variable_path+"LineNum")
	Nvar smoothnum=$(variable_path+"SmoothNum")
	Wave currentdata=$(absolute_path+"data"+Num2Str(dataindex))

	//创建Wave储存新的EDC和MDC
	Make/O/N=(DimSize(currentdata,1)),$(absolute_path+"EDC")
	Wave EDC=$(absolute_path+"EDC")
	SetScale/P x,DimOffset(currentdata,1),DimDelta(currentdata,1),"Kinetic Energy [eV]",EDC
	Make/O/N=(DimSize(currentdata,0)),$(absolute_path+"MDC")
	Wave MDC=$(absolute_path+"MDC")
	SetScale/P x,DimOffset(currentdata,0),DimDelta(currentdata,0),"Y-Scale [deg]",MDC
	
	//根据linenum更新
	Duplicate/Free/O/RMD=[edcindex-(linenum-1)/2,edcindex+(linenum-1)/2][] currentdata,block
	SumDimension/D=0/DEST=EDC block
	MatrixOp/O EDC=EDC/linenum
	Duplicate/Free/O/RMD=[][mdcindex-(linenum-1)/2,mdcindex+(linenum-1)/2] currentdata,block
	SumDimension/D=1/DEST=MDC block
	MatrixOp/O MDC=MDC/linenum
	
	//根据smoothnum更新
	If(smoothnum!=0)
		Smooth/F=1 smoothnum,EDC
		Smooth/F=1 smoothnum,MDC
	EndIf
	
	ReplaceWave/W=$win trace=EDC,EDC
	ReplaceWave/W=$win trace=MDC,MDC
	
	//根据当前的data更新EDC_index和MDC_index的范围
	String EDC_index=plot_subfolder+"EDC_index"
	SetVariable $EDC_index,limits={DimOffset(currentdata,0),DimOffset(currentdata,0)+DimDelta(currentdata,0)*DimSize(currentdata,0),DimDelta(currentdata,0)}
	String MDC_index=plot_subfolder+"MDC_index"
	SetVariable $MDC_index,limits={DimOffset(currentdata,1),DimOffset(currentdata,1)+DimDelta(currentdata,1)*DimSize(currentdata,1),DimDelta(currentdata,1)}
	String EDCindex_slider=plot_subfolder+"EDCindex_slider"
	Slider $EDCindex_slider,limits={DimOffset(currentdata,0),DimOffset(currentdata,0)+DimDelta(currentdata,0)*DimSize(currentdata,0),DimDelta(currentdata,0)}
	String MDCindex_slider=plot_subfolder+"MDCindex_slider"
	Slider $MDCindex_slider,limits={DimOffset(currentdata,1),DimOffset(currentdata,1)+DimDelta(currentdata,1)*DimSize(currentdata,1),DimDelta(currentdata,1)}
	 
End