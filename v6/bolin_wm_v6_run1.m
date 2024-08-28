% 输入法改成英语
clear;clc;close all;
global screens screenNumber win wsize flipIntv slack cx cy time_stamp

% 被试信息
exp_date = '20240826';
sub_num = '03';
sub_name = 'Test';
sub_sex = 'Male'; % Male, Female
sub_age = '23yrs';
sub_result = strcat('C:\Users\byron\Desktop\HippoCode20240603\results\sub_', sub_num, '_', sub_name, '_run1.mat');

% 键盘持续输入bug修复，f22
% PTB硬件bug，不同电脑会有不同错误按键
[keyIsDown, ~, keyCode] = KbCheck;
keyCode = find(keyCode, 1);
if keyIsDown
    ignoreKey=keyCode;
    DisableKeysForKbCheck(ignoreKey);
end

try
    % ====设定====
    %ListenChar(2); % 1，开启键盘录入(默认)；2，开启键盘录入，但不记录在Matlab中；0，关闭键盘录入
    KbName('UnifyKeyNames');
    space= KbName('space');
    keys= KbName('s'); % 3# for test in the lab, s for experiment
    key1= KbName('1!'); % Yes
    key2= KbName('2@'); % No
    
    HideCursor;
    InitializeMatlabOpenGL;
    Screen('Preference', 'SkipSyncTests', 1); % 跳过刷新率检测
    screens=Screen('Screens');
    %screenNumber=max(screens); % 第一个屏幕为0
    screenNumber=0;
    [win, wsize]=Screen('OpenWindow', screenNumber); % 美德液晶2880x1800
    cx=wsize(3)/2; cy=wsize(4)/2;     % 屏幕中央坐标
    flipIntv=Screen('GetFlipInterval', win); % 获取屏幕刷新间隔时间，单位s
    slack=flipIntv/2; % 弛豫时间
    Screen('FillRect',win,0); % 一个中性黑色的背景
    time_stamp = Screen('Flip',win); % 屏幕翻转的时间，单位s
    % ============
    
    
    % 导入图片并打乱顺序
    cd images/run1
    files=dir('*jpg*');
    random_order = randperm(length(files));
    image_pool = cell(1, length(files));
    image_shown = cell(1, length(files));
    for i= 1:length(files)
        image_pool{i}=imread(files(random_order(i)).name);
    end
    pixs=800;
    
    % 实验帧数的设计
    n_block=8; % 每个block需要60秒
    
    n_trial=4; 
    
    block_rest=24; block_rest = time2frame(flipIntv,block_rest);
    %trial_interval=1; trial_interval=time2frame(flipIntv,trial_interval); % 试次之间的间隔帧数，可以设置为被试作出反应的时间
    fix_onset=1; fix_onset=time2frame(flipIntv,fix_onset); % 注视点的帧数
    image_onset=1; image_onset=time2frame(flipIntv,image_onset); % 每张图片呈现的帧数
    hold_onset=2; hold_onset=time2frame(flipIntv,hold_onset); % 等待记忆保留的帧数
    response_onset=3; response_onset=time2frame(flipIntv,response_onset); % 作出反应的最长时间
    
    % 正确答案
    answer = randi([0,1],1,n_trial*n_block);
    % 第四张图的编号
    n_judge =[];
    
    % 预分配内存给反应矩阵
    response_pool=[];
    RT_pool=[];
    response_true=[];
    
    % 记录时间戳
    time_fixation = [];
    time_image1 = []; time_image2 = []; time_image3 = [];
    time_hold = [];
    time_judge = [];
    time_stim_block = [];
    
    
    % =========开始实验=====================
    
    % 指导语
    oldTextSize=Screen('TextSize', win, 100);
    txt='Welcome to Working Memory Experiment!';
    bRect= Screen('TextBounds',win,txt);
    Screen('DrawText',win,txt,cx-bRect(3)/2,cy-bRect(4)/2,255);
    time_stamp = Screen('Flip',win,time_stamp+1);
    
    % ===接收到磁共振触发，开始任务================================================
    ListenChar(2);
    while(1)
        [K_down, secs, K_code] = KbCheck;
        if(K_down)
            disp(KbName(find(K_code==1)))
            if(K_code(keys))
                break
            end
        end
    end
    Screen('FillRect',win,0);
    time_stamp = Screen('Flip',win);
    run_begin_time = GetSecs;
    
    for block=1:n_block
        % ===Rest============================
        Screen('FillRect',win,0);
        time_stamp = Screen('Flip',win,time_stamp+(block_rest-0.5)*flipIntv); % 完成任务后的30秒
        time_stim_block(block) = GetSecs-run_begin_time;
            
        for i=1:n_trial
            ind = i+(block-1)*n_trial;
            % ===注视点============================
            Screen('FillRect',win,0);
            Screen('DrawLine', win, 255, cx-40, cy, cx+40, cy, 10);
            Screen('DrawLine', win, 255, cx, cy-40, cx, cy+40, 10);
            %time_stamp = Screen('Flip',win,time_stamp+(trial_interval-0.5)*flipIntv); % 完成任务后的10秒
            time_stamp = Screen('Flip',win); % 完成任务后的10秒
            time_fixation(ind) = GetSecs-run_begin_time;
            
            % ===展示图片1=========================
            Screen('FillRect',win,0);
            img_ind=4*ind-3;
            Image_Index=Screen('MakeTexture', win, image_pool{img_ind});
            Screen('DrawTexture', win, Image_Index,[],[cx-pixs, cy-pixs, cx+pixs, cy+pixs]);
            time_stamp = Screen('Flip',win,time_stamp+(fix_onset-0.5)*flipIntv);
            time_image1(ind) = GetSecs-run_begin_time;
            image_shown{img_ind} = files(random_order(img_ind)).name; % 保存图片呈现的次序
            
            % ===展示图片2===========================
            Screen('FillRect',win,0);
            img_ind=4*ind-2;
            Image_Index=Screen('MakeTexture', win, image_pool{img_ind});
            Screen('DrawTexture', win, Image_Index,[],[cx-pixs, cy-pixs, cx+pixs, cy+pixs]);
            time_stamp = Screen('Flip',win,time_stamp+(image_onset-0.5)*flipIntv);
            time_image2(ind) = GetSecs-run_begin_time;
            image_shown{img_ind} = files(random_order(img_ind)).name; % 保存图片呈现的次序
            
            % ===展示图片3===========================
            Screen('FillRect',win,0);
            img_ind=4*ind-1;
            Image_Index=Screen('MakeTexture', win, image_pool{img_ind});
            Screen('DrawTexture', win, Image_Index,[],[cx-pixs, cy-pixs, cx+pixs, cy+pixs]);
            time_stamp = Screen('Flip',win,time_stamp+(image_onset-0.5)*flipIntv);
            time_image3(ind) = GetSecs-run_begin_time;
            image_shown{img_ind} = files(random_order(img_ind)).name; % 保存图片呈现的次序
            
            % ===注视点等待，记忆保留==============================
            Screen('FillRect',win,0);
            Screen('DrawLine', win, 255, cx-40, cy, cx+40, cy, 10);
            Screen('DrawLine', win, 255, cx, cy-40, cx, cy+40, 10);
            time_stamp = Screen('Flip',win,time_stamp+(image_onset-0.5)*flipIntv);
            time_hold(ind) = GetSecs-run_begin_time;
            
            % ===展示回忆图片，并要求判断======================
            if answer(ind)==0
                n_judge(ind)=4*ind;
            else
                random_number=rand;
                if random_number<1/3
                    n_judge(ind)=4*ind-3;
                elseif random_number<2/3
                    n_judge(ind)=4*ind-2;
                else
                    n_judge(ind)=4*ind-1;
                end
            end
            
            Screen('FillRect',win,0);
            Image_Index=Screen('MakeTexture', win, image_pool{n_judge(ind)});
            Screen('DrawTexture', win, Image_Index,[],[cx-pixs, cy-pixs, cx+pixs, cy+pixs]);
            oldTextSize=Screen('TextSize', win, 160);
            Screen('DrawText',win,'Yes',cx-pixs-400,cy-pixs,[0,255,0]); % 绿色
            Screen('DrawText',win,'No',cx+pixs+100,cy-pixs,[255,0,0]); % 红色
            time_stamp = Screen('Flip',win,time_stamp+(hold_onset-0.5)*flipIntv);
            time_judge(ind) = GetSecs-run_begin_time;
            image_shown{4*ind} = files(random_order(n_judge(ind))).name; % 保存图片呈现的次序
            
            % 要求【被试反应】
            start_time=GetSecs;
            response_pool(ind)=nan;
            RT_pool(ind)=nan;
            while(GetSecs-start_time<response_onset*flipIntv) % 最多等多久？
                [K_down, ~, K_code] = KbCheck;
                if(K_down)
                    % 保存反应时
                    RT_pool(ind)=GetSecs-start_time;
                    % ===按键后的刺激间隙================================================
                    judge_onset=time2frame(flipIntv,RT_pool(ind));
                    Screen('FillRect',win,0);
                    Screen('DrawLine', win, 255, cx-40, cy, cx+40, cy, 10);
                    Screen('DrawLine', win, 255, cx, cy-40, cx, cy+40, 10);
                    time_stamp = Screen('Flip',win,time_stamp+(judge_onset-0.5)*flipIntv);
                    
                    % 记录按键信息，反应是否正确
                    response_pool(ind)=find(K_code==1); % 获取按下的是哪个键的信息
                    if(K_code(space)) % 如果按下的是空格
                        sca; % Screen('CloseAll') 关闭屏幕
                        % 保存做过的数据
                        stats.date = exp_date;
                        stats.subinfo = {sub_num, sub_name, sub_sex, sub_age};
                        stats.trial_num = n_trial*n_block;
                        stats.time_stim_block = time_stim_block;
                        stats.image_shown = image_shown; % 并非所有图片都出现了
                        stats.n_judge = n_judge; % 每一轮的判断出现的是第几张图
                        stats.time_fixation = time_fixation; % 注视点的时间戳
                        stats.time_image1 = time_image1; % 第一张图的时间戳
                        stats.time_image2 = time_image2; % 第二张图的时间戳
                        stats.time_image3 = time_image3; % 第三张图的时间戳
                        stats.time_hold = time_hold; % hold保持记忆的时间戳
                        stats.time_judge = time_judge; % 展示判断图的时间戳
                        stats.response = {RT_pool,response_true,response_pool};
                        stats.docs = 'To be continued...';
                        save(sub_result, 'stats');
                        return % 直接结束程序
                    elseif(K_code(key1)) % 如果按下的是1 for Yes
                        if(answer(ind)==1)
                            response_true(ind) = 1; % response true
                        else
                            response_true(ind) = 0; % response wrong
                        end
                    elseif(K_code(key2)) % 如果按下的是2 for No
                        if(answer(ind)==0)
                            response_true(ind) = 1; % response true
                        else
                            response_true(ind) = 0; % response wrong
                        end
                    else % 如果按了其他
                        response_true(ind) = 0; % response wrong
                    end
                    
                    break
                end
            end
            
            % ===刺激间隙================================================
            if(K_down)
                response_int_onset=time2frame(flipIntv,3-RT_pool(ind));
                Screen('FillRect',win,0);
                time_stamp = Screen('Flip',win,time_stamp+(response_int_onset-0.5)*flipIntv);
            else
                response_int_onset=time2frame(flipIntv,3);
                Screen('FillRect',win,0);
                time_stamp = Screen('Flip',win,time_stamp+(response_int_onset-0.5)*flipIntv);
            end
            
        end
    
    end
    time_stamp = Screen('Flip',win,time_stamp+5); % 屏幕持续5秒
    
    % 保存做过的数据
    stats.subinfo = {sub_num, sub_name, sub_sex, sub_age};
    stats.trial_num = n_trial*n_block;
    stats.time_stim_block = time_stim_block;
    stats.image_shown = image_shown; % 并非所有图片都出现了
    stats.n_judge = n_judge; % 每一轮的判断出现的是第几张图
    stats.time_fixation = time_fixation; % 注视点的时间戳
    stats.time_image1 = time_image1; % 第一张图的时间戳
    stats.time_image2 = time_image2; % 第二张图的时间戳
    stats.time_image3 = time_image3; % 第三张图的时间戳
    stats.time_hold = time_hold; % hold保持记忆的时间戳
    stats.time_judge = time_judge; % 展示判断图的时间戳
    stats.response = {RT_pool,response_true,response_pool};
    stats.docs = 'To be continued...';
    save(sub_result, 'stats');
    
    % run结束，关闭屏幕
    Screen('CloseAll');%sca;
    ListenChar(0);
catch
    ListenChar(0);
    sca;
end



function nframe = time2frame(flipIntv,duration)
nframe=round(duration/flipIntv);
end