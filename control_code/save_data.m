FolderName = datestr(now,'yyyymmdd');
if ~exist(FolderName, 'dir')
   mkdir(FolderName)
end
FileNb = 1;
FileName = sprintf('C:/Users/Margot Paez/Desktop/snake/Dmitri_small_robot/%s/experiment_%d.mat', FolderName, FileNb);
while exist(FileName, 'file') == 2
    FileNb = FileNb + 1;
    FileName = sprintf('C:/Users/Margot Paez/Desktop/snake/Dmitri_small_robot/%s/experiment_%d.mat', FolderName, FileNb);
end
save(FileName, 'fbk');