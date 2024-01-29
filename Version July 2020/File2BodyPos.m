function [PosAll,PosActual,NameC,NameS] = File2BodyPos(FileNames)

% Estimates which file in FileNames match the body position thigh, hip, arm and trunk.
% FileNames (cell array of file names) are scanned for text parts that can refer to thigh, hip, arm or trunk. 

% Output:
% PosActual is the positions recognized from the files in FileNames 
% NameC is a cellarray with the filenames matching PosActual
% NameS is a struct with the filenames matching PosAll

 Thigh = {'ben','lår','thigh','leg','femur'};
 Hip = {'hofte','hip','crist'};
 Arm = {'arm','delto'};
 %Trunk = {'t1','t2','ryg','back','front','sternum','chest','bryst'}; %Marts 15: front, sternum and chest added
 Trunk = {'ryg','back','front','sternum','chest','bryst'}; %Aug 19: t1/ t2 risc for misclassification
 
 PosAll = {'Thigh','Hip','Arm','Trunk'};
 NameS = struct('Thigh','','Hip','','Arm','','Trunk','');

 for i=1:length(FileNames)
    for j=1:length(Thigh)
        if ~isempty((strfind(lower(FileNames{i}),Thigh{j}))), NameS.Thigh = FileNames{i}; end 
    end
    for j=1:length(Hip)
        if ~isempty((strfind(lower(FileNames{i}),Hip{j}))), NameS.Hip = FileNames{i}; end 
    end
    for j=1:length(Arm)
        if ~isempty((strfind(lower(FileNames{i}),Arm{j}))), NameS.Arm = FileNames{i}; end 
    end
    for j=1:length(Trunk)
        if ~isempty((strfind(lower(FileNames{i}),Trunk{j}))), NameS.Trunk = FileNames{i}; end 
    end
 end
 
 Inotempty = ~structfun(@isempty,NameS);
 PosActual = PosAll(Inotempty); 
 NameC = struct2cell(NameS);
 NameC = NameC(Inotempty);
 