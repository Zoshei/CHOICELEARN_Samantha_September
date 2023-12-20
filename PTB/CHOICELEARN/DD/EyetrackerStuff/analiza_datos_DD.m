function [todo a]=analiza_datos_DD(EyeDataFilename)%run dit met naam van bestand asc ipv archivo

% Take ascii file as input //what is ascii??

if ~exist(EyeDataFilename,'file')
    disp('Error: does not exist.')
    return
end

disp(['file for analysis: ' EyeDataFilename])

modo=modo_eyelink(EyeDataFilename);
disp(['Modo: ' modo]);

ojo=busca_ojo(EyeDataFilename);%eye = eye_tracker(naamfile)(hoe kan dit?? want hij moet toch naar niet spaanse file refereren??
disp(['Eye tracked: ' ojo]);

srate=busca_samplingrate(EyeDataFilename);
disp(['Sampling Rate: ' num2str(srate)]);
  
%busca los textos "SAMPLES\tGAZE" o "EVENTS\tGAZE" o "SYNCTIME" en el asc para ver desde donde empezar
%->>>
%search for the text "SAMPLES\tGaze", "EVENTS\tGAZE" or "SYNCTIME" in order to show asc when to start 


[linea]=busca_texto_en_archivo(EyeDataFilename, {'SAMPLES	GAZE' 'EVENTS	GAZE' 'SYNCTIME'},1000); %zoek naar tekst in bestand
if isempty(linea)
    disp('Llegué a EOF y no encontré ningún texto!!')
    disp('Pongo Startline: 200')
    S=200;
else
    S=linea+5;
    disp(['Start line: ' num2str(S)])
end


%abre el archivo llamado filename y mete todas las lineas de texto en la celda C
%->>>>
%open the file with filename y and put all the lines of the text in cell C 

filename=EyeDataFilename;
fid = fopen(filename);
% S=70; % La linea del  *.asc desde la que empieza a convertir a strings.
C = textscan(fid, '%s','HeaderLines',S,'delimiter', '\n');
fclose(fid);
a=C{1};
clear C;

%busca samples
%->>
%search for samples


todo.samples=busca_samples(a,modo);%necesita saber si es monoc, binoc o remoto ->>> you havo to know wheather it is monoc, binoc or remote 

%busca eventos de cada tipo->> search for events from every type 

todo.resac=busca_eventos(a,'ESACC R');
todo.lesac=busca_eventos(a,'ESACC L');
todo.refix=busca_eventos(a,'EFIX R');
todo.lefix=busca_eventos(a,'EFIX L');
todo.rebli=busca_eventos(a,'EBLINK R');
todo.lebli=busca_eventos(a,'EBLINK L');
[todo.msgtime todo.msgline]=busca_eventos(a,'MSG');
todo.msg=a(todo.msgline);   
todo.driftcorrect=busca_driftcorrect(EyeDataFilename);
todo.modo=modo;
todo.ojo=ojo;
todo.srate=srate;

todo.headerlines=S;

% disp ' '
% disp 'podriamos hacer un campo mas con todo.msgsample, la linea de la matriz'
% disp ' de samples en la que aparece cada mensaje, para ahorrar un monton de find...'
% disp ' tipo: find(todo.samples(:,1)>todo.msgtime(i),1) pero mas eficiente'
% disp 'podriamos hacerlo para todos los eventos... o tal vez sea mucho'
% disp ' '

%para que no aparezca msg numerito en todo.msg ->>> appear msg number everywhere msg? 

for i=1:length(todo.msg)
    [A, count, errmsg, nextindex]=sscanf(todo.msg{i},'MSG%f');%todo esto para buscar nextindex
    %nextindex es el indice del caracter despues de leer MSG y un float 
    %->>>nextindex is the index of the sign after reading MSG, and faster?
    todo.msg{i}=todo.msg{i}(nextindex+1:end);
end


save todo todo
end



function matriz=busca_samples(data,modo)
tic
if strcmp(modo,'RTABLE') | strcmp(modo,'MTABLE') %si es remoto o monocular ->>> as remote for monoculaire
    %no hago lo mismo que en binocular pues eso es mucho mas lento.
    
    %->>> dont want to do the same in binocular for this, because it takes to
    %much time?
    matriz=nan(length(data),4);
    for i=1:length(data);
        temp=sscanf(char(data(i)),'%f');
        if length(temp)==4
            matriz(i,:)=temp;
        elseif length(temp)==1
            matriz(i,:)=nan;
            matriz(i,1)=temp;
        end
    end
elseif strcmp(modo,'BTABLE') %si es binocular->>>yes, as binocular
    %tengo que hacer algo diferente para binocular pues sino no entiende
    %cuando tengo un solo ojo (uno blinkeado), y cosas asi. ero tarda mas
    
    %->>>i have to do something different for binocular, but i dont
    %understand when i have only one eye, and things like that take longer 
    
    DATOSPORSAMPLE=7;
    matriz=nan(length(data),DATOSPORSAMPLE);
    for i=1:length(data);
        if mod(i,10000)==0;fprintf(1,'%d0k ',i/10000);end            
        str=char(data(i));
        C = textscan(str, '%s','delimiter', '\t');
        C=str2double(C{1});        
        if length(C)==DATOSPORSAMPLE+1
            matriz(i,:)=C(1:DATOSPORSAMPLE);
        end                
    end
    matriz(find(isnan(matriz(:,5))),7)=nan;
else
    disp('Modo desconocido')
    matriz=[];
    return
end


Index=find(isnan(matriz(:,1)));
matriz(Index,:)=[];


tiempo=toc;
disp([num2str(length(matriz)) ' samples encontrados en ' num2str(tiempo) ' seg.'])  
disp(['Samples/seg = ' num2str(length(matriz)/tiempo)])  

end

function [matriz indices] = busca_eventos(data,event_name)


switch event_name
   case {'EFIX L','EFIX R' }
      numeros=6;
   case {'ESACC L','ESACC R'}
      numeros=9;
   case {'EBLINK L','EBLINK R'}
      numeros=3;
   case 'MSG'
      numeros=1;
    otherwise
       disp('nose')
end


indices=mystrmatch(event_name,data);
matriz=nan(length(indices),numeros);
for i=1:length(indices);
%    data{indices(i)}
    temp=sscanf(data{indices(i)},[event_name ' %f %f %f %f %f %f %f %f %f']);
    matriz(i,1:length(temp))=temp;
end
disp([num2str(length(indices)) ' eventos ' event_name ' encontrados.'])    

end

function [coincidencias]=mystrmatch(string,data)
    coincidencias=[];
    deacuantos=200000;
    pos=0;
    contador=0;
    while pos<length(data);
        if (pos+deacuantos)>length(data)
            indices=(pos+1):length(data);
        else
            indices=pos+(1:deacuantos);
        end
        loqueagrego=pos+strmatch(string,data(indices));
        coincidencias=[coincidencias; loqueagrego];        
        pos=pos+deacuantos;
        contador=contador+1;
%        fprintf(1,'%d %d %d %d\n',contador,indices(1),indices(end),length(loqueagrego))
    end
        
% %esto anda pero es lento pues ejecuta strmatch 10millones de veces  ->> runs, but is veryvery slow  
%     indices=[];
%     for i=1:length(data)
%         temp=data{i};
%         if strmatch(string,temp(1:length(string)))
%             indices(end+1)=i;    
%         end
%     end
%     coincidencias=indices;
end

function [linea tline]=busca_texto_en_archivo(filename, texts,maxlines)
% busca uno de los textos en el archivo, hasta un maximo de maxline lineas
% y devuelve numero de linea y texto de la linea encontrada
%->>>search for one of the texts in the file, up to a maximum of maxlines
%and return numer of line and text of the line found

linea=[];
tline=[];
fid=fopen(filename);
contador=0;
while isempty(ferror(fid)) && contador<maxlines %mientras no da fin de archivo ->>>
    contador=contador+1;
    tline = fgetl(fid);    %leo una linea del archivo->>> read one line archive 
    for i=1:length(texts)% para cada uno de los textos de busqueda->> for each of the search texts
        if ~isempty(strfind(tline,texts{i})) %me fijo si aparece en la linea->> notice if it appears on the line 
%            disp([tline ])
            linea=contador; 
            fclose(fid);
            return %si parece cierro y me voy->> it seems i close and go
        end
    end
%    disp([num2str(contador) tline])
end
fclose(fid);
if isempty(linea)
    tline=[];
end
end

function MODO=modo_eyelink(archivo)
% se fija si es (M)onocular, (B)inocular o (R)emoto ->>>it is fixed if it
% is M,B,R
    MODO=[];
    [linea textline]=busca_texto_en_archivo(archivo, {'ELCLCFG'},1000);
    if strfind(textline,'RTABLE')>0
        MODO='RTABLE';%remoto
    elseif  strfind(textline,'BTABLE')>0
        MODO='BTABLE';%binocular
    elseif strfind(textline,'MTABLE')>0
        MODO='MTABLE';%monocular
    end
end

function ojo=busca_ojo(archivo)
%busca que ojo se utilizo ->>>look which eye is used
    [linea textline]=busca_texto_en_archivo(archivo,{'START'},1000);
    ojo=[];
    if isempty(linea)
        ojo=nan;        
    else
        derecho=strfind(textline,'RIGHT');      
        izquierdo=strfind(textline,'LEFT');
        if ~isempty(derecho) && ~isempty(izquierdo)
            ojo='BOTH';
        elseif ~isempty(derecho) && isempty(izquierdo)
            ojo='RIGHT';
        elseif isempty(derecho) && ~isempty(izquierdo)
            ojo='LEFT';
        else
            ojo='??';
            disp('ojo no reconocido')
        end
    
    end
end

function srate=busca_samplingrate(archivo)
%busca que ojo se utilizo ->>> look which eye is used
    [linea textline]=busca_texto_en_archivo(archivo,{'RATE'},1000);
    ojo=[];
    if isempty(linea)
        srate=[];
    else
        posicion=strfind(textline,'RATE');
        srate=sscanf(textline(posicion+4:end),'%f');
    end

end

function driftcorrect=busca_driftcorrect(archivo)
%devuelve el primer drift correct que encuentra, en formato ->>>return the
%frist correct drift that it finds in format
%[[dcxl dcyl] 
% [dcxr dcyr]]

    [linea textline]=busca_texto_en_archivo(archivo, {'DRIFTCORRECT LR LEFT' 'DRIFTCORRECT L LEFT'},1000);        
    if isempty(linea)
        driftcorrectleft=[nan; nan];
    else
        posicion=strfind(textline,'deg.');
        driftcorrectleft=sscanf(textline(posicion+4:end),'%f,%f');
    end
    
    [linea textline]=busca_texto_en_archivo(archivo, {'DRIFTCORRECT LR RIGHT' 'DRIFTCORRECT R RIGHT'},1000);        
    if isempty(linea)
        driftcorrectright=[nan; nan];
    else
        posicion=strfind(textline,'deg.');
        driftcorrectright=sscanf(textline(posicion+4:end),'%f,%f');
    end
    driftcorrect=[driftcorrectleft driftcorrectright]';
end
