#import <UIKit/UIKit.h>
#import <Contacts/Contacts.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import <WebKit/WebKit.h>

// ====== إعدادات التهيئة ======
#define DEBUG_MODE 1                // وضع التصحيح
#define ENABLE_LOCATION_SPOOF 1     // تزييف الموقع
#define ENABLE_NUMBER_LOOKUP 1      // بحث الأرقام
#define ENABLE_HIDE_CHATS 1         // إخفاء المحادثات
#define ENABLE_CUSTOM_FONTS 1       // الخطوط المخصصة

// ====== بيانات الاختبار ======
static NSDictionary *testNumbers = @{
    @"966501234567": @{@"name": @"محمد أحمد (تجربة)", @"carrier": @"STC"},
    @"966502345678": @{@"name": @"شركة النهدي (تجربة)", @"carrier": @"موبايلي"}
};

static NSDictionary *savedLocations = @{
    @"الرياض": @{@"lat": @24.7136, @"lng": @46.6753},
    @"جدة": @{@"lat": @21.5433, @"lng": @39.1728}
};

// ====== الفئات المخصصة والواجهات ======
@interface DevLandSettings : NSObject
+ (instancetype)shared;
@property (assign, nonatomic) BOOL fakeLocationEnabled;
@property (assign, nonatomic) CLLocationCoordinate2D customLocation;
@property (strong, nonatomic) NSString *currentFont;
@property (assign, nonatomic) BOOL chatsHidden;
@end

@interface WAChatViewController : UIViewController
@end

@interface WAContactCell : UITableViewCell
@property (nonatomic, strong) NSString *phoneNumber;
- (void)setupLookupButton;
- (void)devLand_handleLookup;
- (void)saveTestContact:(NSString *)name number:(NSString *)number;
- (void)sendLocation;
@end

// ====== التنفيذ الرئيسي ======
%hook WAChatViewController

// MARK: - إخفاء المحادثات
- (void)viewWillAppear:(BOOL)animated {
    %orig;
    
    #if ENABLE_HIDE_CHATS
    if ([DevLandSettings shared].chatsHidden) {
        self.view.alpha = 0.3; // تأثير شفافية
    }
    #endif
}

%end

%hook WAContactCell

// MARK: - زر البحث
- (void)layoutSubviews {
    %orig;
    
    #if ENABLE_NUMBER_LOOKUP
    [self setupLookupButton];
    #endif
}

%new
- (void)setupLookupButton {
    static UIButton *btn;
    if (!btn) {
        btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn setImage:[UIImage systemImageNamed:@"magnifyingglass"] forState:UIControlStateNormal];
        btn.frame = CGRectMake(self.frame.size.width - 50, 10, 30, 30);
        [btn addTarget:self action:@selector(devLand_handleLookup) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:btn];
    }
}

%new
- (void)devLand_handleLookup {
    NSString *number = [[self.phoneNumber componentsSeparatedByCharactersInSet:
                       [[NSCharacterSet decimalDigitCharacterSet] invertedSet]] 
                       componentsJoinedByString:@""];
    
    NSDictionary *result = testNumbers[number] ?: @{@"name": @"غير معروف", @"carrier": @"N/A"};
    
    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:@"نتيجة البحث (تجريبية)"
        message:[NSString stringWithFormat:@"الاسم: %@\nالشركة: %@", result[@"name"], result[@"carrier"]]
        preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"حفظ" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self saveTestContact:result[@"name"] number:number];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"إلغاء" style:UIAlertActionStyleCancel handler:nil]];
    
    UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    [rootVC presentViewController:alert animated:YES completion:nil];
}

%new
- (void)saveTestContact:(NSString *)name number:(NSString *)number {
    NSLog(@"[DevLand] حفظ جهة اتصال تجريبية: %@ - %@", name, number);
}

// MARK: - تزييف الموقع
#if ENABLE_LOCATION_SPOOF
- (void)sendLocation {
    if ([DevLandSettings shared].fakeLocationEnabled) {
        CLLocationCoordinate2D fakeLoc = [DevLandSettings shared].customLocation;
        
        // هنا كود إرسال الموقع المزيف
        NSLog(@"[DevLand] إرسال موقع مزيف: (%f, %f)", fakeLoc.latitude, fakeLoc.longitude);
        
        return; // لا ترسل الموقع الحقيقي
    }
    %orig;
}
#endif

%end

// MARK: - الخطوط المخصصة
#if ENABLE_CUSTOM_FONTS
%hook UIFont

+ (UIFont *)systemFontOfSize:(CGFloat)size {
    if ([DevLandSettings shared].currentFont) {
        return [UIFont fontWithName:[DevLandSettings shared].currentFont size:size];
    }
    return %orig;
}

%end
#endif

// ====== الإعدادات والتهيئة ======
%ctor {
    NSLog(@"[DevLand] تم تحميل التويك بنجاح!");
    
    // تهيئة الإعدادات الافتراضية
    [DevLandSettings shared].fakeLocationEnabled = YES;
    [DevLandSettings shared].customLocation = CLLocationCoordinate2DMake(24.7136, 46.6753);
    [DevLandSettings shared].currentFont = @"ArialArabic-Bold";
    [DevLandSettings shared].chatsHidden = NO;
    
    #if DEBUG_MODE
    NSLog(@"[DevLand] الإعدادات الافتراضية:");
    NSLog(@"- تزييف الموقع: %@", [DevLandSettings shared].fakeLocationEnabled ? @"مفعل" : @"معطل");
    NSLog(@"- الخط الحالي: %@", [DevLandSettings shared].currentFont);
    #endif
}
