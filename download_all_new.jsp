<%@ page trimDirectiveWhitespaces="true" %>
<%@ page language="java" import="java.io.*
,neo.smartui.report.EnvInfo
,neo.smartui.report.DataParameter
,neo.smartui.report.CrystalReportProcess
,neo.smartui.report.NEOExecInfo
,java.util.*
,javax.sql.RowSet
,java.sql.SQLException
,java.util.ArrayList
,java.util.List
,java.util.zip.ZipEntry
,java.util.zip.ZipOutputStream
,org.apache.commons.io.FilenameUtils
,custom.file.FileUtils
,custom.file.FileInfo
"%>
<%
     String token_ = "";
    
    try{
        token_ =    request.getParameter("dsmore");
    }catch (Exception e) {
        e.printStackTrace();
    }

	if (token_==null || token_.isEmpty())
	{
		token_="1"; 
	}
	//setUserVar("downloadToken", "yes"); 
	HttpSession session1 = request.getSession();	
	session1.setAttribute("downloadToken", "yes");
	
   javax.servlet.http.Cookie tk = new Cookie("downloadToken", token_);       
   // Set expiry date after 24 Hrs for both the cookies.
   tk.setMaxAge(60*60);      
   // Add both the cookies in the response header.
   response.addCookie( tk );   
   System.out.println("Cookie add OK: " + token_);
   
    //System.out.println("---------------HELLO------");
    EnvInfo _ei = new EnvInfo(request,session.getServletContext());
    if(_ei==null){
            out.println("Ban khong co quyen truy cap he thong!");
            return;
    }

    //kiem tra so lan query len web server, tranh bi tan cong DOS
    Long lastDateAccess = (Long) session.getAttribute("sysLastDateAccess");
    Integer hitCount = (Integer) session.getAttribute("sysHitCount");

    if ((lastDateAccess == null) || (hitCount == null)) { // ghi lai lan dau
            lastDateAccess = new Long(System.currentTimeMillis());
            hitCount = new Integer(1);
    } else {
            if ((System.currentTimeMillis() - lastDateAccess.longValue()) <
                    60000) { //trong vong 1 phut
                    if (hitCount.intValue() > 100) 
                    { 
                        //vuot qua so lan hit
                         System.out.println("-----vuot qua so lan hit");
                        return ;
                    } else {
                        hitCount = new Integer(hitCount.intValue() + 1);
                    }
            } else {
                    lastDateAccess = new Long(System.currentTimeMillis());
                    hitCount = new Integer(1);
            }
    }

    session.setAttribute("sysLastDateAccess", lastDateAccess);
    session.setAttribute("sysHitCount", hitCount);

    String sFuncSchema = _ei.sysConst("FuncSchema");
    String sDataSchema = _ei.userVar("sys_dataschema");
    String sUserIp = _ei.userVar("userIP");
    String userID=_ei.userVar("userID");
    String sys_ismobile=_ei.userVar("sys_ismobile");
    String fileUploadDir = _ei.sysConst("FileUploadDir").replace("\\", "/");
    String fn= "";
    if(userID==null){
        out.println("Ban khong co quyen truy cap he thong!");
        return;
    }

    // Get parameters
    CrystalReportProcess crp = new CrystalReportProcess(request);
    Map p = crp.getParameter(); 
    //cuongtm them
    String file_id = "";
    String ref_string = "";
    String docid = "";
    String flgzip = "";
    String is_attach = "";
    String a[];
    String b[];
    int i = 0;
    String type = ""; //EGOVHOTRO-6881: type = qll
    String flgzip_single = "1"; ////EGOVHOTRO-6881: ktra zip 1 file
    try
    {
        file_id = (String)p.get("dname");  //dname se luu file_id dname khi encode la : 5E1XCBS.=
		//EGOVHOTRO-7860
			if(file_id.indexOf("/")>-1||file_id.indexOf("\\")>-1){
			out.println("Ten file khong dung dinh dang!!!");
			return;
			}
        ref_string = (String)p.get("dpath");  //dpath khi encode la: 5FpXTEW.=
        //is_attach = (String)p.get("is_attach");  //dpath se luu cac thong so tham khao theo dang:
        docid = (String)p.get("docid");
        flgzip = (String)p.get("docid1");
        type = (String)p.get("type");
        flgzip_single = (String)p.get("zip_single");
        if (file_id==null || file_id.isEmpty())
        {
        	file_id="*";
        }
        if (ref_string==null || ref_string.isEmpty())
        {
        	ref_string="*";
        }
        if (flgzip==null || flgzip.isEmpty())
        {
        	flgzip="1";
        }
        if (type==null || type.isEmpty())
        {
            type="";
        }
        if (flgzip_single==null || flgzip_single.isEmpty()) {
            flgzip_single="1";
        }
    }catch (Exception e) {
    	flgzip="0";
        e.printStackTrace();
	}
    
    System.out.println("file_id ref_string is_attach = "+file_id+" * "+ref_string + " * " + docid + " * " + flgzip);
    //System.out.println("fileUploadDir = "+fileUploadDir);


    try {

            if (ref_string.indexOf("..") <= -1&&ref_string.startsWith(fileUploadDir)) 
            {  
                response.setContentType("application/zip" ) ;
                response.addHeader( "Content-Disposition", "attachment; filename=myzipfile.zip" ) ;
                
                fn=ref_string;                
                System.out.println("fn = "+fn);                
                ZipOutputStream outZip = new ZipOutputStream( response.getOutputStream() );

                InputStream in = null ;
                try
                {
                    // Add ZIP entry to output stream.
                    outZip.putNextEntry( new ZipEntry( file_id ) ) ;
                    in = FileUtils.getInputStream( fn ) ;
                    // Transfer bytes from the file to the ZIP file
                    byte[] buf = new byte[ 4096 ] ;
                    int len ;
                    while( ( len = in.read( buf ) ) > 0 )
                    {
                        outZip.write( buf, 0, len ) ;
                    }
                }
                catch( IOException ex ) { ex.printStackTrace(); }
                finally
                {
                    // Complete the entry
                    try{ outZip.closeEntry() ; } catch( IOException ex ) { }
                    try{ in.close() ; } catch( IOException ex ) { }
                }

                // flush the stream, and close it
                outZip.flush() ;
                outZip.close() ;

            } else if("qll".equals(type)) { // EGOVHOTRO-6881
                String sql = "begin ? := " + sFuncSchema+ "PK_QLL_DONVI_TONGHOP.get_event_file(?, ?, ?, ?); end;";
                NEOExecInfo nei = new NEOExecInfo(sql);
                nei.bindParameter(2, userID);
                nei.bindParameter(3, sUserIp);
                nei.bindParameter(4, sDataSchema);
                nei.bindParameter(5, docid);
                RowSet rowSet = null;
                try {
                    rowSet = DataParameter.getRSet(_ei, nei);
                } catch (Exception e) {
                    // TODO Auto-generated catch block
                    e.printStackTrace();
                }
                if (rowSet == null) {
                    response.setContentType("text/html"); 
                    out.println("Loi file hoac ban khong co quyen truy cap");
                    return;
                }
                String qllUploadDir = _ei.sysConst("UploadDir").replace("\\", "/");
                ArrayList paths = new ArrayList();
                try {
                    while (rowSet.next()) {
                        paths.add(qllUploadDir+rowSet.getString("filepath"));
                    }
                } catch (SQLException e) {
                    e.printStackTrace();
                } finally {
                    rowSet.close();
                }
                int totalFile = paths.size();
                if(totalFile == 0) {
                    response.setContentType("text/html"); 
                    out.println("Loi file hoac ban khong co quyen truy cap");
                    return;
                }
                
                if(totalFile > 1 || (totalFile == 1 && "1".equals(flgzip_single))) { // Zip
                    response.setContentType("application/zip" );
                    response.addHeader("Content-Disposition", "attachment; filename=" + file_id + ".zip");
                    ZipOutputStream outZip = new ZipOutputStream(response.getOutputStream());
                    InputStream in = null;
                    try{
                        for (String path : paths) {
                            String filename = FilenameUtils.getName(path);
                            outZip.putNextEntry(new ZipEntry(filename));
                            in = FileUtils.getInputStream(path);
                            byte[] buf = new byte[4096] ;
                            int len ;
                            while( ( len = in.read( buf ) ) > 0 ) {
                                outZip.write( buf, 0, len ) ;
                            }
                        }
                    } catch(IOException ex ) {
                        ex.printStackTrace();
                    } finally {
                        try { 
                            outZip.closeEntry();
                        } catch(IOException ex) {
                            ex.printStackTrace();
                        }
                        try{
                            in.close();
                        } catch(IOException ex){
                            ex.printStackTrace();
                        }
                    }
                    outZip.flush();
                    outZip.close();
                } else {
                    String path = paths.get(0);
                    String filename = FilenameUtils.getName(path);
                    response.setHeader("Content-Disposition","attachment; filename=\"" + filename +"\"");
                    response.setHeader("Content-Transfer-Encoding","binary");
                    response.setHeader("Keep-Alive","timeout=5, max=100");
                    response.setContentType("application/vnd.ms-word");
                    if(filename.contains(".doc")||filename.contains(".docx")) {
                       response.setContentType("application/vnd.ms-word");
                    } else if(filename.contains(".xls")||filename.contains(".xlsx")) {
                        response.setContentType("application/vnd.ms-excel");
                    } else if (filename.contains(".pdf")) {
                        response.setContentType("application/vnd.ms-pdf");
                    }
                    ServletOutputStream servletOutputStream = response.getOutputStream();
                    FileInfo file =FileUtils.getFileInfo(path);
                    if(!file.isExists()) {
                        response.setContentType("text/html"); 
                        out.println("Loi file hoac ban khong co quyen truy cap");
                        return;
                    }
                    InputStream is = FileUtils.getInputStream(path);
                    byte[] buffer = new byte[1024];
                    int readed=-1;
                    while((readed = is.read(buffer, 0,1024)) != -1) {
                        servletOutputStream.write(buffer, 0, readed);
                    }
                    is.close();
                }
            } else {
                String sql="";
                
                sql="begin ?:= "+sFuncSchema+"pk_van_ban_den.sf_get_file_attach_lst('"+userID+"','"+sUserIp
                                   +"','"+sDataSchema+"','"+docid+"'); end;";
                
                 //file_id, name, hdd_file, attachment_id, creator, is_deleted
                RowSet rs = DataParameter.getRSet(_ei,sql); 
                if (flgzip.contentEquals("1"))
            	{
            		//Zip lai de download ve
                    response.setContentType("application/zip" ) ;
                    response.addHeader("Content-Disposition", "attachment; filename=" + sql + ".zip") ;                                        
                    ZipOutputStream outZip = new ZipOutputStream( response.getOutputStream() );                                        
                    ArrayList obj = new ArrayList(); 
                    InputStream in = null ;
                    
                    try{
	                    while (rs.next()) {	                   		
	                   		String[] item = new String[2];
                                        if("1".equals(rs.getString("is_phieu_trinh"))){ //--EGOVHOTRO-7913
                                            continue;
                                        }
                            String sql1 = "";
                            sql1 = "select hdd_file from "+sDataSchema+"fem_file where id="+rs.getString("FILE_ID");                            
                            RowSet rs1 = DataParameter.getRSet(_ei,sql1);
                            if (rs1.next())
                            {
                                item[0] =rs1.getString("hdd_file");
                            }
	                   		//item[0] =rs.getString("hdd_file");
	      					item[1]=rs.getString("name");
	      					obj.add(item);	      						                        
	                    }
	                    rs.close();
	                    
	                    for (i = 0; i < obj.size(); i++) {
	      					//Add ZIP entry to output stream. 
	      					String[] item1 = new String[2];
	      					item1 = (String[])obj.get(i);
	                        outZip.putNextEntry( new ZipEntry( item1[1] )); //ten file
	                        in = FileUtils.getInputStream( item1[0] ) ; //duong dan
	                        //Transfer bytes from the file to the ZIP file
	                        byte[] buf = new byte[ 4096 ] ;
	                        int len ;
	                        while( ( len = in.read( buf ) ) > 0 )
	                        {
	                            outZip.write( buf, 0, len ) ;
	                        }	                    	
	                    }

                    }
                    catch( IOException ex ) { ex.printStackTrace(); }
                    finally
                    {
                        // Complete the entry
                        try{ outZip.closeEntry() ; } catch( IOException ex ) { }
                        try{ in.close() ; } catch( IOException ex ) { }
                    }
                                    
                   // flush the stream, and close it
                    outZip.flush() ;
                    outZip.close() ;                		
            		
            	}else
            	{
            		//Khong zip, download luon file ve            		
            		ServletOutputStream servletOutputStream = response.getOutputStream();
            		if(rs.next()) 
                    {

    					fn=rs.getString(3);
    					file_id=rs.getString(2); 
                        //response.setContentLength(rs.getInt(4));
                        response.setHeader("Content-Disposition","attachment; filename=\"" + file_id +"\"");
                        response.setHeader("Content-Transfer-Encoding","binary");
                        response.setHeader("Keep-Alive","timeout=5, max=100");
                        response.setContentType("application/vnd.ms-word");
                        if (file_id.contains(".doc")||file_id.contains(".docx"))
                        {
                                response.setContentType("application/vnd.ms-word");
                        }
                        if (file_id.contains(".xls")||file_id.contains(".xlsx"))
                        {
                                response.setContentType("application/vnd.ms-excel");
                        }		
                        if (file_id.contains(".pdf"))
                        {
                                response.setContentType("application/vnd.ms-pdf");
                        }						                
                        
                        if (fn !=null) 
                        {
                            InputStream is = FileUtils.getInputStream(fn);
                            byte[] buffer = new byte[1024];
                            int readed=-1;
                            while((readed = is.read(buffer, 0,1024)) != -1){
                                    servletOutputStream.write(buffer, 0, readed);
                            }
                        }                          

                    }  else {
                            response.setContentType("text/html"); 
                            out.println("Loi file hoac ban khong co quyen truy cap");
                    }
            		rs.close();
            		                		
            	}
                //if (flgzip.contentEquals("1"))                 	                
                
            }
    } catch (Exception e) {
        e.printStackTrace();
    }
    
%>