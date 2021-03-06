//
//  WatchRTMPViewController.m
//  VHallSDKDemo
//
//  Created by developer_k on 16/4/13.
//  Copyright © 2016年 vhall. All rights reserved.
//
#import <AVFoundation/AVFoundation.h>
#import "WatchLiveViewController.h"
#import <MediaPlayer/MPMoviePlayerController.h>
#import "WatchLiveOnlineTableViewCell.h"
#import "WatchLiveChatTableViewCell.h"
#import "WatchLiveQATableViewCell.h"
#import "WatchLiveSurveyTableViewCell.h"
#import "WatchLiveLotteryViewController.h"
#import "VHMessageToolView.h"
#import "VHallApi.h"
#import "MBProgressHUD.h"
#import "AnnouncementView.h"
#import "SignView.h"
#import "BarrageRenderer.h"
#import "NSSafeObject.h"
#import "SZQuestionItem.h"
#import "VHQuestionCheckBox.h"
//#import "VHDrawView.h"
#import "VHDocumentView.h"

# define DebugLog(fmt, ...) NSLog((@"\n[文件名:%s]\n""[函数名:%s]\n""[行号:%d] \n" fmt), __FILE__, __FUNCTION__, __LINE__, ##__VA_ARGS__);

static AnnouncementView* announcementView = nil;
@interface WatchLiveViewController ()<VHallMoviePlayerDelegate, VHallChatDelegate, VHallQADelegate, VHallLotteryDelegate,VHallSignDelegate,VHallSurveyDelegate, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate,VHMessageToolBarDelegate>
{
    VHallMoviePlayer  *_moviePlayer;//播放器
    __weak IBOutlet UIView *_showView;

    VHallChat         *_chat;       //聊天
    VHallQAndA        *_QA;         //问答
    VHallLottery      *_lottery;    //抽奖
    VHallSign         *_sign;       //签到
    VHallSurvey       *_survey;      //问卷
    BarrageRenderer   *_renderer;   //弹幕
    
    UIImageView       *_logView;    //当播放音频时显示的图片
    WatchLiveLotteryViewController *_lotteryVC; //抽奖VC
//    BOOL _isStart;
    BOOL _isMute;
    BOOL _isAllScreen;
    BOOL _isReciveHistory;
    int  _bufferCount;
    BOOL _fullScreentBtnClick;
    BOOL _isVr;
    BOOL _isRender;//

    NSMutableArray    *_QADataArray;
    NSArray           *_videoLevePicArray;//视频质量等级图片
    NSMutableArray    *_videoPlayModel;//播放模式
//    NSMutableArray    *_videoPlayModelPicArray;//单视频纯音频切换
     UIButton          *_toolViewBackView;//遮罩
     NSMutableDictionary *announcementContentDic;//公告内容
//     VHDrawView *_pptHandView;//PPT
//    VHDrawView *_whiteBoardView;//白板
//    UIView     *_whiteBoardContainer;//白板容器
    VHDocumentView* _documentView;
}

@property (weak, nonatomic) IBOutlet UILabel *bufferCountLabel;
@property (weak, nonatomic) IBOutlet UIButton *muteBtn;
@property (weak, nonatomic) IBOutlet UIButton *allScreenBtn;
@property (weak, nonatomic) IBOutlet UILabel *bitRateLabel;
@property (weak, nonatomic) IBOutlet UIButton *startAndStopBtn;
@property (weak, nonatomic) IBOutlet UIView *backView;
@property (weak, nonatomic) IBOutlet UIImageView *textImageView;
@property (weak, nonatomic) IBOutlet UILabel *liveTypeLabel;

@property (weak, nonatomic) IBOutlet UIButton *detailBtn;
@property (weak, nonatomic) IBOutlet UIButton *docBtn;
@property (weak, nonatomic) IBOutlet UIButton *chatBtn;
@property (weak, nonatomic) IBOutlet UIButton *QABtn;
@property (weak, nonatomic) IBOutlet UITableView *chatView;
@property (nonatomic,assign) VHMovieVideoPlayMode playModelTemp;
@property (nonatomic,strong) UILabel*textLabel;

@property (weak, nonatomic) IBOutlet UIButton *definitionBtn0;
@property (weak, nonatomic) IBOutlet UIButton *definitionBtn1;
@property (weak, nonatomic) IBOutlet UIButton *definitionBtn2;
@property (weak, nonatomic) IBOutlet UIButton *definitionBtn3;
@property (weak, nonatomic) IBOutlet UIButton *playModeBtn0;
@property (weak, nonatomic) IBOutlet UIButton *playModeBtn1;
@property (weak, nonatomic) IBOutlet UIButton *playModeBtn2;
@property (weak, nonatomic) IBOutlet UIButton *playModeBtn3;
@property (weak, nonatomic) IBOutlet UILabel *modelLabel;
@property (nonatomic,strong) VHMessageToolView * messageToolView;  //输入框
    @property (weak, nonatomic) IBOutlet UIButton *GyroBtn;//陀螺仪开关

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topConstraint;
@property (weak, nonatomic) IBOutlet UIButton *fullscreenBtn;
@property (weak, nonatomic) IBOutlet UIButton *rendererOpenBtn;
@property (nonatomic, strong) NSArray *surveyResultArray;//问卷结果

@property (nonatomic, strong)NSMutableArray    *chatDataArray;
@end

@implementation WatchLiveViewController

-(UILabel *)textLabel
{
    if (!_textLabel) {
        _textLabel = [[UILabel alloc]init];
        _textLabel.frame = CGRectMake(0, 10, self.textImageView.width, 21);
        _textLabel.text = @"无文档";
        _textLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _textLabel;
}


#pragma mark - Private Method

-(void)addPanGestureRecognizer
{
    UIPanGestureRecognizer * panGesture = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(handlePan:)];
    panGesture.maximumNumberOfTouches = 1;
    panGesture.minimumNumberOfTouches = 1;
    [_moviePlayer.moviePlayerView addGestureRecognizer:panGesture];
}

-(void)initDatas
{
//    _isStart = YES;
    _isMute = NO;
    _isAllScreen = NO;
    _chatDataArray = [NSMutableArray arrayWithCapacity:0];
    _QADataArray = [NSMutableArray arrayWithCapacity:0];
}

- (void)initViews
{
    //阻止iOS设备锁屏
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    [self registerLiveNotification];

    _moviePlayer = [[VHallMoviePlayer alloc]initWithDelegate:self];
    self.view.clipsToBounds = YES;
    _moviePlayer.movieScalingMode = VHRTMPMovieScalingModeAspectFit;
    _moviePlayer.bufferTime = (int)_bufferTimes;
    _moviePlayer.reConnectTimes = 2;
//    [_moviePlayer setRenderViewModel:VHRenderModelDewarpVR];
//   _moviePlayer.defaultDefinition = VHMovieDefinitionHD;

    // chat & QA 在播放之前初始化并设置代理
    _chat = [[VHallChat alloc] initWithMoviePlayer:_moviePlayer];
    _chat.delegate = self;
    _QA = [[VHallQAndA alloc] initWithMoviePlayer:_moviePlayer];
    _QA.delegate = self;
    _lottery = [[VHallLottery alloc] initWithMoviePlayer:_moviePlayer];
    _lottery.delegate = self;
    _sign = [[VHallSign alloc] initWithMoviePlayer:_moviePlayer];
    _sign.delegate = self;
    _survey=[[VHallSurvey alloc] initWithMoviePlayer:_moviePlayer];
    _survey.delegate= self;

    _logView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"UIModel.bundle/vhallLogo.tiff"]];
    _logView.backgroundColor = [UIColor whiteColor];
    _logView.contentMode = UIViewContentModeCenter;
    self.view.backgroundColor=[UIColor blackColor];
    [self.backView addSubview:_moviePlayer.moviePlayerView];
    [self.backView sendSubviewToBack:_moviePlayer.moviePlayerView];
    [_moviePlayer.moviePlayerView addSubview:_logView];    
    [self.view bringSubviewToFront:self.backView];
    _textImageView.hidden = YES;
    _logView.hidden = YES;
    _videoLevePicArray=@[@"UIModel.bundle/原画.tiff",@"UIModel.bundle/超清.tiff",@"UIModel.bundle/高清.tiff",@"UIModel.bundle/标清.tiff",@""];
//    _videoPlayModelPicArray=@[@"UIModel.bundle/单视频",@"UIModel.bundle/单音频"];
    _videoPlayModel=[NSMutableArray array];

    if ([self.chatView  respondsToSelector:@selector(setLayoutMargins:)]) {
        [self.chatView setLayoutMargins:UIEdgeInsetsZero];
    }
    
    [self initBarrageRenderer];
  
}

- (void)initBarrageRenderer
{
    _renderer = [[BarrageRenderer alloc]init];
    [_moviePlayer.moviePlayerView addSubview:_renderer.view];
    _renderer.canvasMargin = UIEdgeInsetsMake(20, 10,30, 10);
    // 若想为弹幕增加点击功能, 请添加此句话, 并在Descriptor中注入行为
//    _renderer.view.userInteractionEnabled = YES;
    [_moviePlayer.moviePlayerView sendSubviewToBack:_renderer.view];
}


- (void)destoryMoivePlayer
{
    [_moviePlayer destroyMoivePlayer];

}

//调查问卷页面
-(void)showSurveyVCWithSruveyModel:(VHallSurvey*)survey
{
//    __weak typeof(self) weakSelf =self;
    NSMutableArray *titleArray=[[NSMutableArray alloc] init];
    NSMutableArray *optionArray=[[NSMutableArray alloc] init];
    NSMutableArray *typeArry  =[[NSMutableArray alloc] init];
    NSMutableArray *isMustSelectArray = [[NSMutableArray alloc] init];
    
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"_orderNum" ascending:NO];
    survey.questionArray =[survey.questionArray sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    
    for (VHallSurveyQuestion *question in survey.questionArray)
    {
            [titleArray addObject:question.questionTitle];
        
        if (question.quesionSelectArray !=nil)
        {
            [optionArray addObject:question.quesionSelectArray];
        }else
        {
            [optionArray addObject:@[]];
        }
        // 选项类型 （0问答 1单选 2多选）
        if (question.type == 0)
        {
            [typeArry addObject:@(3)];
        }else if (question.type ==1)
        {
            [typeArry addObject:@(1)];
        }else if (question.type ==2)
        {
            [typeArry addObject:@(2)];
        }
        
        if (question.isMustSelect)
        {
            [isMustSelectArray addObject:@"1"];
        }else
        {
            [isMustSelectArray addObject:@"0"];
        }
    }
//    NSArray *resultArray =[[NSMutableArray alloc] init];
    SZQuestionItem *item = [[SZQuestionItem alloc] initWithTitleArray:titleArray andOptionArray:optionArray andResultArray:self.surveyResultArray andQuestonTypes:typeArry isMustSelectArray:isMustSelectArray];
   VHQuestionCheckBox *questionBox=[[VHQuestionCheckBox alloc] initWithItem:item];
    questionBox.survey = survey;
    
    [self presentViewController:questionBox animated:YES completion:^{

     }];
}

-(void)clickSurvey:(id)mode
{
    VHallSurveyModel *model =mode;
    __weak typeof(self) weakSelf =self;
    [self rotateScreen:NO];
    self.fullscreenBtn.enabled =NO;
    [_survey getSurveryContentWithSurveyId:model.surveyId webInarId:_roomId success:^(VHallSurvey *survey) {
        weakSelf.fullscreenBtn.enabled =YES;
        [weakSelf showSurveyVCWithSruveyModel:survey];
    } failed:^(NSDictionary *failedData) {
        weakSelf.fullscreenBtn.enabled =YES;
        NSString* code = [NSString stringWithFormat:@"%@", failedData[@"code"]];
        [UIAlertView popupAlertByDelegate:nil title:failedData[@"content"] message:code];
    }];
}
#pragma mark - 注册通知
- (void)registerLiveNotification
{
    [self.view addObserver:self forKeyPath:kViewFramePath options:NSKeyValueObservingOptionNew context:nil];
    //已经进入活跃状态的通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActive)name:UIApplicationDidBecomeActiveNotification object:nil];
    //监听耳机的插拔
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(outputDeviceChanged:)name:AVAudioSessionRouteChangeNotification object:[AVAudioSession sharedInstance]];
    
   }


#pragma mark - UIButton Event
- (IBAction)stopWatchBtnClick:(id)sender
{
    _definitionBtn0.hidden = YES;
    if (_moviePlayer.playerState == VHPlayerStateStoped || _moviePlayer.playerState == VHPlayerStateStreamStoped) {
        [MBProgressHUD hideHUDForView:_moviePlayer.moviePlayerView animated:NO];
         [MBProgressHUD showHUDAddedTo:_moviePlayer.moviePlayerView animated:YES];
        _bufferCount = 0;
        _bufferCountLabel.text = [NSString stringWithFormat:@"卡顿：%d",_bufferCount];
        if(_moviePlayer.playerState == VHPlayerStateStreamStoped)
        {
            [_moviePlayer reconnectPlay];
            if (self.playModelTemp == VHMovieVideoPlayModeTextAndVoice || self.playModelTemp == VHMovieVideoPlayModeVoice) {
                self.liveTypeLabel.text = @"语音直播中";
            }else{
                _definitionBtn0.hidden = NO;
                self.liveTypeLabel.text = @"";
            }
            return;
        }
        else
        {
            NSMutableDictionary * param = [[NSMutableDictionary alloc]init];
            param[@"id"] =  _roomId;
            param[@"name"] = [UIDevice currentDevice].name;
            param[@"email"] = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
            if (_kValue&&_kValue.length>0) {
                param[@"pass"] = _kValue;
            }
            [_moviePlayer startPlay:param];
        }
    }
    else if (_moviePlayer.playerState == VHPlayerStatePlaying)//暂停
    {
        [MBProgressHUD hideHUDForView:_moviePlayer.moviePlayerView animated:NO];
        _bitRateLabel.text = @"";
        _bufferCount = 0;
        _bufferCountLabel.text = [NSString stringWithFormat:@"卡顿：%d",_bufferCount];
        _startAndStopBtn.selected = NO;
        [_moviePlayer pausePlay];

        if (self.playModelTemp == VHMovieVideoPlayModeTextAndVoice || self.playModelTemp == VHMovieVideoPlayModeVoice) {
            self.liveTypeLabel.text = @"已暂停语音直播";
        }else{
            self.liveTypeLabel.text = @"";
        }
    }

    if (self.textImageView.image == nil) {
        [self.textImageView addSubview:self.textLabel];
    }else{
        [self.textLabel removeFromSuperview];
        self.textLabel = nil;
    }
}


#pragma mark 点击聊天输入框蒙版
-(void)toolViewBackViewClick
{
    [_messageToolView endEditing:YES];
    [_toolViewBackView removeFromSuperview];
}

#pragma mark - 返回上层界面按钮
- (IBAction)closeBtnClick:(id)sender
{
    __weak typeof(self) weakSelf = self;
     [_renderer stop];
    [_moviePlayer stopPlay];
    [self dismissViewControllerAnimated:YES completion:^{
        [weakSelf destoryMoivePlayer];
    }];
}

#pragma mark - 静音
- (IBAction)muteBtnClick:(UIButton *)sender
{
    _isMute = !_isMute;
    [_moviePlayer setMute:_isMute];
    sender.selected = _isMute;
}

#pragma mark - RTMP屏幕自适应
- (IBAction)allScreenBtnClick:(id)sender
{
    _isAllScreen = !_isAllScreen;
    if (_isAllScreen) {
        _moviePlayer.movieScalingMode = VHRTMPMovieScalingModeAspectFill;

    }else{
        _moviePlayer.movieScalingMode = VHRTMPMovieScalingModeAspectFit;
    }
}
#pragma mark 发送聊天按钮
- (IBAction)sendChatBtnClick:(id)sender
{
    
    _toolViewBackView=[[UIButton alloc] initWithFrame:CGRectMake(0, 0, VH_SW, VH_SH)];
    _toolViewBackView.backgroundColor=[UIColor clearColor];
    [_toolViewBackView addTarget:self action:@selector(toolViewBackViewClick) forControlEvents:UIControlEventTouchUpInside];
    _messageToolView=[[VHMessageToolView alloc] initWithFrame:CGRectMake(0, _toolViewBackView.height-[VHMessageToolView  defaultHeight], VHScreenWidth, [VHMessageToolView defaultHeight]) type:3];
    _messageToolView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin;
    _messageToolView.delegate=self;
    _messageToolView.hidden=NO;
    _messageToolView.maxLength=140;
    [_toolViewBackView addSubview:_messageToolView];
    [self.view addSubview:_toolViewBackView];
    [_messageToolView beginTextViewInView];
}

#pragma mark - Lifecycle Method
- (id)init
{
    self = [super initWithNibName:NSStringFromClass([self class]) bundle:meetingResourcesBundle];
    if (self) {
        [self initDatas];
    }
    return self;
}

-(BOOL)shouldAutorotate
{
    if (_fullScreentBtnClick) {
        return YES;
    }else if (_isVr)
    {
        return NO;
    }
    return YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    if (_fullScreentBtnClick) {
        return YES;
    }else if (_isVr)
    {
        return NO;
    }
    return YES;
}

- (void)willAnimateSecondHalfOfRotationFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation duration:(NSTimeInterval)duration
{
    if (IOSVersion<8.0)
    {
        CGRect frame = self.view.frame;
        CGRect bounds = [[UIScreen mainScreen]bounds];
        if ([[UIDevice currentDevice] orientation] == UIDeviceOrientationPortrait// UIInterfaceOrientationPortrait
            || [[UIDevice currentDevice] orientation] == UIDeviceOrientationPortraitUpsideDown) { //UIInterfaceOrientationPortraitUpsideDown
            //竖屏
            frame = self.backView.bounds;
        } else {
            //横屏
            frame = CGRectMake(0, 0, bounds.size.height, bounds.size.width);
        }
        _moviePlayer.moviePlayerView.frame = frame;
        _logView.frame = _moviePlayer.moviePlayerView.bounds;
        _lotteryVC.view.frame = _showView.bounds;
    }
}

-(UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait|UIInterfaceOrientationMaskLandscapeLeft|UIInterfaceOrientationMaskLandscapeRight;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

#pragma mark - viewDidLoad
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self initViews];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if(announcementView && !announcementView.hidden)
    {
        announcementView.content = announcementView.content;
    }
}

-(void)viewWillLayoutSubviews
{
    
    if ([UIApplication sharedApplication].statusBarOrientation == UIDeviceOrientationPortrait)
        
    {
        _topConstraint.constant = 20;
        _fullscreenBtn.selected = NO;
        
    }
    else
    {
        _topConstraint.constant = 0;
        _fullscreenBtn.selected = YES;
    }
    
    if (_isVr && _GyroBtn.selected) {
        [_moviePlayer setUILayoutOrientation:[[UIDevice currentDevice]orientation]];
    }
    
    _fullScreentBtnClick=NO;
}

- (void)viewDidLayoutSubviews
{
    _moviePlayer.moviePlayerView.frame = self.backView.bounds;
    _logView.frame = _moviePlayer.moviePlayerView.bounds;
    _lotteryVC.view.frame = _showView.bounds;
    if (_documentView)
    {
        _documentView.frame = self.textImageView.bounds;
        [_documentView layoutSubviews];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    if (_chat) {
        _chat = nil;
    }
    
    if (_QA) {
        _QA = nil;
    }
    
    if (_lottery) {
        _lottery = nil;
    }
    
    if (_lotteryVC) {
        [_lotteryVC.view removeFromSuperview];
        [_lotteryVC removeFromParentViewController];
        [_lotteryVC destory];
        _lotteryVC = nil;
    }
    
    if (_sign) {
        _sign.delegate = nil;
    }
    if (_survey) {
        _survey.delegate = nil;
    }
    //阻止iOS设备锁屏
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    [self.view removeObserver:self forKeyPath:kViewFramePath];
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    VHLog(@"%@ dealloc",[[self class]description]);
}

#pragma mark - Delegate
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * cell = nil;
  __weak  typeof(self) weakSelf =self;
//  __weak  typeof(VHallSurvey) *weakSurvey = _survey;
    if (_chatBtn.selected)
    {
        id model = [_chatDataArray objectAtIndex:indexPath.row];
        if ([model isKindOfClass:[VHallOnlineStateModel class]])
        {
            static NSString * indetify = @"WatchLiveOnlineCell";
            cell = [tableView dequeueReusableCellWithIdentifier:indetify];
            if (!cell) {
                cell = [[WatchLiveOnlineTableViewCell alloc]init];
            }
            ((WatchLiveOnlineTableViewCell *)cell).model = model;
        } else if([model isKindOfClass:[VHallSurveyModel class]])
        {
            static NSString * indetify = @"WatchLiveSurveyTableViewCell";
            cell = [tableView dequeueReusableCellWithIdentifier:indetify];
            if (!cell) {
                cell = [[WatchLiveSurveyTableViewCell alloc]init];
            }
            ((WatchLiveSurveyTableViewCell *)cell).model = model;
              ((WatchLiveSurveyTableViewCell *)cell).clickSurveyItem=^(VHallSurveyModel *model)
            {
                [weakSelf performSelector:@selector(clickSurvey:) withObject:model];

            };
        }
        else
        {
            static NSString * indetify = @"WatchLiveChatCell";
            cell = [tableView dequeueReusableCellWithIdentifier:indetify];
            if (!cell) {
                cell = [[WatchLiveChatTableViewCell alloc]init];
            }
            ((WatchLiveChatTableViewCell *)cell).model = model;
        }
    }
    else if (_QABtn.selected)
    {
        static NSString * qaIndetify = @"WatchLiveQACell";
        cell = [tableView dequeueReusableCellWithIdentifier:qaIndetify];
        if (!cell) {
            cell = [[WatchLiveQATableViewCell alloc]init];
        }
        ((WatchLiveQATableViewCell *)cell).model = [_QADataArray objectAtIndex:indexPath.row];
    }
   else
    {
        static NSString * qaIndetify = @"identifiCell";
        cell = [tableView dequeueReusableCellWithIdentifier:qaIndetify];
        if (!cell) {
            cell =[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:qaIndetify];
        }
    }
    cell.width = self.view.bounds.size.width;
    return cell;
}



-(NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section
{
    if (_chatBtn.selected) {
        return _chatDataArray.count;
    }
    
    if (_QABtn.selected) {
        return _QADataArray.count;
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = 0;
    if (_chatBtn.selected)
    {
        id mode = [_chatDataArray objectAtIndex:indexPath.row];
        if ([mode isKindOfClass:[VHallOnlineStateModel class]])
        {
            height = 60;
        }
        else
        {
            height = 60;
        }
    }
    
    if (_QABtn.selected)
    {
        height = 120;
    }
    return height;
}


#pragma mark - VHMoviePlayerDelegate
-(void)moviePlayerWillMoveFromWindow
{
}

-(void)connectSucceed:(VHallMoviePlayer *)moviePlayer info:(NSDictionary *)info
{
  //  [_startAndStopBtn setTitle:@"停止播放" forState:UIControlStateNormal];
    _startAndStopBtn.selected = YES;
    [_definitionBtn0 setImage:[UIImage imageNamed:_videoLevePicArray[_moviePlayer.curDefinition]] forState:UIControlStateNormal];
}

-(void)bufferStart:(VHallMoviePlayer *)moviePlayer info:(NSDictionary *)info
{
    _bufferCount++;
    _bufferCountLabel.text = [NSString stringWithFormat:@"卡顿：%d",_bufferCount];
    [MBProgressHUD hideHUDForView:_moviePlayer.moviePlayerView animated:NO];
    [MBProgressHUD showHUDAddedTo:_moviePlayer.moviePlayerView animated:YES];
}

-(void)bufferStop:(VHallMoviePlayer *)moviePlayer info:(NSDictionary *)info
{
    [MBProgressHUD hideHUDForView:_moviePlayer.moviePlayerView animated:YES];

}

-(void)downloadSpeed:(VHallMoviePlayer *)moviePlayer info:(NSDictionary *)info
{
    NSString * content = info[@"content"];
    _bitRateLabel.text = [NSString stringWithFormat:@"%@ kb/s",content];
//    VHLog(@"downloadSpeed:%@",[info description]);
}

- (void)cdnSwitch:(VHallMoviePlayer*)moviePlayer info:(NSDictionary*)info
{
    
}

- (void)recStreamtype:(VHallMoviePlayer*)moviePlayer info:(NSDictionary*)info
{
    VHStreamType streamType = (VHStreamType)[info[@"content"] intValue];
    if (streamType == VHStreamTypeVideoAndAudio) {
        _logView.hidden = YES;
    } else if(streamType == VHStreamTypeOnlyAudio){
        _logView.hidden = NO;
    }
}

- (void)playError:(VHLivePlayErrorType)livePlayErrorType info:(NSDictionary *)info;
{
    [MBProgressHUD hideHUDForView:_moviePlayer.moviePlayerView animated:YES];
    void (^resetStartPlay)(NSString * msg) = ^(NSString * msg){
        _bitRateLabel.text = @"";
        _startAndStopBtn.selected = NO;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self detailsButtonClick: nil];
            [UIAlertView popupAlertByDelegate:nil title:msg message:nil];
        });
    };

    NSString * msg = @"";
    switch (livePlayErrorType) {
        case VHLivePlayParamError:
        {
            msg = @"参数错误";
            resetStartPlay(msg);
        }
            break;
        case VHLivePlayRecvError:
        {
            msg = @"对方已经停止直播";
            resetStartPlay(msg);
        }
            break;
        case VHLivePlayCDNConnectError:
        {
            msg = @"服务器任性...连接失败";
            resetStartPlay(msg);
        }
            break;
        case VHLivePlayGetUrlError:
        {
            msg = @"获取服务器地址报错";
            [self detailsButtonClick: nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBHUDHelper showWarningWithText:info[@"content"]];
            });
        }
            break;
        default:
            break;
    }
}

#pragma mark - vhallMoviePlayerDelegate
-(void)PPTScrollNextPagechangeImagePath:(NSString *)changeImagePath
{
//    [_pptHandView removeFromSuperview];
//    _pptHandView = nil;
//    self.textImageView.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:changeImagePath]]];
//    if (self.textImageView.image == nil) {
//        [self.textImageView addSubview:self.textLabel];
//    }else{
//        [self.textLabel removeFromSuperview];
//        self.textLabel = nil;
//
//    }
    
    if (changeImagePath.length<=0) {
        [self.textImageView addSubview:self.textLabel];
    }else{
        [self.textLabel removeFromSuperview];
        self.textLabel = nil;
        
    }
    
    if(!_documentView)
    {
        _documentView = [[VHDocumentView alloc]initWithFrame:self.textImageView.bounds];
        _documentView.contentMode = UIViewContentModeScaleAspectFit;
        _documentView.backgroundColor=MakeColorRGB(0xe2e8eb);
    }
    _documentView.frame = self.textImageView.bounds;
    [self.textImageView addSubview:_documentView];
    _documentView.imagePath = changeImagePath;
}

- (void)docHandList:(NSArray*)docList whiteBoardHandList:(NSArray*)boardList
{
    if(!_documentView)
    {
        _documentView = [[VHDocumentView alloc]initWithFrame:self.textImageView.bounds];
        _documentView.contentMode = UIViewContentModeScaleAspectFit;
        _documentView.backgroundColor=MakeColorRGB(0xe2e8eb);
    }
    _documentView.frame = self.textImageView.bounds;
    [_documentView drawDocHandList:docList whiteBoardHandList:boardList];
}



-(void)VideoPlayMode:(VHMovieVideoPlayMode)playMode isVrVideo:(BOOL)isVrVideo
{
    _chatBtn.enabled = YES;
    
    [self performSelector:@selector(chatButtonClick:) withObject:nil afterDelay:1];
    _isVr = isVrVideo;
    if (!_isRender)
    {
        if (isVrVideo)
        {
            _GyroBtn.hidden = NO;
            _GyroBtn.selected = YES;
            [_moviePlayer setRenderViewModel:VHRenderModelDewarpVR];
            [_moviePlayer setUsingGyro:YES];
            
        }else
        {
            _GyroBtn.hidden =YES;
            _GyroBtn.selected = NO;
            [_moviePlayer setRenderViewModel:VHRenderModelOrigin];
            [_moviePlayer setUsingGyro:NO];
            [self addPanGestureRecognizer];
        }
        _isRender =YES;
    }
    
    
    
    
    VHLog(@"---%ld",(long)playMode);
    self.liveTypeLabel.text = @"";
    _playModelTemp = playMode;
    switch (playMode) {
        case VHMovieVideoPlayModeNone:
        case VHMovieVideoPlayModeMedia:
        case VHMovieVideoPlayModeTextAndMedia:
//            [_playModeBtn0 setImage:[UIImage imageNamed:_videoPlayModelPicArray[0]] forState:UIControlStateNormal];
            _playModeBtn0.selected = NO;
            _playModeBtn0.enabled=YES;
            break;
        case VHMovieVideoPlayModeTextAndVoice:
        case VHMovieVideoPlayModeVoice:
        {
            self.liveTypeLabel.text = @"语音直播中";
        }
            _playModeBtn0.enabled=NO;
            break;
        default:
            break;
    }

    [self alertWithMessage:playMode];
}

-(void)VideoPlayModeList:(NSArray*)playModeList
{
    for (NSNumber *playMode in playModeList) {
        switch ([playMode intValue]) {
            case VHMovieVideoPlayModeMedia:
                [_videoPlayModel addObject:@"1"];
                break;
            case VHMovieVideoPlayModeTextAndVoice:
                [_videoPlayModel addObject:@"2"];
                break;
            case VHMovieVideoPlayModeTextAndMedia:
                [_videoPlayModel addObject:@"3"];
                break;
            case VHMovieVideoPlayModeVoice:
                [_videoPlayModel addObject:@"4"];
                break;
            default:
                break;
        }
    }
}

-(void)ActiveState:(VHMovieActiveState)activeState
{
    VHLog(@"activeState-%ld",(long)activeState);
}

- (void)VideoDefinitionList: (NSArray*)definitionList
{
    VHLog(@"可用分辨率%@ 当前分辨率：%ld",definitionList,(long)_moviePlayer.curDefinition);
    _definitionBtn0.hidden = NO;
    [_definitionBtn0 setImage:[UIImage imageNamed:_videoLevePicArray[_moviePlayer.curDefinition]] forState:UIControlStateNormal];
    if (_moviePlayer.curDefinition == VHMovieDefinitionAudio) {
        _playModelTemp=VHMovieVideoPlayModeVoice;
        _playModeBtn0.selected = YES;
    }
}

- (void)LiveStoped
{
    VHLog(@"直播已结束");
    [MBProgressHUD hideHUDForView:_moviePlayer.moviePlayerView animated:YES];
    _startAndStopBtn.selected = NO;
    [_moviePlayer stopPlay];
    UIAlertView*alert = [[UIAlertView alloc]initWithTitle:@"提示" message:@"直播已结束" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
    [alert show];
}

#pragma mark - Announcement
- (void)Announcement:(NSString*)content publishTime:(NSString*)time
{
    VHLog(@"公告:%@",content);
    if (!announcementContentDic)
    {
        announcementContentDic =[[NSMutableDictionary alloc] init];
    }
    [announcementContentDic setObject:content forKey:@"announceContent"];
    [announcementContentDic setObject:time forKey:@"announceTime"];
    
    
    if(!announcementView)
    { //横屏时frame错误
        if (_showView.width < [UIScreen mainScreen].bounds.size.height)
        {
            announcementView = [[AnnouncementView alloc]initWithFrame:CGRectMake(0, 0, _showView.width, 35) content:content time:nil];
        }else
        {
            announcementView = [[AnnouncementView alloc]initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.height, 35) content:content time:nil];
        }
        
    }
    announcementView.content = [content stringByAppendingString:time];
    [_showView addSubview:announcementView];
    
}

#pragma mark - VHallChatDelegate
- (void)reciveOnlineMsg:(NSArray *)msgs
{
    if (msgs.count > 0) {
        [_chatDataArray addObjectsFromArray:msgs];
        if (_chatBtn.selected) {
            [_chatView reloadData];
            [_chatView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:_chatDataArray.count-1 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
        }
    }
}

- (void)reciveChatMsg:(NSArray *)msgs
{
    if (msgs.count > 0) {
        [_chatDataArray addObjectsFromArray:msgs];
        if (_chatBtn.selected) {
            [_chatView reloadData];
            [_chatView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:_chatDataArray.count-1 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
        }
        VHallChatModel* model = [msgs objectAtIndex:0];
        BarrageDescriptor * descriptor = [[BarrageDescriptor alloc]init];
        descriptor.spriteName = NSStringFromClass([BarrageWalkImageTextSprite class]);
        descriptor.params[@"text"] = model.text;
        descriptor.params[@"textColor"] = MakeColorRGB(0xffffff);//MakeColor(random()%255, random()%255, random()%255, 1);
        //@(100 * (double)random()/RAND_MAX+50) 随机速度
        descriptor.params[@"speed"] = @(100);// 固定速度
        descriptor.params[@"direction"] = @(BarrageWalkDirectionR2L);
        descriptor.params[@"side"] = @(BarrageWalkSideDefault);
//        descriptor.params[@"clickAction"] = ^{
//            UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"提示" message:@"弹幕被点击" delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:nil];
//            [alertView show];
//        };
        [_renderer receive:descriptor];
    }
}

#pragma mark - VHallQAndADelegate
- (void)reciveQAMsg:(NSArray *)msgs
{
    if (msgs.count > 0)
    {
        VHallQAModel * qaModel = [msgs lastObject];
        if (qaModel.questionModel) {
            [_QADataArray addObject:qaModel.questionModel];
        }
        
        if (qaModel.answerModels && qaModel.answerModels.count > 0) {
            [_QADataArray addObjectsFromArray:qaModel.answerModels];
        }
        
        if (_QABtn.selected) {
            [_chatView reloadData];
        }
    }
}

#pragma mark - VHallLotteryDelegate
- (void)startLottery:(VHallStartLotteryModel *)msg
{
    if (_lotteryVC) {
        [_lotteryVC.view removeFromSuperview];
        [_lotteryVC removeFromParentViewController];
        _lotteryVC = nil;
    }
    
    _lotteryVC = [[WatchLiveLotteryViewController alloc] init];
    _lotteryVC.lottery = _lottery;
    _lotteryVC.view.frame = _showView.bounds;
    [_showView addSubview:_lotteryVC.view];
}

- (void)endLottery:(VHallEndLotteryModel *)msg
{
    if (!_lotteryVC) {
        _lotteryVC = [[WatchLiveLotteryViewController alloc] init];
        _lotteryVC.lottery = _lottery;
        _lotteryVC.view.frame = _showView.bounds;
        [_showView addSubview:_lotteryVC.view];
    }
    _lotteryVC.lotteryOver = YES;
    _lotteryVC.endLotteryModel = msg;
}

#pragma mark - VHallSignDelegate
- (void)startSign
{
//    NSLog(@"开始签到");
    __weak typeof(self) weakSelf = self;
    [SignView showSignBtnClickedBlock:^BOOL{
        [weakSelf SignBtnClicked];
        return NO;
    }];
}

- (void)SignBtnClicked
{
    __weak typeof(self) weakSelf = self;
    [_sign signSuccess:^{
      [SignView close];
      [weakSelf showMsg:@"签到成功" afterDelay:2];
    } failed:^(NSDictionary *failedData) {
        [weakSelf showMsg:[NSString stringWithFormat:@"%@,错误码%@",failedData[@"content"],failedData[@"code"]] afterDelay:2];
        [_sign cancelSign];
        [SignView close];
    }];
}

- (void)signRemainingTime:(NSTimeInterval)remainingTime
{
//    NSLog(@"距结束%d秒",(int)remainingTime);
    [SignView remainingTime:remainingTime];
}

- (void)stopSign
{   [SignView close];
    [self showMsg:@"签到结束" afterDelay:2];
}

#pragma mark 问卷调查delegate
-(void)receiveSurveryMsgs:(NSArray*)msgs
{
    if (msgs.count > 0) {
        [_chatDataArray addObjectsFromArray:msgs];
        if (_chatBtn.selected) {
            [_chatView reloadData];
            [_chatView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:_chatDataArray.count-1 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
        }
    }
}

#pragma mark - UIPanGestureRecognizer
-(void)handlePan:(UIPanGestureRecognizer*)pan
{
    float baseY = 200.0f;
    CGPoint translation = CGPointZero;
    static float volumeSize = 0.0f;
    CGPoint currentLocation = [pan translationInView:self.view];
    if (pan.state == UIGestureRecognizerStateBegan)
    {
        translation = [pan translationInView:self.view];
        volumeSize = [VHallMoviePlayer getSysVolumeSize];
    }else if(pan.state == UIGestureRecognizerStateChanged)
    {
        float y = currentLocation.y-translation.y;
        float changeSize = ABS(y)/baseY;
        if (y>0){
            [VHallMoviePlayer setSysVolumeSize:volumeSize-changeSize];
        }else{
            [VHallMoviePlayer setSysVolumeSize:volumeSize+changeSize];
        }
    }
}

#pragma mark - ObserveValueForKeyPath
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if([keyPath isEqualToString:kViewFramePath])
    {
        _moviePlayer.moviePlayerView.frame = self.backView.bounds;
        _logView.frame = _moviePlayer.moviePlayerView.bounds;
        _lotteryVC.view.frame = _showView.bounds;
        [SignView layoutView:self.view.bounds];
    }
}

- (void)outputDeviceChanged:(NSNotification*)notification
{
    NSInteger routeChangeReason = [[[notification userInfo]objectForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
    switch (routeChangeReason)
    {
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
        {
            VHLog(@"AVAudioSessionRouteChangeReasonNewDeviceAvailable");
            VHLog(@"Headphone/Line plugged in");
        }
            break;
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
        {
            VHLog(@"AVAudioSessionRouteChangeReasonOldDeviceUnavailable");
            VHLog(@"Headphone/Line was pulled. Stopping player....");
            dispatch_async(dispatch_get_main_queue(), ^{

            });
        }
            break;
        case AVAudioSessionRouteChangeReasonCategoryChange:
        {
            // called at start - also when other audio wants to play
            VHLog(@"AVAudioSessionRouteChangeReasonCategoryChange");
        }
            break;
        default:
            break;
    }
}




-(void)didBecomeActive
{
    
    
    NSString *content =nil;
    NSString *time =nil;
    if (announcementContentDic !=nil)
    {
        content =[ announcementContentDic objectForKey:@"announceContent"];
        time =[announcementContentDic    objectForKey:@"announceTime"];
    }
    
    if(announcementView !=nil)
    {
        [announcementView setContent:[content stringByAppendingString:time]];
        
    }
    
    
}


#pragma mark - 详情
- (IBAction)detailsButtonClick:(UIButton *)sender {
    self.textImageView.hidden = YES;
    self.chatView.hidden = YES;
    self.detailBtn.selected = YES;
    self.docBtn.selected = NO;
    self.chatBtn.selected = NO;
    self.QABtn.selected = NO;
    
    
    
    [self.detailBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [self.docBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.chatBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.QABtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
}

#pragma mark - 文档
- (IBAction)textButtonClick:(UIButton *)sender {
    self.textImageView.hidden = NO;
    self.chatView.hidden = YES;
    self.detailBtn.selected = NO;
    self.docBtn.selected = YES;
    self.chatBtn.selected = NO;
    self.QABtn.selected = NO;
    
    
    [self.detailBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.docBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [self.chatBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.QABtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];

}

#pragma mark - 聊天
- (IBAction)chatButtonClick:(UIButton *)sender {
    self.textImageView.hidden = YES;
    self.chatView.hidden = NO;
    self.detailBtn.selected = NO;
    self.docBtn.selected = NO;
    self.chatBtn.selected = YES;
    self.QABtn.selected = NO;
    
    
    
    [self.detailBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.docBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.chatBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [self.QABtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    
    
    [_chatView reloadData];
    
    if (!_isReciveHistory)
    {
        __weak typeof(self) ws = self;
        [_chat getHistoryWithType:YES success:^(NSArray * msgs) {
            
            if (msgs.count > 0) {
                [ws.chatDataArray addObjectsFromArray:msgs];
                if (ws.chatBtn.selected) {
                    [ws.chatView reloadData];
                    [ws.chatView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:ws.chatDataArray.count-1 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
                }
            }
            
        } failed:^(NSDictionary *failedData) {
            
            NSString* code = [NSString stringWithFormat:@"%@,%@", failedData[@"content"], failedData[@"code"]];
            [ws showMsg:code afterDelay:1.5];
//            [UIAlertView popupAlertByDelegate:nil title:failedData[@"content"] message:code];
            
        }];
        _isReciveHistory = YES;
    }
}

#pragma mark - 问答
- (IBAction)QAButtonClick:(UIButton *)sender {
    self.textImageView.hidden = YES;
    self.chatView.hidden = NO;
    self.detailBtn.selected = NO;
    self.docBtn.selected = NO;
    self.chatBtn.selected = NO;
    self.QABtn.selected = YES;
    
    
    [self.detailBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.docBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.chatBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.QABtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    
    [_chatView reloadData];
}

#pragma mark -
-(void)alertWithMessage:(VHMovieVideoPlayMode)state
{
    NSString*message = nil;
    switch (state) {
        case VHMovieVideoPlayModeNone:
            message = @"无内容";
            break;
        case VHMovieVideoPlayModeMedia:
            message = @"纯视频";
            break;
        case VHMovieVideoPlayModeTextAndVoice:
            message = @"文档＋声音";
            break;
        case VHMovieVideoPlayModeTextAndMedia:
            message = @"文档＋视频";
            break;

        default:
            break;
    }
//    UIAlertView*alert = [[UIAlertView alloc]initWithTitle:@"提示" message:message delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
//    [alert show];
    [self showMsg:message afterDelay:1];
}


- (IBAction)definitionBtnCLicked:(UIButton *)sender {
    if(!_startAndStopBtn.selected)return;
    
    int _leve = _moviePlayer.curDefinition + 1;
    if (_leve==4) {
        _leve=0;
    }
    [MBProgressHUD hideHUDForView:_moviePlayer.moviePlayerView animated:NO];
    [MBProgressHUD showHUDAddedTo:_moviePlayer.moviePlayerView animated:YES];
    [_moviePlayer setCurDefinition:_leve];
    _leve = _moviePlayer.curDefinition;
    _playModeBtn0.selected = NO;
    [_definitionBtn0 setImage:[UIImage imageNamed:_videoLevePicArray[_moviePlayer.curDefinition]] forState:UIControlStateNormal];
    _playModelTemp=_moviePlayer.playMode;
}

- (IBAction)playModeBtnCLicked:(UIButton *)sender {
    if(!_startAndStopBtn.selected)return;
    UIButton *btn =(UIButton*)sender;
    btn.selected = !sender.selected;
    if (btn.selected)
    {
        _playModelTemp=VHMovieVideoPlayModeVoice;
        _playModeBtn0.selected = YES;
//        [_playModeBtn0 setImage:[UIImage imageNamed:_videoPlayModelPicArray[1]] forState:UIControlStateNormal];
    }else
    {
        _playModeBtn0.selected = NO;
        _playModelTemp=VHMovieVideoPlayModeMedia;
//        [_playModeBtn0 setImage:[UIImage imageNamed:_videoPlayModelPicArray[0]] forState:UIControlStateNormal];
    }
    
    
    [MBProgressHUD hideHUDForView:_moviePlayer.moviePlayerView animated:NO];
    [MBProgressHUD showHUDAddedTo:_moviePlayer.moviePlayerView animated:YES];
    if (_playModelTemp == VHMovieVideoPlayModeVoice ||_playModelTemp == VHMovieVideoPlayModeTextAndVoice) {
        [_moviePlayer setCurDefinition:VHMovieDefinitionAudio];
        _logView.hidden=NO;
        self.liveTypeLabel.text = @"语音直播中";
    }
    else {
        [_moviePlayer setCurDefinition:VHMovieDefinitionOrigin];
        _logView.hidden=YES;
        _definitionBtn0.hidden = NO;
        self.liveTypeLabel.text = @"";
    }
    [_definitionBtn0 setImage:[UIImage imageNamed:_videoLevePicArray[_moviePlayer.curDefinition]] forState:UIControlStateNormal];
}

#pragma mark 弹幕开关
- (IBAction)barrageBtnClick:(id)sender
{
//    UIButton *btn = (UIButton*)sender;
//    btn.selected = !btn.selected;
    
    _rendererOpenBtn.selected = !_rendererOpenBtn.selected;
    if (_rendererOpenBtn.selected)
    {
        [_renderer start];
      
    }else
    {
        [_renderer stop];
    }
}

#pragma mark 陀螺开关

- (IBAction)startGyroClick:(id)sender
{
    UIButton *btn = (UIButton*)sender;
    btn.selected = !btn.selected;
    if (btn.selected)
    {
        [_moviePlayer setUsingGyro:YES];
    }else
    {
        [_moviePlayer setUsingGyro:NO];
    }
    
}

#pragma mark messageToolViewDelegate
- (void)didSendText:(NSString *)text
{
    if (_chatBtn.selected == YES) {
        
        [_chat sendMsg:text success:^{
            
        } failed:^(NSDictionary *failedData) {
            
            NSString* code = [NSString stringWithFormat:@"%@", failedData[@"code"]];
            [UIAlertView popupAlertByDelegate:nil title:failedData[@"content"] message:code];
            
        }];
        
        return;
    }
    
    if (_QABtn.selected == YES) {
        
        [_QA sendMsg:text success:^{
        } failed:^(NSDictionary *failedData) {
            
            NSString* code = [NSString stringWithFormat:@"%@", failedData[@"code"]];
            [UIAlertView popupAlertByDelegate:nil title:failedData[@"content"] message:code];
            
        }];
        
        return;
    }
}

- (IBAction)fullscreenBtnClicked:(UIButton*)sender {

    _fullScreentBtnClick =YES;
    if(_fullscreenBtn.isSelected)
    {//退出全屏
        [self rotateScreen:NO];
    }
    else
    {//全屏
        [self rotateScreen:YES];
    }
}

- (void)rotateScreen:(BOOL)isLandscapeRight
{
    if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)])
    {
        NSNumber *num = [[NSNumber alloc] initWithInt:(isLandscapeRight?UIInterfaceOrientationLandscapeRight:UIInterfaceOrientationPortrait)];
        [[UIDevice currentDevice] performSelector:@selector(setOrientation:) withObject:(id)num];
        [UIViewController attemptRotationToDeviceOrientation];
        //这行代码是关键
    }
    SEL selector=NSSelectorFromString(@"setOrientation:");
    NSInvocation *invocation =[NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:selector]];
    [invocation setSelector:selector];
    [invocation setTarget:[UIDevice currentDevice]];
    int val =isLandscapeRight?UIInterfaceOrientationLandscapeRight:UIInterfaceOrientationPortrait;
    [invocation setArgument:&val atIndex:2];
    [invocation invoke];
    [[UIApplication sharedApplication] setStatusBarHidden:isLandscapeRight withAnimation:UIStatusBarAnimationSlide];
}

-(UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleBlackTranslucent;
}
@end
