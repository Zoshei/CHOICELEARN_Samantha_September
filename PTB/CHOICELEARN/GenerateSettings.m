function GenerateSettings(nSubs)

% How many morphseries do we have
nMorphSeries = 24;
nPositions = 6;

% Possible configs (pick one per subject!)
config(1).relred.pos = [2 5]; % [rel red]
config(2).relred.pos = [3 6];

for n = 1:nSubs
    configorder = Shuffle(1:length(config));
    cidx = configorder(1);
    relred = Shuffle(config(cidx).relred.pos);

    settings(n).relpos = relred(1); %#ok<*SAGROW>
    settings(n).redpos = relred(2);

    dpos = 1: nPositions;
    dpos(dpos == settings(n).relpos) = [];
    dpos(dpos == settings(n).redpos) = [];
    settings(n).dispos = Shuffle(dpos); 

    imgorder = Shuffle(1:nMorphSeries); 
    settings(n).relidx = imgorder(1:4);
    settings(n).redidx = imgorder(5:8);
    settings(n).dis(1).idx = imgorder(9:12);
    settings(n).dis(2).idx = imgorder(13:16);
    settings(n).dis(3).idx = imgorder(17:20);
    settings(n).dis(4).idx = imgorder(21:24);
    
    fn = ['config_' num2str(n,'%0.3d') '.m'];
    fid = fopen(fn,'w');
    fn2 = ['config_red_' num2str(n,'%0.3d') '.m'];
    fid2 = fopen(fn2,'w');
    
    
    fprintf(fid,'%% STIMULUS TRIAL TYPES ==========\n');
    fprintf(fid,'STIM.Template.imgpos.r = 5;\n');
    fprintf(fid,'STIM.Template.imgpos.angle = 0:60:359;\n');
    fprintf(fid,['STIM.Template.relred.pos = ' ...
        mat2str(relred) ';\n']);

    fprintf(fid2,'%% STIMULUS TRIAL TYPES ==========\n');
    fprintf(fid2,'STIM.Template.imgpos.r = 0;\n');
    fprintf(fid2,'STIM.Template.imgpos.angle = 0;\n');

    for i = 1:length(settings(n).dis)
        fprintf(fid,['STIM.Template.distractor(' num2str(i) ...
            ').pos = ' num2str(settings(n).dispos(i)) ';\n']);
        fprintf(fid,['STIM.Template.distractor(' num2str(i) ...
            ').idx = ' mat2str(settings(n).dis(i).idx) ';\n']);
    end
    fprintf(fid,'STIM.Template.noreps = true;\n');
    
    corresp = [1 1 2 2];
    rel = [relred(1) relred(2) relred(1) relred(2)];
    red = [relred(2) relred(1) relred(2) relred(1)];
    for i = 1:4 % 4 trialtypes
        fprintf(fid,['STIM.TrialType(' num2str(i) ...
            ').relevant_idx = ' num2str(settings(n).relidx(i)) ';\n']);
        fprintf(fid,['STIM.TrialType(' num2str(i) ...
            ').relevant_pos = ' num2str(rel(i)) ';\n']);
        fprintf(fid,['STIM.TrialType(' num2str(i) ...
            ').redundant_idx = ' num2str(settings(n).redidx(i)) ';\n']);
        fprintf(fid,['STIM.TrialType(' num2str(i) ...
            ').redundant_pos = ' num2str(red(i)) ';\n']);
        fprintf(fid,['STIM.TrialType(' num2str(i) ...
            ').correctresponse = ' num2str(corresp(i)) ';\n']);
    end
    fclose(fid);

    for i = 1:4 % 4 trialtypes
        fprintf(fid2,['STIM.TrialType(' num2str(i) ...
            ').morphseries_idx = ' num2str(settings(n).relidx(i)) ';\n']);
        fprintf(fid2,['STIM.TrialType(' num2str(i) ...
            ').morphposition = 1;\n']);
        fprintf(fid2,['STIM.TrialType(' num2str(i) ...
            ').imgtype = relevant;\n']);
        fprintf(fid2,['STIM.TrialType(' num2str(i) ...
            ').correctresponse = ' num2str(corresp(i)) ';\n']);

        fprintf(fid2,['STIM.TrialType(' num2str(4+i) ...
            ').morphseries_idx = ' num2str(settings(n).relidx(i)) ';\n']);
        fprintf(fid2,['STIM.TrialType(' num2str(4+i) ...
            ').morphposition = 10;\n']);
        fprintf(fid2,['STIM.TrialType(' num2str(4+i) ...
            ').imgtype = relevant;\n']);
        fprintf(fid2,['STIM.TrialType(' num2str(4+i) ...
            ').correctresponse = ' num2str(corresp(i)) ';\n']);

        fprintf(fid2,['STIM.TrialType(' num2str(8+i) ...
            ').morphseries_idx = ' num2str(settings(n).relidx(i)) ';\n']);
        fprintf(fid2,['STIM.TrialType(' num2str(8+i) ...
            ').morphposition = 1;\n']);
        fprintf(fid2,['STIM.TrialType(' num2str(8+i) ...
            ').imgtype = redundant;\n']);
        fprintf(fid2,['STIM.TrialType(' num2str(8+i) ...
            ').correctresponse = ' num2str(corresp(i)) ';\n']);

        fprintf(fid2,['STIM.TrialType(' num2str(12+i) ...
            ').morphseries_idx = ' num2str(settings(n).relidx(i)) ';\n']);
        fprintf(fid2,['STIM.TrialType(' num2str(12+i) ...
            ').morphposition = 10;\n']);
        fprintf(fid2,['STIM.TrialType(' num2str(12+i) ...
            ').imgtype = redundant;\n']);
        fprintf(fid2,['STIM.TrialType(' num2str(12+i) ...
            ').correctresponse = ' num2str(corresp(i)) ';\n']);
    end
    fprintf(fid2,'STIM.Trials.TrialsInExp = 1:16;\n');
    fclose(fid2);
end


