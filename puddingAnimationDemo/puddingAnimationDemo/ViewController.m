//
//  ViewController.m
//  puddingAnimationDemo
//
//  Created by 叶杨 on 16/3/16.
//  Copyright © 2016年 叶景天. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()


//布丁的layer
@property (nonatomic, strong)CAShapeLayer *shapeLayer;


//布丁的贝塞尔曲线控制原点(屏幕的中心点)
@property (nonatomic, assign)CGPoint originalPoint;

//定时器,监控手势变化
@property (nonatomic, strong)CADisplayLink *displayLink;

@property (nonatomic, strong)UIView *pointView;
@end

#define  SCREEN_WIDTH      [UIScreen mainScreen].bounds.size.width

#define  SCREEN_HRIGHT  [UIScreen mainScreen].bounds.size.height



@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.originalPoint = self.view.center;
    
    //上一篇博文,我们用了shapeLayer这次我们再详细讲解一下shapeLayer,CAShapeLayer是CALayer的子类,如果你初始化了一个CALayer就必须给他一个frame,但是他此时并没有形状,你必须为他执行一个path,为CAShapeLayer塑形,我们来看下面的用法
    self.shapeLayer = [CAShapeLayer layer];
    self.shapeLayer.frame = self.view.bounds;
    self.shapeLayer.fillColor = [UIColor yellowColor].CGColor;
    //现在我们为他指定一个path,为了解耦,我们用另外写一个方法给他
    self.shapeLayer.path = [self caculatePathWithPoint:self.originalPoint].CGPath;
    //将它添加到self.view.layer上
    [self.view.layer addSublayer:self.shapeLayer];
    
    //这里我为了使大伙看得到控制视图,所以把它弄大了,且设置背景颜色为蓝色,真正做效果的时候,最好设置Rect为(0,0,4,4)或者更小也可以
    self.pointView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 30, 30)];
    self.pointView.layer.backgroundColor = [UIColor blueColor].CGColor;
    
    self.pointView.center = self.view.center;
    
    [self.view addSubview:self.pointView];
    
    //接下来我们要为self.view添加一个平移手势
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panGestureRecognizerAction:)];
    [self.view addGestureRecognizer:panGesture];
    
    //仅仅是手势还不够,我们需要有一个定时,监测手势的变化,然后改变布丁的形状,在这里我们我们不用NSTimer我们用UIDisplayLinker,这个类是专门用来改变Layer形状的,每秒60帧,且不会使卡顿,
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkEvent:)];
    [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    //好了,接下来我们就是要重点处理平移手势了
    
}

- (void)displayLinkEvent: (CADisplayLink *)displayLink
{

    CALayer *layer = self.pointView.layer.presentationLayer;
    
    //这里详解一下presentationLayer和self.pointView.layer的区别,例如,如果你设置一个弹簧动画,直接设置了self.pointView.layer.position = self.view.center那么self.pointView.layer.position在数值上就会立刻变成self.view.center,注意这里是在数值上,因为你是在弹簧效果,所以他在屏幕上的position并不会立刻编程self.view.center,所以这时候就需要presentationLayer进行判断它在屏幕上的位置
    
    //不能这么写
//    self.shapeLayer.path = [self caculatePathWithPoint:self.pointView.layer.position].CGPath;
    self.shapeLayer.path = [self caculatePathWithPoint:layer.position].CGPath;
}

//平移手势
- (void)panGestureRecognizerAction:(UIPanGestureRecognizer *)panGesture
{
    //平移手势是做动画当中重中之中的手势,一些炫酷的动画基本上都是通过这几种方式叠加做成的.1.手势 2.定时器 3. CoreAnimation ,反而算法并没有占多重要,一些看似复杂的动画都是由几个简单的动画叠加做成的,使之看起来很复杂
    
    CGPoint point = [panGesture locationInView:panGesture.view];
    
    //这是个人计算的,弯曲得最好看的参数设置方法,如觉得不好看也可以微调
    CGPoint caculatePoint = CGPointMake((point.x + SCREEN_WIDTH / 2) / 2.f, (point.y + SCREEN_HRIGHT / 2) / 2.f);
    //接下来判断手势的状态
    if (panGesture.state == UIGestureRecognizerStateChanged) {
        self.shapeLayer.path = [self caculatePathWithPoint:caculatePoint].CGPath;
        self.pointView.center = caculatePoint;

    }else if (panGesture.state == UIGestureRecognizerStateCancelled ||
              panGesture.state == UIGestureRecognizerStateEnded ||
              panGesture.state == UIGestureRecognizerStateFailed) {
        
        [UIView animateWithDuration:1.0 delay:0.0 usingSpringWithDamping:0.25f initialSpringVelocity:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             self.pointView.center = self.view.center;
                             
                         } completion:nil];
    }

}

//通过point改变布丁的形状
- (UIBezierPath *)caculatePathWithPoint: (CGPoint)point
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    
    //绘制一个为屏幕竖直二分之一大小的矩形
    [path moveToPoint:CGPointMake(0, SCREEN_HRIGHT / 2.f)];
    [path addLineToPoint:CGPointMake(0, SCREEN_HRIGHT)];
    [path addLineToPoint:CGPointMake(SCREEN_WIDTH, SCREEN_HRIGHT)];
    [path addLineToPoint:CGPointMake(SCREEN_WIDTH, SCREEN_HRIGHT / 2)];
    
    //接下来的就是重点了,我们需要绘制布丁的最上层的曲线,那么就需要一个controlPoint
    [path addQuadCurveToPoint:CGPointMake(0, SCREEN_HRIGHT / 2) controlPoint:point];
    return path;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
