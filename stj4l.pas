{$I-}
uses Unix;
var dir,dir_scr,init_s,notice:string;
procedure init_output;
  begin
    shell('clear');
    writeln(' -----------------------------------------------------');
    writeln('|           Linux下的评测系统 Sk-T (STJ4L)            |');
    writeln(' ---------------------------------------02/11/2012----');
    writeln('当前路径： '+dir_scr); writeln('状态： '+notice+'.');
    writeln;
    writeln('你要做什么？');
    writeln;
  end;
function exist(s:string):boolean;
  var ff:text;
  begin
    assign(ff,s); reset(ff);
    exit(ioresult=0);
  end;
procedure cmp(std,oup:string);
  var err:text;
  begin
    shell('diff -a -Z '+std+' '+oup+' > /tmp/log.txt');
    assign(err,'/tmp/log.txt'); reset(err);
    if eof(err) then shell('echo -n -e "\033[1;32;40m测试通过          \033[0;0;0m"')
    else shell('echo -n -e "\033[1;31;40m错误答案          \033[0;0;0m"');
    close(err);
  end;
procedure print(s:string);
  begin
    shell('echo -n -e "\033[1;31;40m'+s+'\033[0;0;0m"');
  end;
procedure start_judge(single:boolean);
  var
    tot,t:real;
    conf,err,tm:text;
    name,data_dir,ch,tm_s:string;
    test,times,i,caseb,casee,errnumber:longint;
  begin
    //获取配置文件
    if (not single)and(not exist(dir_scr+'/config.txt')) then begin
      writeln('未找到配置文件。');
    end else begin
    if not single then begin assign(conf,dir_scr+'/config.txt'); reset(conf); end;
    writeln('载入配置文件完成，开始评测……');
    shell('mkdir '+dir_scr+'/.tmp > /dev/null');
    //读入题目数量
    if single then test:=1 else readln(conf,test);
    for times:=1 to test do begin
      tot:=0; t:=0;
      //读入题目名称
      if single then begin
	 writeln('请输入题目名称：(输入B返回)');
	 shell('ls '+dir_scr+'/data --color=auto');
	 readln(name);
	 if upcase(name)='B' then exit;
      end else readln(conf,name);
      writeln('-------------------------');
      writeln('题目',times:2,' 名称： ',name);
      //获取选手程序
      data_dir:=dir_scr+'/data/'+name;
      if not exist(dir_scr+'/src/'+name+'.pas') then begin
        writeln('找不到程序。'); readln(conf); continue;
      end;
      shell('cp '+dir_scr+'/src/'+name+'.pas '+dir_scr+'/.tmp > /dev/null');
      //编译程序
      writeln('正在编译……');
      shell('fpc '+dir_scr+'/.tmp/'+name+'.pas > /dev/null');
      //判断编译错误
      if not exist(dir_scr+'/.tmp/'+name) then begin
        print('编译失败。'); writeln; readln(conf); continue;
      end;
      writeln('编译通过，正在运行……');
      //读入测试点个数
      if single then begin
        writeln('请输入测试点编号的起止数字：');
        readln(caseb,casee);
      end else readln(conf,caseb,casee);
      for i:=caseb to casee do begin
        str(i,ch);
        write('测试点 ',i-caseb+1:2,' ('+name+ch+'.in'+')','： ');
        if not exist(data_dir+'/'+name+ch+'.in') then begin
          writeln('找不到测试数据'); continue;
        end;
        //获取输入数据
        shell('cp '+data_dir+'/'+name+ch+'.in '+dir_scr+'/.tmp'+' > /dev/null');
        shell('mv '+dir_scr+'/.tmp/'+name+ch+'.in '+dir_scr+'/.tmp/'+name+'.in'+' > /dev/null');
        //运行程序
        shell('cd '+dir_scr+'/.tmp ; (time(((timeout 1 ./'+name+') > /dev/null) ; echo $? > /tmp/log.txt)) 2> /tmp/tm.txt');
        //获取程序错误
        assign(err,'/tmp/log.txt'); reset(err);
        readln(err,errnumber);
        case errnumber of
            0:errnumber:=0;
            2:print('无输出');
          124:print('超过时间限制');
          200:print('运算被0除');
          202:print('堆栈溢出');
          215:print('算数溢出');
          216:print('存取非法');
          else begin str(errnumber:3,tm_s); print('运行时错误'+tm_s); end;
        end;
        if errnumber<>0 then begin
          close(err); writeln; continue;
        end;
        close(err);
        //与标准输出比较
        shell('cp '+data_dir+'/'+name+ch+'.out '+dir_scr+'/.tmp'+' > /dev/null');
        cmp(dir_scr+'/.tmp/'+name+ch+'.out',dir_scr+'/.tmp/'+name+'.out');
        shell('rm '+dir_scr+'/.tmp/'+name+'.in'+' > /dev/null');
        shell('rm '+dir_scr+'/.tmp/'+name+'.out'+' > /dev/null');
        shell('rm '+dir_scr+'/.tmp/'+name+ch+'.out'+' > /dev/null');
        //获取运行时间
        assign(tm,'/tmp/tm.txt'); reset(tm);
        readln(tm); readln(tm,tm_s);
        tm_s:=copy(tm_s,pos('m',tm_s)+1,255);
        val(copy(tm_s,1,length(tm_s)-1),t); tot:=tot+t;
        insert(' ',tm_s,length(tm_s));
        writeln(' ',tm_s);
        close(tm);
      end;
      writeln('总共用时： ',tot:0:3,' 秒。');
    end;
    if not single then close(conf);
    //删除临时文件
    shell('rm -R '+dir_scr+'/.tmp > /dev/null');
    shell('rm /tmp/log.txt > /dev/null');
    shell('rm /tmp/tm.txt > /dev/null');
    end;
    writeln('------------------------------');
    writeln('评测完成，按回车键返回。');
    notice:='评测结束';
    readln;
  end;
procedure exchange_data;
  var init_s,data_dir:string;
  begin
    repeat
      init_output;
      writeln('你要修改哪个题目的数据？(输入B返回)');
      shell('ls '+dir_scr+'/data '+'--color=auto');
      readln(init_s);
      if upcase(init_s)='B' then exit;
      data_dir:=dir_scr+'/data/'+init_s;
      writeln('你要修改第几个数据？(输入B返回)');
      shell('ls '+data_dir+'/ --color=auto');
      readln(init_s);
      if upcase(init_s)='B' then exit;
      shell('emacs -nw '+data_dir+'/'+init_s+' > /dev/null');
      notice:='数据 '+init_s+' 修改完成';
    until false;
  end;
procedure edit_pas;
  var init_s,data_dir:string;
  begin
    repeat
      init_output;
      writeln('你要修改哪个程序？(输入B返回)');
      shell('ls '+dir_scr+'/data '+'--color=auto');
      readln(init_s);
      if upcase(init_s)='B' then exit;
      data_dir:=dir_scr+'/src/'+init_s+'.pas';
      shell('emacs -nw '+data_dir+' > /dev/null');
      notice:='程序 '+init_s+'.pas 修改完成';
    until false;
  end;
procedure in_contest;
  var init_s:string;
  begin
    repeat
      init_output;
      writeln('J:开始评测    C:配置数据    B:浏览文件夹    R:重新打开');
      writeln('E:修改数据    P:修改程序    S:单题评测');
      readln(init_s);
      if upcase(init_s)='J' then start_judge(false);
      if upcase(init_s)='B' then shell('dolphin '+dir_scr+' > /dev/null');
      if upcase(init_s)='C' then shell('emacs -nw '+dir_scr+'/config.txt > /dev/null');
      if upcase(init_s)='R' then exit;
      if upcase(init_s)='E' then exchange_data;
      if upcase(init_s)='P' then edit_pas;
      if upcase(init_s)='S' then start_judge(true);
    until false;
  end;
procedure open_contest;
  var init_s:string;
  begin
    repeat
      //init_output;
      writeln('请输入路径，或输入B返回主菜单:');
      readln(dir);
      if upcase(dir)='B' then exit;
      if dir[length(dir)]='/' then delete(dir,length(dir),1);
      dir_scr:=dir;
      notice:='竞赛已打开';
      in_contest;
    until false;
  end;
procedure new_contest;
  var init_s:string;
  begin
    //init_output;
    writeln('请输入路径，或输入B返回主菜单：');
    readln(dir);
    if upcase(dir)='B' then exit;
    if dir[length(dir)]='/' then delete(dir,length(dir),1);
    writeln('请输入竞赛名称，或输入B取消操作：');
    readln(init_s);
    if upcase(init_s)='B' then exit;
    dir:=dir+'/'+init_s; dir_scr:=dir;
    shell('mkdir '+dir+' > /dev/null');
    shell('mkdir '+dir+'/data'+' > /dev/null');
    shell('mkdir '+dir+'/src'+' > /dev/null');
    notice:='竞赛已建立';
  end;
begin
  notice:='已就绪'; dir:='/'; dir_scr:=dir;
  repeat
    init_output;
    writeln('N:新建竞赛    O:打开竞赛    E:退出程序');
    readln(init_s);
    if upcase(init_s)='N' then new_contest;
    if upcase(init_s)='O' then open_contest;
    if upcase(init_s)='E' then halt;
  until false;
end.
