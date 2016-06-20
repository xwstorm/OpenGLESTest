//
//  ViewController.m
//  HelloOpenGL
//
//  Created by Leelen-mac1 on 14-3-21.
//  Copyright (c) 2014年 Leelen. All rights reserved.
//

#import "ViewController.h"
#import "OpenGLView.h"
@interface ViewController ()
@property (nonatomic, strong)OpenGLView *glView;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.glView = [[OpenGLView alloc] initWithFrame:self.view.frame];
    [self.view addSubview:self.glView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
