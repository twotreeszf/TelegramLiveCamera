//
//  TCExportQRVC.m
//  TelegramLiveCamera
//
//  Created by fanzhang on 2020年4月27日  18周Monday.
//  Copyright © 2020 twotrees. All rights reserved.
//

#import "TCExportQRVC.h"
#import <Masonry/Masonry.h>

@interface TCExportQRVC ()

@end

@implementation TCExportQRVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIImageView* imageView = [UIImageView new];
    imageView.image = _image;
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:imageView];
    
    [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
        CGFloat width = MIN(self.view.bounds.size.width, self.view.bounds.size.height);
        make.width.equalTo(@(width));
        make.height.equalTo(@(width));
    }];
}

@end
