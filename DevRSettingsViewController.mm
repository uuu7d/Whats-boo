#import <UIKit/UIKit.h>
#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

// ====== تعريف الواجهة مباشرة لتفادي الحاجة لملف .h منفصل ======
@interface DevRSettingsViewController : PSListController <MKMapViewDelegate>
@property (nonatomic, strong) MKMapView *mapView;
@property (nonatomic, strong) UISwitch *locationSpoofSwitch;
@property (nonatomic, strong) UISwitch *hideChatsSwitch;
@property (nonatomic, strong) NSArray *fontsList;
@property (nonatomic, strong) NSString *selectedFont;
@end

// ====== واجهة كلاس الإعدادات ======
@interface DevLandSettings : NSObject
+ (instancetype)shared;
@property (assign, nonatomic) BOOL fakeLocationEnabled;
@property (assign, nonatomic) CLLocationCoordinate2D customLocation;
@property (strong, nonatomic) NSString *currentFont;
@property (assign, nonatomic) BOOL chatsHidden;
@end

@implementation DevRSettingsViewController

- (NSArray *)specifiers {
    if (!_specifiers) {
        NSMutableArray *specifiers = [NSMutableArray new];
        
        // ====== قسم تزييف الموقع ======
        PSSpecifier *locationGroup = [PSSpecifier groupSpecifierWithName:@"إعدادات الموقع"];
        [specifiers addObject:locationGroup];
        
        PSSpecifier *spoofSwitch = [PSSpecifier preferenceSpecifierNamed:@"تفعيل تزييف الموقع"
                                    target:self
                                    set:@selector(setPreferenceValue:specifier:)
                                    get:@selector(readPreferenceValue:)
                                    detail:nil
                                    cell:PSSwitchCell
                                    edit:nil];
        spoofSwitch.properties[@"key"] = @"enableLocationSpoof";
        [specifiers addObject:spoofSwitch];
        
        PSSpecifier *mapSpecifier = [PSSpecifier preferenceSpecifierNamed:@"تحديد الموقع المزيف"
                                      target:self
                                      set:nil
                                      get:nil
                                      detail:nil
                                      cell:PSLinkCell
                                      edit:nil];
        [mapSpecifier setProperty:NSStringFromSelector(@selector(showMapView)) forKey:@"action"];
        [specifiers addObject:mapSpecifier];
        
        // ====== قسم إدارة المحادثات ======
        PSSpecifier *chatsGroup = [PSSpecifier groupSpecifierWithName:@"إدارة المحادثات"];
        [specifiers addObject:chatsGroup];
        
        PSSpecifier *hideChatsSwitch = [PSSpecifier preferenceSpecifierNamed:@"إخفاء المحادثات"
                                        target:self
                                        set:@selector(setPreferenceValue:specifier:)
                                        get:@selector(readPreferenceValue:)
                                        detail:nil
                                        cell:PSSwitchCell
                                        edit:nil];
        hideChatsSwitch.properties[@"key"] = @"hideChats";
        [specifiers addObject:hideChatsSwitch];
        
        PSSpecifier *gestureInfo = [PSSpecifier preferenceSpecifierNamed:@"اضغط مرتين لإخفاء/إظهار"
                                     target:self
                                     set:nil
                                     get:nil
                                     detail:nil
                                     cell:PSStaticTextCell
                                     edit:nil];
        [specifiers addObject:gestureInfo];
        
        // ====== قسم المظهر ======
        PSSpecifier *appearanceGroup = [PSSpecifier groupSpecifierWithName:@"المظهر"];
        [specifiers addObject:appearanceGroup];
        
        PSSpecifier *fontSelector = [PSSpecifier preferenceSpecifierNamed:@"اختيار الخط"
                                      target:self
                                      set:@selector(setSelectedFont:specifier:)
                                      get:@selector(getSelectedFont)
                                      detail:NSClassFromString(@"PSListItemsController")
                                      cell:PSLinkListCell
                                      edit:nil];
        fontSelector.properties[@"key"] = @"selectedFont";
        fontSelector.properties[@"values"] = @[@"ArialArabic-Bold", @"Dubai-Regular", @"GeezaPro-Bold"];
        fontSelector.properties[@"titles"] = @[@"عريض", @"دبي", @"جيزا"];
        [specifiers addObject:fontSelector];
        
        _specifiers = specifiers;
    }
    return _specifiers;
}

// ====== عرض خريطة تحديد الموقع ======
- (void)showMapView {
    UIViewController *mapVC = [UIViewController new];
    mapVC.title = @"حدد موقعك المزيف";
    
    self.mapView = [[MKMapView alloc] initWithFrame:mapVC.view.bounds];
    self.mapView.delegate = self;
    self.mapView.showsUserLocation = YES;
    self.mapView.userInteractionEnabled = YES;
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    longPress.minimumPressDuration = 0.5;
    [self.mapView addGestureRecognizer:longPress];
    
    UIButton *confirmButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [confirmButton setTitle:@"تأكيد الموقع" forState:UIControlStateNormal];
    [confirmButton addTarget:self action:@selector(confirmLocation) forControlEvents:UIControlEventTouchUpInside];
    confirmButton.frame = CGRectMake(20, mapVC.view.frame.size.height - 80, mapVC.view.frame.size.width - 40, 50);
    confirmButton.backgroundColor = [UIColor systemBlueColor];
    confirmButton.layer.cornerRadius = 10;
    [confirmButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    [mapVC.view addSubview:self.mapView];
    [mapVC.view addSubview:confirmButton];
    
    [self.navigationController pushViewController:mapVC animated:YES];
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        CGPoint touchPoint = [gestureRecognizer locationInView:self.mapView];
        CLLocationCoordinate2D coordinate = [self.mapView convertPoint:touchPoint toCoordinateFromView:self.mapView];
        
        NSMutableArray *toRemove = [NSMutableArray new];
        for (id<MKAnnotation> ann in self.mapView.annotations) {
            if ([ann isKindOfClass:[MKPointAnnotation class]]) {
                [toRemove addObject:ann];
            }
        }
        [self.mapView removeAnnotations:toRemove];
        
        MKPointAnnotation *annotation = [MKPointAnnotation new];
        annotation.coordinate = coordinate;
        annotation.title = @"الموقع المزيف";
        [self.mapView addAnnotation:annotation];
    }
}

- (void)confirmLocation {
    MKPointAnnotation *selectedAnnotation = nil;
    for (id<MKAnnotation> annotation in self.mapView.annotations) {
        if ([annotation isKindOfClass:[MKPointAnnotation class]]) {
            selectedAnnotation = (MKPointAnnotation *)annotation;
            break;
        }
    }
    
    if (selectedAnnotation) {
        [[DevLandSettings shared] setCustomLocation:selectedAnnotation.coordinate];
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setDouble:selectedAnnotation.coordinate.latitude forKey:@"fakeLocationLat"];
        [defaults setDouble:selectedAnnotation.coordinate.longitude forKey:@"fakeLocationLng"];
        [defaults synchronize];
        
        [self.navigationController popViewControllerAnimated:YES];
    }
}

// ====== إدارة التفضيلات ======
- (id)readPreferenceValue:(PSSpecifier*)specifier {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *key = specifier.properties[@"key"];
    
    if ([key isEqualToString:@"enableLocationSpoof"]) {
        return @([defaults boolForKey:key] ?: YES);
    }
    else if ([key isEqualToString:@"hideChats"]) {
        return @([defaults boolForKey:key] ?: NO);
    }
    return nil;
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *key = specifier.properties[@"key"];
    
    if ([key isEqualToString:@"enableLocationSpoof"]) {
        [defaults setBool:[value boolValue] forKey:key];
        [[DevLandSettings shared] setFakeLocationEnabled:[value boolValue]];
    }
    else if ([key isEqualToString:@"hideChats"]) {
        [defaults setBool:[value boolValue] forKey:key];
        [[DevLandSettings shared] setChatsHidden:[value boolValue]];
    }
    
    [defaults synchronize];
}

- (void)setSelectedFont:(id)value specifier:(PSSpecifier*)specifier {
    [[DevLandSettings shared] setCurrentFont:value];
    [[NSUserDefaults standardUserDefaults] setObject:value forKey:@"selectedFont"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (id)getSelectedFont {
    return [[DevLandSettings shared] currentFont] ?: @"ArialArabic-Bold";
}

// ====== إعداد الواجهة ======
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"إعدادات ديف لاند";
    self.navigationController.navigationBar.tintColor = [UIColor systemBlueColor];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [[DevLandSettings shared] setFakeLocationEnabled:[defaults boolForKey:@"enableLocationSpoof"]];
    [[DevLandSettings shared] setChatsHidden:[defaults boolForKey:@"hideChats"]];
    [[DevLandSettings shared] setCurrentFont:[defaults stringForKey:@"selectedFont"] ?: @"ArialArabic-Bold"];
    
    CLLocationCoordinate2D savedLoc;
    savedLoc.latitude = [defaults doubleForKey:@"fakeLocationLat"] ?: 24.7136;
    savedLoc.longitude = [defaults doubleForKey:@"fakeLocationLng"] ?: 46.6753;
    [[DevLandSettings shared] setCustomLocation:savedLoc];
}

@end
