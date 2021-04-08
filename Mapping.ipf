#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and Strict wave access.

//	Mapping Version1.0  
//	Written by Junde Liu    [2021.04.07]             
//	Function: data mapping, including trans2k and rotation

Function Mapping()
	String plot_subfolder=Choose_subfolder()
	String absolute_path="root:"+plot_subfolder+":"
	String variable_path=absolute_path+"VariableFolder"+":"
	Wave data0=$(absolute_path+"data0")
	
	//参数的初始化		   			
	Nvar cutNum=$(variable_path+"cutNum")
	Variable start_data=1
	Variable end_data=41
	Variable start_angle=-20
	Variable delta_angle=1
	Variable mapping_Ecenter=16.78
				
	Prompt start_data,"Data Number from:"
	Prompt end_data,"Data Number to:"
	Prompt start_angle,"Start angle:"
	Prompt delta_angle,"Delta angle:"
	Prompt mapping_Ecenter,"Mapping energy Center:"
	DoPrompt/Help="" "Mapping Parameter",start_data,end_data,start_angle,delta_angle,mapping_Ecenter
	
	//在变量文件夹创建Mapping所需的全局变量
	Variable/G $(variable_path+"StartData")=start_data
	Variable/G $(variable_path+"EndData")=end_data
	Variable/G $(variable_path+"StartAngle")=start_angle
	Variable/G $(variable_path+"DeltaAngle")=delta_angle
	Variable/G $(variable_path+"MappingEcenter")=mapping_Ecenter
	Variable/G $(variable_path+"MappingErange")=0
	Variable/G $(variable_path+"MappingTilt")=0
	Variable/G $(variable_path+"MappingPolar")=0
	Variable/G $(variable_path+"MappingAzimuth")=0
	Variable/G $(variable_path+"WhetherInterp")=0
	Variable/G $(variable_path+"WhetherTransform")=0
	Variable/G $(variable_path+"WhetherOriginal")=1
			   
	//将需要mapping的数据拼成三维wave
	Wave start_wave=$(absolute_path+"data"+Num2Str(start_data))
	String Str_mapping3Dwave=absolute_path+"mapping3Dwave"
	Make/O/N=(DimSize(start_wave,0),DimSize(start_wave,1),(end_data-start_data+1)) $Str_mapping3Dwave
	Wave mapping3Dwave=$Str_mapping3Dwave
	SetScale/P x, DimOffset(start_wave,0),DimDelta(start_wave,0),"θ",mapping3Dwave
	SetScale/P y, DimOffset(start_wave,1),DimDelta(start_wave,1),"Kinetic Energy[eV]",mapping3Dwave
	SetScale/P z, start_angle,delta_angle,"φ",mapping3Dwave
	Variable index=0
	String Str_cutwave
	Do
		Str_cutwave=absolute_path+"data"+Num2Str(index+start_data)
		Wave cutwave=$Str_cutwave
		mapping3Dwave[][][index]=cutwave[p][q]
		index=index+1
	While(index<(end_data-start_data+1))
			   
	Mapping_face(absolute_path)
	Mapping_window(plot_subfolder)
			   
	
End

Function Mapping_window(plot_subfolder) //建立mapping窗口
	String plot_subfolder
	String absolute_path="root:"+plot_subfolder+":"
	String variable_path=absolute_path+"VariableFolder"+":"
	Wave mappingface=$(absolute_path+"mappingface")
	Nvar start_data=$(variable_path+"StartData")
	Wave start_wave=$(absolute_path+"data"+Num2Str(start_data))
	Nvar mapping_Erange=$(variable_path+"MappingErange")
	
	//创建mapping窗口
	String graph=plot_subfolder+"Mapping"
	Display /N=$graph/W=(250,60,800,700) 
	AppendImage/L=dataleft/B=databottom mappingface
	ModifyImage mappingface ctab= {*,*,Terrain,0}
	ModifyGraph lblPosMode=4 //以坐标轴为参考
	ModifyGraph lblPos(dataleft)=50,lblPos(databottom)=45
	ModifyGraph freePos(dataleft)={0.14,kwFraction}
	ModifyGraph freePos(databottom)={0.13,kwFraction} 
	ModifyGraph axisEnab(dataleft)={0.13,0.7}
	ModifyGraph axisEnab(databottom)={0.14,0.9}
	 
	//创建mappingface窗口的所有控件
	String Str_subfolderpath=variable_path+"Mapping_subfolder"
	String/G $Str_subfolderpath="Mapping Data @ "+plot_subfolder
	String currentsubfolder=plot_subfolder+"currentfolder"
	TitleBox $currentsubfolder,pos={180,23},fixedsize=0,font="系统字体",frame=0,fSize=18
	TitleBox $currentsubfolder,fStyle=1,variable=$Str_subfolderpath
	 
	String mapping_group=plot_subfolder+"Mapping_group"
	GroupBox $mapping_group,pos={81,65},size={400,103}
	GroupBox $mapping_group,font="系统字体",fSize=13,fStyle=1,labelBack=(61166,61166,61166)
    
	String Energy_center=plot_subfolder+"mapping_Ecenter"
	SetVariable $Energy_center,pos={109,79},size={170,75},proc=SetVarProc_mapping,title="Energy Center:"
	SetVariable $Energy_center,font="系统字体",fStyle=0,fSize=13
	SetVariable $Energy_center,limits={(DimOffset(start_wave,1)+mapping_Erange),(DimOffset(start_wave,1)+(DimSize(start_wave,1)-1)*DimDelta(start_wave,1)-mapping_Erange),DimDelta(start_wave,1)},value=$(variable_path+"MappingEcenter")
    
	String Energy_range=plot_subfolder+"mapping_Erange"
	SetVariable $Energy_range,pos={109,109},size={170,75},proc=SetVarProc_mapping,title="Energy Range: "
	SetVariable $Energy_range,font="系统字体",fStyle=0,fSize=13
	SetVariable $Energy_range,limits={0,((DimSize(start_wave,1)-1)*DimDelta(start_wave,1))/2,DimDelta(start_wave,1)},value=$(variable_path+"MappingErange")
	 
	String whether_transform=plot_subfolder+"transform"
	CheckBox $whether_transform,pos={110,139},size={62,10},title="K Space: "
	CheckBox $whether_transform,font="系统字体",fSize=13,fStyle=1,variable=$(variable_path+"WhetherTransform"),side= 1,proc=CheckProc_pack
	 
	String whether_original=plot_subfolder+"original"
	CheckBox $whether_original,pos={202,139},size={62,10},title="Original: "
	CheckBox $whether_original,font="系统字体",fSize=13,fStyle=1,variable=$(variable_path+"WhetherOriginal"),side= 1,proc=CheckProc_pack
	 
	String Str_shift_tilt=plot_subfolder+"tilt"
	SetVariable $Str_shift_tilt,pos={315,79},size={120,12.00},title="Δtilt : "
	SetVariable $Str_shift_tilt,font="系统字体",fSize=13,fStyle=1,value=$(variable_path+"MappingTilt"),proc=SetVarProc_shift_angle
	SetVariable $Str_shift_tilt,limits={-180,180,0.1}
	 
	String Str_shift_polar=plot_subfolder+"polar"
	SetVariable $Str_shift_polar,pos={315,109},size={120,12.00},title="Δpolar : "
	SetVariable $Str_shift_polar,font="系统字体",fSize=13,fStyle=1,value=$(variable_path+"MappingPolar"),proc=SetVarProc_shift_angle
	SetVariable $Str_shift_polar,limits={-180,180,0.1}
	 
	String Str_shift_azimuth=plot_subfolder+"azimuth"
	SetVariable $Str_shift_azimuth,pos={315,136},size={120,12.00},title="Δazimu : "
	SetVariable $Str_shift_azimuth,font="系统字体",fSize=13,fStyle=1,value=$(variable_path+"MappingAzimuth"),proc=SetVarProc_shift_angle
	SetVariable $Str_shift_azimuth,limits={-180,180,0.1} 
	 	 
End

Function Mapping_face(absolute_path) //根据当前参数更新mappingface(theta空间)
	String absolute_path
	String variable_path=absolute_path+"VariableFolder"+":"
	String plot_subfolder=ReplaceString("root:",absolute_path,"")
	
	Nvar start_data=$(variable_path+"StartData")
	Nvar end_data=$(variable_path+"EndData")
	Nvar start_angle=$(variable_path+"StartAngle")
	Nvar delta_angle=$(variable_path+"DeltaAngle")
	Nvar mapping_Ecenter=$(variable_path+"MappingEcenter")
	Nvar mapping_Erange=$(variable_path+"MappingErange")
		 
	Wave start_wave=$(absolute_path+"data"+Num2Str(start_data))
	Wave mapping3Dwave=$(absolute_path+"mapping3Dwave")
	 
	//生成二维mapping平面
	String Str_mappingface=absolute_path+"mappingface"  //确定路径
	Make/O/N=(DimSize(start_wave,0),(end_data-start_data+1)) $Str_mappingface //指定路径生成全局变量
	Wave mappingface=$Str_mappingface //全局变量引用，并赋予名字
	SetScale/P x, DimOffset(start_wave,0),DimDelta(start_wave,0),"θ",mappingface
	SetScale/P y, start_angle,delta_angle,"φ",mappingface
	Duplicate/O/Free/R=()((mapping_Ecenter-mapping_Erange),(mapping_Ecenter+mapping_Erange))() mapping3Dwave, bulk
	SumDimension/D=1/DEST=sumbulk bulk
	mappingface[][]=sumbulk[p][q]
	KillWaves/Z sumbulk
End

Function Mapping_K(win,absolute_path)
	String absolute_path
	String win
	String variable_path=absolute_path+"VariableFolder"+":"

	Nvar mapping_start_data=$(variable_path+"StartData")
	Nvar mapping_Ecenter=$(variable_path+"MappingEcenter")
	Nvar shift_tilt=$(variable_path+"MappingTilt")
	Nvar shift_polar=$(variable_path+"MappingPolar")
	Nvar shift_azimuth=$(variable_path+"MappingAzimuth")
    
	Wave mappingface=$(absolute_path+"mappingface")
	String image_name=ReplaceString(";",ImageNameList(win,";"),"")
	Wave start_wave=$(absolute_path+"data"+Num2Str(mapping_start_data))
    
	Variable n=0,m=0
	Variable theta,phi
    
	//theta_space --> K_space --> rotate_transform --> new_K_space --> new_theta_space
	//得到旋转变换后新的坐标范围
	Make/O/N=(4,4) corner
	corner[0][0]=DimOffSet(mappingface,0)//左下顶点
	corner[0][1]=DimOffSet(mappingface,1)
	corner[1][0]=DimOffSet(mappingface,0)+DimDelta(mappingface,0)*(DimSize(mappingface,0)-1)//右下
	corner[1][1]=DimOffSet(mappingface,1)
	corner[2][0]=DimOffSet(mappingface,0)+DimDelta(mappingface,0)*(DimSize(mappingface,0)-1)//右上
	corner[2][1]=DimOffSet(mappingface,1)+DimDelta(mappingface,1)*(DimSize(mappingface,1)-1)
	corner[3][0]=DimOffSet(mappingface,0)//左上
	corner[3][1]=DimOffSet(mappingface,1)+DimDelta(mappingface,1)*(DimSize(mappingface,1)-1)	
	Variable corner_point=0
	Do
		theta=corner[corner_point][0]*pi/180
		phi=corner[corner_point][1]*pi/180
		Make/Free/O/N=3 vector={cos(theta)*sin(phi),sin(theta),cos(theta)*cos(phi)}//单位矢量
		Transform_matrix(vector,shift_tilt,-shift_polar,shift_azimuth)
		corner[corner_point][2]=vector[0]
		corner[corner_point][3]=vector[1]
		corner_point=corner_point+1
	While(corner_point<4)
	Variable down_kx=min(corner[0][2],corner[1][2],corner[2][2],corner[3][2])
	Variable up_kx=max(corner[0][2],corner[1][2],corner[2][2],corner[3][2])
	Variable down_ky=min(corner[0][3],corner[1][3],corner[2][3],corner[3][3])
	Variable up_ky=max(corner[0][3],corner[1][3],corner[2][3],corner[3][3])
	KillWaves corner
	 
	Variable max_k=0.513*sqrt(mapping_Ecenter)
	String str_mappingface_k=absolute_path+"mappingface_k"
	Make/O/N=(max_k*(up_kx-down_kx)/0.005+40,max_k*(up_ky-down_ky)/0.005+40) $str_mappingface_k
	Wave mappingface_k=$str_mappingface_k
	SetScale/P x,(max_k*down_kx-0.1),0.005,"kx",mappingface_k
	SetScale/P y,(max_k*down_ky-0.1),0.005,"ky",mappingface_k
	Variable kx,ky	
	Do
		Do
			kx=DimOffset(mappingface_k,0)+n*DimDelta(mappingface_k,0)
			ky=DimOffset(mappingface_k,1)+m*DimDelta(mappingface_k,1)
			Make/Free/O/N=3 vector={kx,ky,sqrt(max_k^2-kx^2-ky^2)}
			Direct_antirotate_3axis(vector,shift_tilt/180*pi,shift_polar/180*pi,shift_azimuth/180*pi)
			kx=vector[0]/max_k
			ky=vector[1]/max_k
			theta=asin(ky)/pi*180
			phi=asin(kx/cos(asin(ky)))/pi*180
			If(numtype(Interp2D(mappingface,theta,phi))==0)
				mappingface_k[n][m]=Interp2D(mappingface,theta,phi)
			Else
				mappingface_k[n][m]=0
			EndIf	
			m=m+1
		While(m<DimSize(mappingface_k,1))
		m=0
		n=n+1
	While(n<DimSize(mappingface_k,0))
	MatrixTranspose mappingface_k//这一步是为了使得kx在图上为水平方向。因为计算的时候定义了polar方向为x方向
			
	ReplaceWave image=$image_name, mappingface_k
End

Function Mapping_Reorient(win,absolute_path)
	String absolute_path
	String win
	String variable_path=absolute_path+"VariableFolder"+":"
	    
	Nvar mapping_start_data=$(variable_path+"StartData")
	Nvar start_angle=$(variable_path+"StartAngle")
	Nvar delta_angle=$(variable_path+"DeltaAngle")
	Nvar mapping_Ecenter=$(variable_path+"MappingEcenter")
	Nvar shift_tilt=$(variable_path+"MappingTilt")
	Nvar shift_polar=$(variable_path+"MappingPolar")
	Nvar shift_azimuth=$(variable_path+"MappingAzimuth")
	Nvar whether_transform=$(variable_path+"WhetherTransform")
	
	Wave mappingface=$(absolute_path+"mappingface")
	Wave start_wave=$(absolute_path+"data"+Num2Str(mapping_start_data))
	String image_name=ReplaceString(";",ImageNameList(win,";"),"")
    
	Variable start_theta=DimOffset(start_wave,0)
	Variable delta_theta=DimDelta(start_wave,0)
	Variable n=0,m=0
	Variable theta,phi
    
	//theta_space --> K_space --> rotate_transform --> new_K_space --> new_theta_space
	//得到旋转变换后新的坐标范围
	Make/O/N=(4,4) corner
	corner[0][0]=DimOffSet(mappingface,0)//左下顶点
	corner[0][1]=DimOffSet(mappingface,1)
	corner[1][0]=DimOffSet(mappingface,0)+DimDelta(mappingface,0)*(DimSize(mappingface,0)-1)//右下
	corner[1][1]=DimOffSet(mappingface,1)
	corner[2][0]=DimOffSet(mappingface,0)+DimDelta(mappingface,0)*(DimSize(mappingface,0)-1)//右上
	corner[2][1]=DimOffSet(mappingface,1)+DimDelta(mappingface,1)*(DimSize(mappingface,1)-1)
	corner[3][0]=DimOffSet(mappingface,0)//左上
	corner[3][1]=DimOffSet(mappingface,1)+DimDelta(mappingface,1)*(DimSize(mappingface,1)-1)	
	Variable corner_point=0
	Do
		theta=corner[corner_point][0]*pi/180
		phi=corner[corner_point][1]*pi/180
		Make/Free/O/N=3 vector={cos(theta)*sin(phi),sin(theta),cos(theta)*cos(phi)}//单位矢量
		Transform_matrix(vector,shift_tilt,-shift_polar,shift_azimuth)
		corner[corner_point][2]=asin(vector[1])/pi*180 //new theta
		corner[corner_point][3]=asin(vector[0]/cos(asin(vector[1])))/pi*180 //new phi
		corner_point=corner_point+1
	While(corner_point<4)
	Variable down_theta=min(corner[0][2],corner[1][2],corner[2][2],corner[3][2])
	Variable up_theta=max(corner[0][2],corner[1][2],corner[2][2],corner[3][2])
	Variable down_phi=min(corner[0][3],corner[1][3],corner[2][3],corner[3][3])
	Variable up_phi=max(corner[0][3],corner[1][3],corner[2][3],corner[3][3])
	KillWaves corner
	 
	String g=absolute_path+"mappingface_reorient"
	Make/O/N=(Round(up_theta-down_theta+10)/0.3,Round(up_phi-down_phi+10)/0.3) $g=0
	Wave mappingface_reorient=$g
	SetScale/P x, (Round(down_theta)-5),0.3,"θ",mappingface_reorient
	SetScale/P y, (Round(down_phi)-5),0.3,"φ",mappingface_reorient			
	Do
		Do
			theta=(DimOffSet(mappingface_reorient,0)+n*0.3)/180*pi
			phi=(DimOffSet(mappingface_reorient,1)+m*0.3)/180*pi
			Make/Free/O/N=3 vector={cos(theta)*sin(phi),sin(theta),cos(theta)*cos(phi)}
			Direct_antirotate_3axis(vector,shift_tilt/180*pi,shift_polar/180*pi,shift_azimuth/180*pi)
			theta=asin(vector[1])/pi*180
			phi=asin(vector[0]/cos(asin(vector[1])))/pi*180
						
			If(numtype(Interp2D(mappingface,theta,phi))==0)
				mappingface_reorient[n][m]=Interp2D(mappingface,theta,phi)
			Else
				mappingface_reorient[n][m]=0
			EndIf		
			m=m+1
		While(m<DimSize(mappingface_reorient,1))
		m=0
		n=n+1
	While(n<DimSize(mappingface_reorient,0))	
			
	ReplaceWave image=$image_name, mappingface_reorient
End

Function Update_mappingface(win,absolute_path)
	String win
	String absolute_path
	String variable_path=absolute_path+"VariableFolder"+":"
    
	Wave mappingface=$(absolute_path+"mappingface")
	Nvar whether_transform=$(variable_path+"WhetherTransform")
	Nvar whether_original=$(variable_path+"WhetherOriginal")
    
	String image_name=ReplaceString(";",ImageNameList(win,";"),"")
	Switch(whether_original)		
		Case 0:
			Switch(whether_transform)
				case 0://不转化为k的情况
					Mapping_Reorient(win,absolute_path)
					break
				case 1:
					Mapping_K(win,absolute_path)
					break
			Endswitch
			break
		case 1:
			ReplaceWave image=$image_name, mappingface
			break		
	EndSwitch    
End

Function SetVarProc_mapping(sva) : SetVariableControl //返回更新的Ecenter到mappingInfo，并更新mappingface
	STRUCT WMSetVariableAction &sva
	Switch ( sva.eventCode )
		case 1: 
		case 2:
		case 3:
		case 6:
			Variable dval=sva.dval
			String sval=sva.sval
			String win=sva.win
			String absolute_path="root:"+ReplaceString("Mapping",win,"")+":"
			String variable_path=absolute_path+"VariableFolder"+":"
					
			Nvar start_data=$(variable_path+"StartData")
			Nvar end_data=$(variable_path+"EndData")
			Nvar start_angle=$(variable_path+"StartAngle")
			Nvar delta_angle=$(variable_path+"DeltaAngle")
			Nvar mapping_Ecenter=$(variable_path+"MappingEcenter")
			Nvar mapping_Erange=$(variable_path+"MappingErange")
			
			String Str_start_wave=absolute_path+"data"+Num2Str(start_data) 
			Wave start_wave=$Str_start_wave
			String plot_subfolder=ReplaceString("Mapping",win,"")
			String Energy_center=plot_subfolder+"mapping_Ecenter"
			SetVariable $Energy_center,limits={(DimOffset(start_wave,1)+mapping_Erange),(DimOffset(start_wave,1)+(DimSize(start_wave,1)-1)*DimDelta(start_wave,1)-mapping_Erange),DimDelta(start_wave,1)}	
			
			Mapping_face(absolute_path)
			Update_mappingface(win,absolute_path)
            
			break
		case -1:
			break
	EndSwitch
	return 0
End

Function CheckProc_pack(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba
	Switch( cba.eventCode )
		case 2: 
			Variable checked = cba.checked
			String win=cba.win
			String absolute_path="root:"+ReplaceString("Mapping",win,"")+":"
         
			Update_mappingface(win,absolute_path)
				
			break
		Case -1:
			break
	EndSwitch
	return 0
End

Function SetVarProc_shift_angle(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	switch( sva.eventCode )
		case 1: 
		case 2: 
		case 3: 
			Variable dval = sva.dval
			String sval = sva.sval
			String win=sva.win
			String absolute_path="root:"+ReplaceString("Mapping",win,"")+":"
			
			Update_mappingface(win,absolute_path)

			break
		case -1: // control being killed
			break
	endswitch
	return 0
End

ThreadSafe Function Transform_matrix(vector,shift_tilt,shift_polar,shift_azimuth)
	Wave vector
	Variable shift_tilt
	Variable shift_polar
	Variable shift_azimuth
    
	Make/O/N=(3,3) matrix_tilt
	Make/O/N=(3,3) matrix_polar
	Make/O/N=(3,3) matrix_azimuth
    
	matrix_tilt[0][0]=1
	matrix_tilt[0][1]=0
	matrix_tilt[0][2]=0
	matrix_tilt[1][0]=0
	matrix_tilt[1][1]=cos(shift_tilt/180*pi)
	matrix_tilt[1][2]=sin(shift_tilt/180*pi)
	matrix_tilt[2][0]=0
	matrix_tilt[2][1]=-sin(shift_tilt/180*pi)
	matrix_tilt[2][2]=cos(shift_tilt/180*pi)
	 
	matrix_polar[0][0]=cos(shift_polar/180*pi)
	matrix_polar[0][1]=0
	matrix_polar[0][2]=-sin(shift_polar/180*pi)
	matrix_polar[1][0]=0
	matrix_polar[1][1]=1
	matrix_polar[1][2]=0
	matrix_polar[2][0]=sin(shift_polar/180*pi)
	matrix_polar[2][1]=0
	matrix_polar[2][2]=cos(shift_polar/180*pi)
	 
	matrix_azimuth[0][0]=cos(shift_azimuth/180*pi)
	matrix_azimuth[0][1]=sin(shift_azimuth/180*pi)
	matrix_azimuth[0][2]=0
	matrix_azimuth[1][0]=-sin(shift_azimuth/180*pi)
	matrix_azimuth[1][1]=cos(shift_azimuth/180*pi)
	matrix_azimuth[1][2]=0
	matrix_azimuth[2][0]=0
	matrix_azimuth[2][1]=0
	matrix_azimuth[2][2]=1
	 
	MatrixMultiply matrix_azimuth,matrix_polar,matrix_tilt,vector
	Wave M_product
	vector=M_product
	 
	Killwaves M_product,matrix_tilt,matrix_polar,matrix_azimuth    
End

ThreadSafe Function Direct_antirotate_3axis(vector,shift_tilt,shift_polar,shift_azimuth)
	Wave vector
	Variable shift_tilt//绕x轴旋转角
	Variable shift_polar//绕y轴旋转角
	Variable shift_azimuth//绕z轴旋转角
	
	Variable kx=vector[0]
	Variable ky=vector[1]
	Variable kz=vector[2]
	
	vector[0]=kx*Cos(shift_azimuth)*Cos(shift_polar) - ky*Cos(shift_polar)*Sin(shift_azimuth)-kz*Sin(shift_polar)
	vector[1]=-kz*Cos(shift_polar)*Sin(shift_tilt) + kx*(Cos(shift_tilt)*Sin(shift_azimuth)-Cos(shift_azimuth)*Sin(shift_polar)*Sin(shift_tilt)) + ky*(Cos(shift_azimuth)*Cos(shift_tilt)+Sin(shift_azimuth)*Sin(shift_polar)*Sin(shift_tilt))
	vector[2]=kz*Cos(shift_polar)*Cos(shift_tilt) + ky*(-Cos(shift_tilt)*Sin(shift_azimuth)*Sin(shift_polar)+Cos(shift_azimuth)*Sin(shift_tilt)) + kx*(Cos(shift_azimuth)*Cos(shift_tilt)*Sin(shift_polar)+Sin(shift_azimuth)*Sin(shift_tilt))
End
    
	
	

				
            
