//
//  KSYPlayerSubtitleView.m
//
//  Created by 施雪梅 on 17/7/12.
//  Copyright © 2017年 ksyun. All rights reserved.
//

#import "KSYPlayerSubtitleView.h"

@interface KSYPlayerSubtitleView()<UITableViewDelegate,UITableViewDataSource,UITextFieldDelegate,UIGestureRecognizerDelegate>{
    UILabel *_labelColor;
    UILabel *_labelFont;
    
    NSMutableArray *_colorArray;
    NSMutableArray *_colorPosArray;
    
    NSArray *_fontArray;
    NSMutableArray *_fontPosArray;
    
    UILabel *_labelSubtitle;
    
    UIButton *_btnCloseSubtitle;
    UIButton *_btnOpenSubtitleFile;
    UITableView *_tableSubtitle;
    
    NSMutableArray *_extSubtitleFiles;
    
    NSString *_documentDir;
    
    
}
@end

@implementation KSYPlayerSubtitleView

- (id)init{
    self = [super init];
    
    _colorArray = [NSMutableArray array];
    _colorPosArray = [NSMutableArray array];
    for (int i = 0; i < 5; i++) {
        UIColor *color = [UIColor colorWithHue:i / (float)5 saturation:1.0 brightness:1.0 alpha:1.0];
        [_colorArray addObject:color];
    }
    
    _fontArray = [[NSArray alloc] initWithObjects:@"Georgia-Italic", @"Times New Roman", @"Zapfino", nil];
    _fontPosArray = [NSMutableArray array];
    
    _documentDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    _extSubtitleFiles = [NSMutableArray array];
    NSError *error = nil;
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:_documentDir error:&error];
    for (NSString *fileName in files) {
        if([fileName hasSuffix:@".srt"] || [fileName hasSuffix:@".ass"])
            [_extSubtitleFiles addObject:fileName];
    }
    
    [self setupUI];
    
    UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(colorGridTapped:)];
    recognizer.delegate = self;
    [self addGestureRecognizer:recognizer];
    
    return self;
}

- (void) setupUI {
    _sliderFontSize =  [self addSliderName:@"大小" From:12 To:20 Init:16];
    _labelColor =  [self addLable:@"颜色"];
    _labelFont = [self addLable:@"字体"];
    _labelSubtitle = [self addLable:@"切换内嵌字幕"];
    _btnCloseSubtitle = [self addButton:@"关闭字幕"];
    _btnOpenSubtitleFile = [self addButton:@"打开本地字幕文件"];
    
    _tableSubtitle= [[UITableView alloc]init];
    _tableSubtitle.delegate   = self;
    _tableSubtitle.dataSource = self;
    [self addSubview:_tableSubtitle];
    
    [self layoutUI];
}

- (void)layoutUI{
    [super layoutUI];
    self.yPos = 0;
    
    [self putNarrow:_labelColor andWide:nil];
    
    for (int i = 0; i < _colorArray.count; i++) {
        UILabel *label = [[UILabel alloc] init];
        label.backgroundColor = [_colorArray objectAtIndex:i];
        float elemWidth = (self.frame.size.width -  CGRectGetMaxX(_labelColor.frame) - (_colorArray.count + 1) * self.gap)  / (_colorArray.count);
        if(elemWidth > 0)
        {
            CGRect rect = CGRectMake(CGRectGetMaxX(_labelColor.frame) + self.gap + i * (elemWidth + self.gap), CGRectGetMinY(_labelColor.frame), elemWidth, self.btnH);
            label.frame = rect;
            [_colorPosArray addObject:[NSValue valueWithCGRect:rect]];
        }
        
        [self addSubview:label];
    }
    
    [self putNarrow:_labelFont andWide:nil];
    
    for (int i = 0; i < _fontArray.count; i++) {
        UILabel *label = [[UILabel alloc] init];
        label.backgroundColor = [UIColor whiteColor];
        label.text = [_fontArray objectAtIndex:i];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont fontWithName:label.text size:12];
        float elemWidth = (self.frame.size.width -  CGRectGetMaxX(_labelColor.frame) - (_fontArray.count + 1) * self.gap)  / (_fontArray.count);
        if(elemWidth > 0)
        {
            CGRect rect = CGRectMake(CGRectGetMaxX(_labelFont.frame) + self.gap + i * (elemWidth + self.gap), CGRectGetMinY(_labelFont.frame), elemWidth, self.btnH);
            label.frame = rect;
            [_fontPosArray addObject:[NSValue valueWithCGRect:rect]];
        }
        
        [self addSubview:label];
    }
    
    [self putRow1:_sliderFontSize];
    
    if(_subtitleNumBlock)
        _subtitleNumBlock();
    if(_subtitleNum > 0)
    {
        NSMutableArray *subtitleItem = [NSMutableArray array];
        for(int i = 0; i < _subtitleNum; i++)
        {
            NSString *name  = [NSString stringWithFormat:@"字幕%d", i+1];
            [subtitleItem addObject:name];
        }
        _segSubtitle = [self addSegCtrlWithItems:subtitleItem];
        _segSubtitle.selectedSegmentIndex = _selectedSubtitleIndex;
        [self putLable:_labelSubtitle andView:_segSubtitle];
    }
    [self putRow1:_btnCloseSubtitle];
    [self putRow1:_btnOpenSubtitleFile];
    
    _btnCloseSubtitle.selected = NO;
    _btnOpenSubtitleFile.selected = NO;
    float yPos = CGRectGetMaxY(_btnOpenSubtitleFile.frame) + self.gap;
    _tableSubtitle.frame = CGRectMake(0, yPos, self.width, (self.height - yPos) / 2);
    _tableSubtitle.backgroundColor = [UIColor grayColor];
    _tableSubtitle.hidden = YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    // 若为UITableViewCellContentView（即点击了tableViewCell），则不截获Touch事件
    if ([NSStringFromClass([touch.view class]) isEqualToString:@"UITableViewCellContentView"]) {
        return NO;
    }
    return  YES;
}

- (void) colorGridTapped:(UITapGestureRecognizer *)recognizer {
    CGPoint point = [recognizer locationInView:self];
    
    CGRect pos = [[_colorPosArray objectAtIndex:0] CGRectValue];
    if(point.y >= pos.origin.y && point.y <= pos.origin.y + pos.size.height)
    {
        for (int i = 0; i < _colorArray.count; i++) {
            pos = [[_colorPosArray objectAtIndex:i] CGRectValue];
            if(point.x >= pos.origin.x && point.x <=  pos.origin.x + pos.size.width)
            {
                if(_fontColorBlock)
                    _fontColorBlock(_colorArray[i]);
                return ;
            }
        }
    }
    
    pos = [[_fontPosArray objectAtIndex:0] CGRectValue];
    if(point.y >= pos.origin.y && point.y <= pos.origin.y + pos.size.height)
    {
        for (int i = 0; i < _fontArray.count; i++) {
            pos = [[_fontPosArray objectAtIndex:i] CGRectValue];
            if(point.x >= pos.origin.x && point.x <=  pos.origin.x + pos.size.width)
            {
                if(_fontBlock)
                    _fontBlock(_fontArray[i]);
                return ;
            }
        }
    }
}

- (void)onBtn:(id)sender {
    if(sender == _btnOpenSubtitleFile)
    {
        _btnOpenSubtitleFile.selected = !_btnOpenSubtitleFile.selected;
        _tableSubtitle.hidden = !_tableSubtitle.hidden;
    }
    else if(sender == _btnCloseSubtitle)
    {
        _tableSubtitle.hidden = YES;
        _btnOpenSubtitleFile.selected = NO;
        if(_closeSubtitleBlock)
            _closeSubtitleBlock();
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
        return _extSubtitleFiles.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"abc"];
    if (nil == cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"abc"];
        cell.textLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    }
    
    cell.textLabel.text = _extSubtitleFiles[indexPath.row];
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.backgroundColor = [UIColor grayColor];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if(_subtitleFileSelectedBlock)
        _subtitleFileSelectedBlock([NSString stringWithFormat:@"%@%s%@", _documentDir, "/", _extSubtitleFiles[indexPath.row]]);
}

@end
